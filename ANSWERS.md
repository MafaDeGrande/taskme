**Q1:** Your GKE nodes are in a private subnet with no public IP. Walk through exactly how a pod pulls an image from Artifact Registry. Name every GCP component involved in the network path.

A:

---

**Q2:** Workload Identity is enabled. Explain how a pod authenticates to GCP Secret Manager without a service account key file. What is the chain of trust?

A: The application pod does not access Secret Manager directly. The medi Kubernetes ServiceAccount is created from our manifest, and the SecretSync controller authenticates as default/medi through Workload. Identity Federation using a short-lived token issued and signed by Kubernetes.
The SecretProviderClass identifies the GCP secret to read, while the secret-level roles/secretmanager.secretAccessor IAM binding authorizes that identity to access it. SecretSync then creates the namespaced Kubernetes Secret mounted by the pod, so no long-lived Google service-account key is stored or mounted.

---


**Q3:** `terraform plan` shows your Cloud SQL instance will be destroyed and recreated. What do you do before running `terraform apply`? List every step in order.

A:

---


**Q4:** Your deployment has 3 replicas. During a rolling update the new pod immediately starts returning 500s. Walk through exactly what happens given your readiness probe configuration. What is the state of the old pods? Does the HPA react?

A: If the 500 response also causes /readyz to fail, the new surge pod remains Running but NotReady and is not added to the Service endpoints. With maxUnavailable - 0 and maxSurge -1, k8s keeps retrying the readiness probe while all three old replicas remain Ready and continue serving traffic.

After the 600-second progress deadline, the rollout is marked failed, but k8s does not automatically roll it back and the old ReplicaSet remains available. The HPA does not react directly to HTTP errors because it scales only on CPU and memory. It reacts only if those resource targets are exceeded. If application requests return 500 while /readyz still returns 200, Kubernetes considers the new pod Ready, sends traffic to it, and continues replacing the old pods.

---


**Q5:** Your 30-day error budget is 43 minutes (0.1% of 30 days). At 3 AM an alert fires: burn rate is 10x. How many minutes of budget are you consuming per hour? How long until the budget is exhausted? What is your response?

A:

---


**Q6:** A colleague suggests setting CPU limit to 4 cores so the service is never throttled. What is wrong with this in a shared GKE cluster? What would you configure instead and why?

A: A four-core CPU limit is only a maximum usage, not a reservation, so it neither guarantees four cores nor prevents throttling. Kubernetes schedules pods
based on CPU requests rather than limits if requests are too low, several pods with large limits can be placed on the same node and compete for CPU,
reducing workload density and increasing infrastructure cost. I would determine the CPU request from load tests and observed sustained, then set a smaller
limit with reasonable values. The HPA target should be calculated from that request, and the final values should be validated using CPU utilization, throttling, latency etc..

---


**Q7:** Design a canary deployment strategy using your existing Kubernetes and CI/CD setup — no additional tools required. How do you route 5% of traffic to the new version, automatically promote on success, and automatically rollback if error rate exceeds 1%?

A:
