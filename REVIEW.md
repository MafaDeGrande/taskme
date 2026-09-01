## Find All Issues

### Terraform
1.
   ```
   ip_configuration {
     ipv4_enabled = true
   }
   ```
   This configuration gives the Cloud SQL instance a public IPv4 address and
   does not connect it to a private VPC. The database gains an unnecessary
   public attack surface. A mistake in network access controls or compromised
   credentials could expose the database to unauthorized access.

   fix: Disable public IPv4 and connect the instance to a VPC through Private Service
   Access.
   ```
   settings {
     ip_configuration {
       ipv4_enabled    = false
       private_network = google_compute_network.main.id
     }
   }
   ```
2.
   ```
   backup_configuration {
     enabled = false
   }
   ```

   Automated backups are disabled. Data corruption, an accidental update, or an
   instance failure could leave the service without a recent recovery point.
   This increases potential data loss and recovery time.

   fix: Enable automated backups, point-in-time recovery, and an appropriate
   retention period.
   ```
   backup_configuration {
     enabled                        = true
     point_in_time_recovery_enabled = true
     transaction_log_retention_days = 7

     backup_retention_settings {
       retained_backups = 7
       retention_unit   = "COUNT"
     }
   }
   ```

3.
   ```
   deletion_protection = false
   ```

   Terraform deletion protection is disabled. An accidental
   `terraform destroy` or a configuration change that replaces the instance
   could remove the production database and cause data loss and a prolonged
   outage.

   fix: Enable Terraform deletion protection and the Cloud SQL API deletion
   protection setting. They should only be disabled through an explicitly
   approved database removal procedure.
   ```
   resource "google_sql_database_instance" "postgres" {
     deletion_protection = true

     settings {
       deletion_protection_enabled = true
     }
   }
   ```

4.
   ```
   remove_default_node_pool = false
   ```

   The automatically created default node pool remains attached to the cluster
   and there is no separately managed application node pool. System and
   application workloads can compete for the same nodes. Independent sizing,
   autoscaling, and maintenance of application capacity also become harder.

   fix: Remove the initial node pool and create a dedicated autoscaling node pool for
   the application. The final machine type and scaling limits should be
   confirmed through load testing.

5.
   ```
   master_authorized_networks_config {
     cidr_blocks {
       cidr_block = "0.0.0.0/0"
     }
   }
   ```

   The Kubernetes control plane accepts connections from every IPv4 address.
   This exposes the API to internet scanning, credential attacks, and attempts
   to exploit control plane vulnerabilities. A successful compromise could give
   an attacker control over workloads and cluster secrets.

   fix: Use a private cluster endpoint and allow access only from a trusted
   management network such as a VPN, bastion host, or private CI runner. The
   management CIDR must contain the actual trusted network and must not be
   `0.0.0.0/0`.
   ```
   private_cluster_config {
     enable_private_nodes    = true
     enable_private_endpoint = true
     master_ipv4_cidr_block  = "172.16.0.0/28"
   }

   master_authorized_networks_config {
     cidr_blocks {
       cidr_block   = var.management_cidr
       display_name = "private-management-network"
     }
   }
   ```

### k8s

1.
   ```
   env:
     - name: DB_PASSWORD
       value: "supersecret123"
   ```
   The database password is hardcoded in the Deployment and committed to the
   repository. Anyone with access to Git history, repository copies, CI logs,
   or rendered manifests may obtain the credential. Removing it in a later
   commit does not remove it from Git history, so the exposed password must also
   be rotated.

   fix: Store the password in Secret,and reference only the Secret key from the
   Deployment. The secret value must not be committed to repository.
   ```
   spec:
     serviceAccountName: order-service
     containers:
       - name: order-service
         env:
           - name: DB_PASSWORD
             valueFrom:
               secretKeyRef:
                 name: order-service-db
                 key: password
   ```

2.
   ```
   replicas: 1
   ```
   A single replica provides no redundancy. A pod failure, node drain, or
   rolling update can leave the service without an available instance and cause
   downtime.

   fix: Run multiple replicas and configure an HPA with a safe minimum replica count.
   The final value should be confirmed through load testing.
   ```
   spec:
     replicas: 3
   ```
3.
   ```
   image: order-service:latest
   ```
   The mutable `latest` tag does not identify a specific application version.
   The same manifest can start different image versions on different nodes,
   which makes deployments difficult to reproduce and rollbacks unreliable.

   fix: Use an immutable tag derived from the exact commit that produced the image.
   ```
   containers:
     - name: order-service
       image: order-service:8f3c2ab
       imagePullPolicy: IfNotPresent
   ```

4.
   ```
   resources:
     limits:
       cpu: "4"
       memory: "4Gi"
   ```
   Only resource limits are defined. Without requests, the scheduler does not
   have an accurate minimum resource requirement for the pod. Pods may be
   placed on overloaded nodes, and utilization-based HPA calculations cannot
   reliably use CPU or memory percentages without the corresponding requests.

   fix: Define both requests and limits based on measured application usage. These
   values are reasonable starting points that still require validation.
   ```
   resources:
     requests:
       cpu: "1"
       memory: 1Gi
     limits:
       cpu: "2"
       memory: 2Gi
   ```

5.
   ```
   livenessProbe:
     httpGet:
       path: /readyz
       port: 8080
     initialDelaySeconds: 0
     failureThreshold: 1
   ```

   The liveness probe calls the readiness endpoint, starts without a delay, and
   restarts the container after one failure. A temporary database or API outage
   can make a pod unready without meaning that its process is unhealthy.
   Restarting it in that situation can create a restart loop and make the
   original failure worse. Without a separate readiness probe, traffic may also
   reach a pod that is not ready to serve requests.

   fix: Use `/healthz` for liveness, use `/readyz` for readiness, and configure
   thresholds that tolerate short transient failures.

   ```
   readinessProbe:
     httpGet:
       path: /readyz
       port: 8080
     initialDelaySeconds: 5
     periodSeconds: 5
     timeoutSeconds: 2
     failureThreshold: 3

   livenessProbe:
     httpGet:
       path: /healthz
       port: 8080
     initialDelaySeconds: 15
     periodSeconds: 10
     timeoutSeconds: 2
     failureThreshold: 3
   ```

### ci/cd github

1.
   ```
   on:
     push:
       branches: ["*"]
   ```

   The deployment workflow runs after a push to every matching branch. A
   feature branch can therefore start a production deployment. There is also no
   pull request event that can validate changes before they are merged.

   fix: Run validation and planning for pull requests to `main`. Allow
   state-changing deployment jobs only after a push or merge to `main`.

   ```
   on:
     pull_request:
       branches: [main]
     push:
       branches: [main]
   ```

2.
   ```
   docker build -t order-service:latest .
   docker push order-service:latest
   ```

   The mutable `latest` tag does not identify the commit used to build the
   image. A later build can overwrite the tag, which makes it impossible to
   determine reliably which code is deployed and makes rollback unpredictable.

   Tag the image with `github.sha` so every workflow run produces a unique and
   traceable image reference.

   ```
   env:
     IMAGE_TAG: ${{ github.sha }}

   steps:
     - name: Build and push immutable image
       run: |
         docker build -t "order-service:${IMAGE_TAG}" .
         docker push "order-service:${IMAGE_TAG}"
   ```

3.
   ```
   - name: Deploy to production
     run: kubectl set image deployment/order-service order-service=order-service:latest
   ```

   The pipeline deploys directly to production and skips infrastructure
   planning, an approved infrastructure apply, staging deployment, rollout
   verification, smoke tests, production approval, and automatic rollback. An
   unverified application or incompatible infrastructure change can immediately
   affect users. A failed rollout can remain active without an automatic return
   to the last working version.

   fix: Split the pipeline into dependent stages for validation, image build,
   infrastructure plan and apply, staging deployment, smoke testing, and
   production deployment. Restrict state changes to the main branch, protect
   apply and production with approval environments, and trigger a rollback when
   the production rollout fails.

4.
   ```
   - name: Deploy to production
     run: kubectl set image deployment/order-service order-service=order-service:latest

   - name: Run tests
     run: go test ./...
   ```

   Tests run only after the production deployment. A failing test therefore
   reports a defect after users may already be running the defective version.
   The test result cannot prevent the deployment that has already completed.

   fix: Run tests before build and deployment, and make every later job depend on a
   successful test job.
   ```
   jobs:
     test:
       runs-on: ubuntu-latest
       steps:
         - uses: actions/checkout@v4
         - uses: actions/setup-go@v5
           with:
             go-version-file: go.mod
         - name: Run tests
           run: go test ./...

     build:
       needs: test

     deploy-staging:
       needs: build
   ```
