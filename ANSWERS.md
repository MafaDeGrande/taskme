**Q1:** Your GKE nodes are in a private subnet with no public IP. Walk through exactly how a pod pulls an image from Artifact Registry. Name every GCP component involved in the network path.

A:

---

**Q2:** Workload Identity is enabled. Explain how a pod authenticates to GCP Secret Manager without a service account key file. What is the chain of trust?

A:

---


**Q3:** `terraform plan` shows your Cloud SQL instance will be destroyed and recreated. What do you do before running `terraform apply`? List every step in order.

A:

---


**Q4:** Your deployment has 3 replicas. During a rolling update the new pod immediately starts returning 500s. Walk through exactly what happens given your readiness probe configuration. What is the state of the old pods? Does the HPA react?

A:

---


**Q5:** Your 30-day error budget is 43 minutes (0.1% of 30 days). At 3 AM an alert fires: burn rate is 10x. How many minutes of budget are you consuming per hour? How long until the budget is exhausted? What is your response?

A:

---


**Q6:** A colleague suggests setting CPU limit to 4 cores so the service is never throttled. What is wrong with this in a shared GKE cluster? What would you configure instead and why?

A:

---


**Q7:** Design a canary deployment strategy using your existing Kubernetes and CI/CD setup — no additional tools required. How do you route 5% of traffic to the new version, automatically promote on success, and automatically rollback if error rate exceeds 1%?

A:
