# HighErrorRate runbook

## Alert context

`HighErrorRate` is critical when more than 1% of Medi requests return 5xx for
five minutes. Users can receive failed or delayed order operations.

- Workload: `deployment/medi`
- Service and HPA: `service/medi`, `hpa/medi`
- Namespace: `default`
- Dependencies: PostgreSQL and an external billing API

## Initial triage

1. Confirm the target cluster and current error rate:

   ```bash
   kubectl config current-context
   kubectl config view --minify
   ```
   ```
   sum(rate(http_requests_total{job="medi",status=~"5.."}[5m]))
   /
   clamp_min(sum(rate(http_requests_total{job="medi"}[5m])), 1e-9)
   ```

2. Check the workload and recent rollout:
   ```bash
   kubectl -n default get deployment,pods,service,endpoints,hpa
   kubectl -n default rollout status deployment/medi --timeout=30s
   kubectl -n default rollout history deployment/medi
   ```

## Diagnosis

Identify the failing HTTP status and whether errors are isolated to a pod:

```
sum by (status) (rate(http_requests_total{job="medi"}[5m]))
```

```
sum by (pod) (rate(http_requests_total{job="medi",status=~"5.."}[5m]))
/
clamp_min(sum by (pod) (rate(http_requests_total{job="medi"}[5m])), 1e-9)
```

Inspect logs, pod conditions, resource usage, and recent events:

```bash
kubectl -n default logs -l app.kubernetes.io/name=medi --all-containers=true --prefix --since=15m --tail=200
kubectl -n default describe deployment medi
kubectl -n default top pods -l app.kubernetes.io/name=medi
kubectl -n default get events --sort-by=.lastTimestamp
```

If a container restarted, inspect its previous logs:

```bash
kubectl -n default logs <POD> --previous --all-containers=true --tail=200
```

Check database-pool capacity:

```
(
  db_connection_pool_max_connections{job="medi"}
  - db_connection_pool_in_use_connections{job="medi"}
)
/
clamp_min(db_connection_pool_max_connections{job="medi"}, 1)
```

Correlate the first errors with the latest deployment. Check application logs
for PostgreSQL failures and billing API timeouts or 5xx responses.

## Resolution, least to most disruptive

1. **Pause an active rollout** if errors started with the new revision:

   ```bash
   kubectl -n default rollout pause deployment/medi
   ```

2. **Roll back that revision** when the correlation is confirmed:

   ```bash
   kubectl -n default rollout resume deployment/medi
   kubectl -n default rollout undo deployment/medi
   kubectl -n default rollout status deployment/medi --timeout=10m
   ```

3. **Replace one unhealthy pod** only when the other replicas remain Ready:

   ```bash
   kubectl -n default delete pod <POD>
   ```

4. **Increase capacity temporarily** only when CPU or memory saturation is the
   confirmed cause and the dependencies are healthy. Keep the HPA minimum within
   its configured maximum and record the change for reversal.

5. **Escalate dependency changes** to the database or billing owner. Do not
   change Cloud SQL or retry billing operations without their confirmation.

## Verify recovery

- Desired replicas are Ready and Service endpoints are populated.
- The five-minute 5xx ratio remains below 1% for at least ten minutes.
- `medi:slo_availability:burn_rate_1h` is decreasing.
- Any temporary rollout or scaling change is reverted or recorded.

## Escalation

- Declare a major incident if errors exceed 5%, all replicas are unavailable,
  or data integrity may be affected.
- Engage the application owner if the cause is unknown after ten minutes or
  rollback does not recover the service.
- Engage the database or billing owner when the corresponding dependency fails.
- Engage the platform/SRE owner for GKE, network, DNS, or Secret Sync failures.
- Assign an incident commander when impact lasts 15 minutes or burn rate exceeds
  5x, and provide regular stakeholder updates.
