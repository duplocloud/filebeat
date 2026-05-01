# Fluent Bit DaemonSet Deployment

Log collector that runs alongside (or replaces) the platform-managed Filebeat DaemonSet.
Output structure matches Filebeat for index/query compatibility.

## Prerequisites

- Kubectl access to the target cluster
- OpenSearch endpoint (no credentials needed — uses IAM)
- Docker image tag from [duplocloud/fluentbit on Docker Hub](https://hub.docker.com/r/duplocloud/fluentbit/tags)

## Generate and deploy

Two modes: **tenant-scoped** (one namespace's nodes) and **cluster-wide** (all nodes).

### Tenant-scoped (default)

```bash
./generate.sh <namespace> <docker-image> <es-host>
kubectl apply -f rbac/rbac-<namespace>.yaml
kubectl apply -f ds/fluentbit-k8s-<namespace>.yaml
```

The namespace is the full Kubernetes namespace (e.g. `duploservices-dev-usw2`).
The DaemonSet uses `nodeSelector.tenantname` to schedule only on that tenant's nodes.
Deploy into the tenant that **owns the nodes**, not a workload-only namespace — a single
DaemonSet collects logs from all containers on a node regardless of pod namespace.

### Cluster-wide

```bash
./generate.sh --cluster-wide <namespace> <docker-image> <es-host>
kubectl apply -f rbac/rbac-cluster.yaml
kubectl apply -f ds/fluentbit-k8s-cluster.yaml
```

Schedules on **every node** regardless of tenant. The `<namespace>` argument determines
where the resources are created (e.g. `duploservices-default`). Differences from
tenant-scoped:

- No `tenantname` nodeSelector — pods schedule on all Linux nodes
- Catch-all toleration (`operator: Exists`) — tolerates all taints
- `duplocloud.net/daemnonset-tenant-local: "False"`
- Resource names use `fluentbit-cluster-*`

Or run `./generate.sh` without arguments (either mode) to be prompted interactively.

**DuploCloud Portal alternative:** Navigate to **Kubernetes → DaemonSet** and paste the
generated YAML instead of using `kubectl apply`.

## Verify

```bash
# Check pods are running
kubectl -n <namespace> get pods -l app=fluentbit-<name>-ds

# Health endpoint
kubectl -n <namespace> exec <pod> -- curl -s http://localhost:2020/api/v1/health

# Prometheus metrics
curl http://localhost:2020/api/v1/metrics/prometheus

# Confirm indices in OpenSearch
# e.g. "filebeat-fluentbit-YYYY.MM.DD"
```

Where `<name>` is the namespace (tenant mode) or `cluster` (cluster-wide mode).

## Migrating from tenant-scoped to cluster-wide

Deploy new **before** deleting old to avoid any log loss. Both DaemonSets share the
host-level offset database (`flb_kube.db`) with `DB.locking: true` — on nodes where
both land, the cluster-wide pod fails to initialize (`database is locked`) and enters
CrashLoopBackOff until the tenant-scoped pod is removed. Once the lock is released,
the cluster-wide pod restarts, acquires the DB, and resumes from the last recorded
offset. No logs are lost, but expect CrashLoopBackOff on shared nodes between steps 2
and 4.

```bash
# 1. Generate cluster-wide manifests
./generate.sh --cluster-wide <namespace> <docker-image> <es-host>

# 2. Deploy cluster-wide — on nodes with existing tenant-scoped pods, new pods will be
#    in CrashLoopBackOff (database is locked) until step 4. That is expected.
kubectl apply -f rbac/rbac-cluster.yaml
kubectl apply -f ds/fluentbit-k8s-cluster.yaml

# 3. Verify cluster-wide pods are healthy on nodes without existing tenant-scoped pods
kubectl -n <namespace> get pods -l app=fluentbit-cluster-ds

# 4. Delete tenant-scoped DaemonSets — releases DB lock, CrashLoopBackOff pods
#    restart, acquire the DB, and resume from the last recorded offset
kubectl delete -f ds/fluentbit-k8s-<namespace>.yaml   # repeat per tenant

# 5. Clean up old RBAC
kubectl delete -f rbac/rbac-<namespace>.yaml           # repeat per tenant
```

Nodes that never had tenant-scoped Fluent Bit get coverage immediately at step 2.
Nodes that did get a seamless handoff at step 4.

### Replacing Filebeat

Same order — deploy Fluent Bit first, verify, then remove Filebeat. There is no state
conflict because Fluent Bit and Filebeat use separate offset-tracking databases.

## Rollback

```bash
kubectl delete -f ds/fluentbit-k8s-<name>.yaml
kubectl delete -f rbac/rbac-<name>.yaml
```

## Index prefix

Indices are named `filebeat-fluentbit-YYYY.MM.DD` by default — all tenants share one
daily index. The `filebeat-` prefix ensures logs match the pre-existing `filebeat-*`
index pattern in OpenSearch Dashboards — backwards compatible with existing dashboards
and saved searches. Configurable via the `INDEX_PREFIX` environment variable
(default: `filebeat-fluentbit-`).

## File overview

```text
diagnostics/opensearch/fluentbit/
  ARCHITECTURE.md                # Design decisions, pipeline details, OpenSearch gotchas
  generate.sh                    # Generates RBAC + DaemonSet config from templates
  Dockerfile                     # Image build (base: fluent-bit 4.2.4)
  conf/fluent-bit.conf           # Pipeline config (input, filters, output)
  conf/parsers.conf              # CRI and JSON log parsers
  scripts/tenant_extract.lua     # Tenant extraction, log restructuring, index routing
  ds/fluentbit-k8s.yaml.tpl      # DaemonSet YAML template
  rbac/rbac.yaml.tpl             # RBAC template (ServiceAccount, ClusterRole, ClusterRoleBinding)
```
