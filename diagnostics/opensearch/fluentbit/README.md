# Fluent Bit DaemonSet Deployment

Parallel Fluent Bit log collector that runs alongside the platform-managed Filebeat DaemonSet.
Log output structure matches Filebeat for index/query compatibility.

## Prerequisites

- Kubectl access to the target cluster
- OpenSearch endpoint (no credentials needed — uses IAM)
- Docker image tag from [duplocloud/fluentbit on Docker Hub](https://hub.docker.com/r/duplocloud/fluentbit/tags)

## 1. Generate config

```bash
./generate.sh <namespace> <docker-image> <es-host>
```

Or run without arguments to be prompted interactively. The namespace is the full
Kubernetes namespace (e.g. `duploservices-dev-usw2`).

**Node scheduling:** The DaemonSet uses `nodeSelector.tenantname` set to the namespace.
Deploy into the tenant that **owns the nodes**, not a workload-only namespace. A single
DaemonSet collects logs from all containers on a node regardless of pod namespace, so
namespaces that share nodes should be covered by one DaemonSet in the node-owning tenant.

This generates:

- `rbac/rbac-<namespace>.yaml` — ServiceAccount, ClusterRole, ClusterRoleBinding
- `ds/fluentbit-k8s-<namespace>.yaml` — DaemonSet manifest

## 2. Apply RBAC

```bash
kubectl apply -f rbac/rbac-<namespace>.yaml
```

## 3. Deploy

**Option A — DuploCloud Portal** (recommended):

1. Navigate to **Kubernetes → DaemonSet**
2. Use the generated `ds/fluentbit-k8s-<namespace>.yaml` as the DaemonSet config
3. The portal adds standard DuploCloud labels and annotations automatically

**Option B — Direct kubectl**:

```bash
kubectl apply -f ds/fluentbit-k8s-<namespace>.yaml
```

The generated template includes all fields needed for direct apply (nodeSelector,
serviceAccount, tolerations, priorityClassName, etc.).

## 4. Verify

```bash
# Check pods are running
kubectl -n <namespace> get pods -l app=fluentbit-<namespace>-ds

# Check fluent-bit health endpoint
kubectl -n <namespace> exec <pod> -- curl -s http://localhost:2020/api/v1/health

# Confirm indices in OpenSearch (index name uses short tenant name from k8s labels)
# e.g. "filebeat-fluentbit-dev-usw2-YYYY.MM.DD"
```

## Metrics

Each pod exposes Prometheus-compatible metrics on port `2020`:

```bash
# Health check
curl http://localhost:2020/api/v1/health

# Prometheus metrics
curl http://localhost:2020/api/v1/metrics/prometheus
```

The container port is named `metrics` in the DaemonSet spec for service discovery.

## Index prefix

Indices are named `filebeat-fluentbit-{tenant}-YYYY.MM.DD` by default. The
`filebeat-` prefix ensures logs are automatically included in the pre-existing
`filebeat-*` index pattern that OpenSearch Dashboards uses by default, making this
backwards compatible with existing dashboards, saved searches, and queries without
requiring a new index pattern.

The prefix is configurable via the `INDEX_PREFIX` environment variable in the DaemonSet
(default: `filebeat-fluentbit-`).

## File overview

```text
diagnostics/opensearch/fluentbit/
  ARCHITECTURE.md                # Design decisions, pipeline details, OpenSearch gotchas
  generate.sh                    # Generates RBAC + DaemonSet config from templates
  Dockerfile                     # Image build (base: fluent-bit 4.2.3)
  conf/fluent-bit.conf           # Pipeline config (input, filters, output)
  conf/parsers.conf              # CRI and JSON log parsers
  scripts/tenant_extract.lua     # Tenant extraction, log restructuring, index routing
  ds/fluentbit-k8s.yaml.tpl      # DaemonSet YAML template
  ds/.gitignore                  # Ignores generated YAML files
  rbac/rbac.yaml.tpl             # RBAC template (ServiceAccount, ClusterRole, ClusterRoleBinding)
  rbac/.gitignore                # Ignores generated YAML files
```

## Rollback

```bash
kubectl delete -f ds/fluentbit-k8s-<namespace>.yaml
kubectl delete -f rbac/rbac-<namespace>.yaml
```
