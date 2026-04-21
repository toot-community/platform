# 2026-04-21 — `tc-prod-wk-lyuba` global OOM

## Summary

A chart label migration on the `victoria-logs-single` chart broke the
VictoriaLogs Service endpoint list. Vector (the log collector DaemonSet) kept
retrying against an unresolvable DNS name and buffered all in-flight log
events in memory. With no VPA `maxAllowed`, VPA's `InPlaceOrRecreate` grew
the pod's memory limit to ~297 GB, following the runaway usage. On `lyuba`,
vector's RSS reached ~116 GB and triggered a kernel `global_oom`. That took
down or restarted most pods on the node, including the `toot-community`
postgres replica (`database-1`), `vmalertmanager-vm-0`, and several
StatefulSet members.

A separate, pre-existing condition contributed: the `toot-community` postgres
replica had been hitting its 32 GiB cgroup limit five times during the
afternoon before the vector blow-up, generating the log burst that vector
couldn't ship.

## Timeline (CEST / UTC)

All times from Talos `dmesg` on `tc-prod-wk-lyuba` (148.251.81.14).

| CEST   | UTC    | Event                                                                                   |
|--------|--------|------------------------------------------------------------------------------------------|
| 13:04  | 11:04  | Talos OOM controller kills cgroup `pod8f59751f` (`toot-community/database-1`)            |
| 14:27  | 12:27  | OOM controller kills `database-1` again + another pod                                    |
| 14:55  | 12:55  | OOM controller kills `database-1` third time. Node Ready condition transitions.          |
| 14:55  | 12:55  | First Robusta alerts: crashing `database-1` pods in `n8n` and `toot-community`           |
| 15:54  | 13:54  | `vmalertmanager-vm-0` crashing alert                                                     |
| 15:56  | 13:56  | OOM #4 on `database-1`                                                                   |
| 16:21-16:56 | 14:21-14:56 | Cascading alertmanager alerts (half-down, failed notifications, service down) |
| 16:26  | 14:26  | OOM #5 on `database-1`                                                                   |
| 16:59  | 14:59  | **Kernel `global_oom`** — vector killed with `anon-rss: 116 GB`                          |
| 16:59  | 14:59  | Talos OOM controller kills further cgroups. Cilium/containerd health checks flap.        |
| 17:00  | 15:00  | `vl-vector-trsq4` OOMKilled alert (Gmail)                                                |

Current time of response writing: 2026-04-21 ~20:30 CEST.

## Root cause

Two independent issues that compounded.

### 1. Broken log-shipper sink (the one that actually blew up the node)

PR #798 (`ecbc769`) bumped `victoria-logs-single` to `v0.11.32`. The chart
migrated its label scheme from `app: server` to
`app.kubernetes.io/component: server`.

- The rendered **Service** got the new selector and ArgoCD synced it.
- The rendered **StatefulSet** had the new selector, but
  `spec.selector` on StatefulSets is immutable. ArgoCD could not apply
  the change. The live STS kept `app: server` and its pods kept the old
  labels.
- Result: `vl-victoria-logs-single-server` Service had **zero endpoints**
  and its per-pod DNS name (`vl-victoria-logs-single-server-0.vl-victoria-logs-single-server.victorialogs.svc.cluster.local`) returned `NXDOMAIN`.
- Vector retried against the unresolvable sink, buffering indefinitely.

Vector in this chart has no sink `buffer` block, so it defaults to an
in-memory buffer with unbounded backpressure resolution (retry until success).

ArgoCD had been flagging the STS as `OutOfSync` since the chart bump, but
nothing surfaced it as a critical alert.

### 2. Postgres replica OOM-looping throughout the afternoon

`toot-community` postgres is configured with 32 GiB cgroup and the following
memory-relevant parameters:

| Parameter | Value |
|---|---|
| `max_connections` | 200 |
| `shared_buffers` | 8 GB |
| `work_mem` | 41 MB |
| `hash_mem_multiplier` | 2 |
| `maintenance_work_mem` | 2 GB |

Mastodon uses Makara read-replica routing (`DB_HOST=database-pooler-rw`,
`REPLICA_DB_HOST=database-pooler-ro`). All SELECTs hit the replica.

The RO pooler (`database-pooler-ro`) is configured with
`default_pool_size: 125` × 2 pgbouncer instances = 250 target server
connections — well above the replica's `max_connections: 200`.

Worst-case working-set math: 200 conns × 2 hash ops × 82 MB (work_mem × hash_mem_multiplier) = **~33 GiB in hash tables alone**, plus 8 GB
shared_buffers. Under concurrent read load the replica exceeds 32 GiB and
the Talos OOM controller kills it.

Top RO-pressure queries (from `pg_stat_statements` on primary):
- `statuses × statuses_tags × accounts` hashtag-timeline joins (~22 TB total buffer reads)
- `preview_cards × preview_card_trends` (~10 TB)

### 3. Missing VPA safety rail (what turned the above into a cluster incident)

`vl-vector-vpa` had no `maxAllowed`. With `updateMode:
InPlaceOrRecreate` and `controlledValues: RequestsAndLimits`, VPA saw the
growing usage and kept raising the pod's memory request/limit in-place.

The poisoned recommender histogram (seen post-incident):
```
target.memory:     166,603,480,601  (~155 GB)
uncappedTarget:    166,603,480,601  (~155 GB)
```

The live pod limit was ~297 GB when vector finally crossed the line and
triggered the kernel OOM killer against the whole node (not just the
cgroup).

## Fixes applied

### Today (hotfix)

| Area | Change | Commit |
|------|--------|--------|
| VPA | Add `maxAllowed: {cpu: 1, memory: 2Gi}` to `vl-vector-vpa` in `manifests/applications/vpa-resources/helm-values.yaml` | `c900a2b` |
| VPA state | `kubectl delete verticalpodautoscalercheckpoint vl-vector-vpa-vector goldilocks-vl-vector-vector goldilocks-vl-victoria-logs-single-server-vlogs -n victorialogs` — purge poisoned histograms | — |
| Vector | `kubectl rollout restart ds vl-vector -n victorialogs` — re-apply limits from DS template instead of in-place-resized values | — |
| VictoriaLogs | `kubectl delete sts vl-victoria-logs-single-server --cascade=orphan`, then `kubectl delete pod vl-victoria-logs-single-server-0` — force StatefulSet recreation with the new selector. PVC `server-volume-vl-victoria-logs-single-server-0` was preserved; no data loss. | — |
| Postgres | Bump `resources.memory` to 40 GiB and add `statement_timeout: 120s` / `idle_in_transaction_session_timeout: 60s` / `log_min_duration_statement: 2000` in `manifests/applications/mastodon/overlays/toot.community/database-cluster.yaml` | follow-up commit |

### Caveat

With `controlledValues: RequestsAndLimits` preserved from the chart default,
the 2 GiB `maxAllowed` translates to ~9 GiB effective pod limit (because
the chart's Helm values have a 4.4× request:limit ratio: 233 Mi → 1 Gi).
A follow-up could add `controlledValues: RequestsOnly` to the `vl-vector`
VPA so the Helm values' `limits.memory: 1Gi` stays authoritative. Not
urgent — 9 GiB × 3 pods = 28 GiB is safely bounded on 128 GiB nodes.

## Action items / follow-ups

- [ ] Audit every VPA with `containerName: "*"` and no `maxAllowed` — same
      structural risk exists for node-exporter, cilium, cilium-envoy, and
      others. Add per-workload caps.
- [ ] Consider lowering `database-pooler-ro` `default_pool_size` from 125
      to ~75 if the replica still pressures after the 40 GiB bump.
      Skipped today because it changes client-facing queuing behavior.
- [ ] Add an alert for ArgoCD `OutOfSync` apps so chart migrations that
      can't apply (immutable fields, selector conflicts) surface quickly.
      The VL StatefulSet was stuck OutOfSync between the chart bump and
      today — we only discovered it during the incident.
- [ ] Add a vector sink `buffer` block (`type: disk`, bounded size, and
      `when_full: drop_newest`) so a broken sink drops logs instead of
      consuming memory. This would have made the node-OOM impossible even
      without the VPA cap.
- [ ] Review `toot-community` top-N queries from `pg_stat_statements`;
      the hashtag-timeline joins are worth an index-usage review.

## Signals / detection

What would have caught this earlier, ranked by cheapness:

1. **`kube_endpoint_address_not_ready` or `absent_over_time(kube_endpoints{...}==0)`** on `vl-victoria-logs-single-server`. Would have fired the moment the chart bump landed. **Highest value.**
2. **Vector internal metric `vector_component_errors_total{component_id="vlogs-0"}`** spiking (sink failures). Already scraped via `vector-podscrape.yaml`, but no alert.
3. **ArgoCD application health != Healthy** for > 15 minutes.
4. **Node `MemoryPressure`** on any worker. Node heartbeat didn't flip today because the kernel OOM killer resolved the pressure faster than the kubelet reconciliation window.

## Commands used during investigation

```sh
# Talos dmesg (requires ~/.talos/keys/default-support@toot.community.pgp)
direnv exec /Users/jorijn/Development/tc talosctl -n 148.251.81.14 dmesg | grep -iE 'oom|panic'

# Find which pod a cgroup UID belongs to
kubectl get pods -A -o json | jq -r '.items[] | select(.metadata.uid=="<uid>") | "\(.metadata.namespace)/\(.metadata.name)"'

# Check for the DNS/endpoint mismatch
kubectl -n victorialogs get svc vl-victoria-logs-single-server -o json | jq '.spec.selector'
kubectl -n victorialogs get pod vl-victoria-logs-single-server-0 -o json | jq '.metadata.labels'
kubectl -n victorialogs get endpoints vl-victoria-logs-single-server

# Check VPA recommendation (look at uncappedTarget to see the raw histogram)
kubectl -n victorialogs get vpa vl-vector-vpa -o json | jq '.status.recommendation'

# Top queries on primary
kubectl -n toot-community exec database-2 -c postgres -- psql -U postgres -d app \
  -c "SELECT substring(query,1,120), calls, total_exec_time::bigint, mean_exec_time::bigint \
      FROM pg_stat_statements ORDER BY total_exec_time DESC LIMIT 10;"
```
