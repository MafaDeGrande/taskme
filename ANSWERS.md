**Q1:** Your GKE nodes are in a private subnet with no public IP. Walk through exactly how a pod pulls an image from Artifact Registry. Name every GCP component involved in the network path.

A: The pod does not pull the image itself. After the scheduler assigns the pod, the node's kubelet asks containerd to pull the image. The GKE node authenticates
through the GKE metadata server as the node-pool Google service account. No pod Workload Identity token is involved in an image pull. That service account has
`roles/artifactregistry.reader` on the `medi` repository.

The network path is: the node's private primary IP and NIC -> the custom VPC route and DNS resolution for `us-central1-docker.pkg.dev` -> Private Google
Access enabled on the GKE subnet -> Google's API frontend -> Artifact Registry and its Google-managed backing storage. Return traffic follows the same private
Google network path. Cloud NAT is available for general external egress, but it is not the normal Artifact Registry path because Private Google Access handles
Google APIs and services. Binary Authorization verifies the deploy policy before the pod is admitted, it does not transport image layers.

---

**Q2:** Workload Identity is enabled. Explain how a pod authenticates to GCP Secret Manager without a service account key file. What is the chain of trust?

A: The application pod does not access Secret Manager directly. The medi Kubernetes ServiceAccount is created from our manifest, and the SecretSync controller authenticates as default/medi through Workload. Identity Federation using a short-lived token issued and signed by Kubernetes.
The SecretProviderClass identifies the GCP secret to read, while the secret-level roles/secretmanager.secretAccessor IAM binding authorizes that identity to access it. SecretSync then creates the namespaced Kubernetes Secret mounted by the pod, so no long-lived Google service-account key is stored or mounted.

---


**Q3:** `terraform plan` shows your Cloud SQL instance will be destroyed and recreated. What do you do before running `terraform apply`? List every step in order.

A:

1. First, confirm that the plan was created for the correct GCP project, backend,
   Terraform workspace, branch, and variable files.
2. Inspect the replacement diff and identify the exact Cloud SQL attribute
   marked as forcing replacement. Compare it with my local changes, recent
   commits, the current Terraform state, and the real Cloud SQL configuration.
3. Check with the team whether someone has uncommitted or unpushed Terraform changes, another
   active plan or apply, or recent manual changes in GCP that could explain the difference.
4. Review provider versions, and any recent module or provider upgrades. Check their release notes for renamed,
   removed, or newly replacement-triggering fields. If necessary, reproduce the plan with the previously pinned
   versions to determine whether an upgrade caused it.
5. If replacement is genuinely required, assess the expected downtime, data loss risk, dependent
   applications, connection changes, and the effect of deletion protection. Prefer creating and validating
   a new instance before removing the old one instead of accepting an immediate destroy-and-create.
6. Verify that automated backups and point-in-time recovery are enabled, create an on-demand backup, wait for 
   it to complete, and prove that it can be restored to a separate instance before approving the replacement.

---


**Q4:** Your deployment has 3 replicas. During a rolling update the new pod immediately starts returning 500s. Walk through exactly what happens given your readiness probe configuration. What is the state of the old pods? Does the HPA react?

A: If the 500 response also causes /readyz to fail, the new surge pod remains Running but NotReady and is not added to the Service endpoints. With maxUnavailable - 0 and maxSurge -1, k8s keeps retrying the readiness probe while all three old replicas remain Ready and continue serving traffic.

After the 600-second progress deadline, the rollout is marked failed, but k8s does not automatically roll it back and the old ReplicaSet remains available. The HPA does not react directly to HTTP errors because it scales only on CPU and memory. It reacts only if those resource targets are exceeded. If application requests return 500 while /readyz still returns 200, Kubernetes considers the new pod Ready, sends traffic to it, and continues replacing the old pods.

---


**Q5:** Your 30-day error budget is 43 minutes (0.1% of 30 days). At 3 AM an alert fires: burn rate is 10x. How many minutes of budget are you consuming per hour? How long until the budget is exhausted? What is your response?

A: At a 10× burn rate, we consume about 0.6 minutes (36 seconds) of the error budget per hour. If the full budget remains, it will be exhausted in 72 hours.
I’d acknowledge the alert, verify sustained user impact, mitigate first, rolling back a faulty release or failing over and confirm that the burn rate returns below 1x.
Root-cause analysis and a postmortem should follow after the service is stable

---


**Q6:** A colleague suggests setting CPU limit to 4 cores so the service is never throttled. What is wrong with this in a shared GKE cluster? What would you configure instead and why?

A: A four-core CPU limit is only a maximum usage, not a reservation, so it neither guarantees four cores nor prevents throttling. Kubernetes schedules pods
based on CPU requests rather than limits if requests are too low, several pods with large limits can be placed on the same node and compete for CPU,
reducing workload density and increasing infrastructure cost. I would determine the CPU request from load tests and observed sustained, then set a smaller
limit with reasonable values. The HPA target should be calculated from that request, and the final values should be validated using CPU utilization, throttling, latency etc..

---


**Q7:** Design a canary deployment strategy using your existing Kubernetes and CI/CD setup — no additional tools required. How do you route 5% of traffic to the new version, automatically promote on success, and automatically rollback if error rate exceeds 1%?

A: The only option I see with the existing setup is for the pipeline to temporarily run nineteen old-version pods in the stable Deployment and one
new-version pod in a separate `medi-canary` Deployment. The Service selects all twenty endpoints, so the canary receives approximately `1 / (19 + 1) = 5%` of
connections. With the normal three stable pods, adding one canary would produce approximately `1 / (3 + 1) = 25%`, which is too high. The stable HPA must be
paused or temporarily changed so that it does not alter the 19:1 ratio.

After the canary becomes Ready, CI queries its version-labelled 5xx rate in Prometheus for a fixed observation period. If the rate stays at or below 1%, CI
updates the stable Deployment to the candidate SHA, waits for the rollout, deletes `medi-canary`, and restores the normal replica count and HPA settings.
If the rate exceeds 1%, CI deletes only the canary and restores the original stable scaling. The old application version has remained available throughout.

This is only an approximation because Kubernetes balances endpoints and persistent connections, not an exact percentage of individual HTTP requests.
Guaranteed 5% weighted routing requires an ingress controller or service mesh, which the question excludes.
