# Fluent Bit Architecture & Design Decisions

## Purpose

This Fluent Bit DaemonSet runs in parallel with the platform-managed Filebeat DaemonSet.
Its log output structure matches Filebeat so both can write to the same OpenSearch indices
(or separate ones) with compatible field mappings and query patterns.

## Pipeline overview

```txt
tail input → CRI parser → kubernetes filter → Lua filter → OpenSearch output
```

1. **tail input** — reads `/var/log/containers/*.log` (all containers on the node)
2. **CRI parser** — extracts `log`, `stream`, and timestamp from the CRI log format
3. **kubernetes filter** — enriches with pod/namespace/label metadata via the K8s API.
   `Merge_Log On` parses JSON log lines; `Merge_Log_Key log_processed` stores parsed
   fields under `log_processed` (which the Lua filter then discards — see below)
4. **Lua filter** (`tenant_extract.lua`) — restructures the record for Filebeat parity
5. **OpenSearch output** — writes to date-based indices using a per-record prefix

## Lua filter: what it does and why

The Lua filter (`scripts/tenant_extract.lua`) runs after the kubernetes filter and
performs all log restructuring in a single pass:

- **Tenant extraction** — reads `tenantname` from k8s labels, strips `duploservices-`
  prefix to get the short tenant name. Falls back to namespace if label is missing.
- **Kubernetes metadata restructuring** — Fluent Bit's kubernetes filter produces flat
  fields (`pod_name`, `container_name`, `host`, etc.). The Lua script nests them into
  `kubernetes.pod`, `kubernetes.container`, `kubernetes.node`, `kubernetes.namespace`
  to match Filebeat's structure.
- **Field renaming** — `log` → `message` (the raw log line). The `log` field is then
  repurposed as `log.file.path` (reconstructed from the tag).
- **`log_processed` removal** — `Merge_Log_Key log_processed` captures parsed JSON from
  the log line, but this duplicates `message`. Worse, different apps emit fields like
  `timestamp` in different formats, causing **OpenSearch field type conflicts** across
  indices (e.g. `date` in one index, `text` in another). We nil it out to avoid this.
- **Index prefix** — builds `index_prefix` for per-tenant index routing. The output
  plugin uses `Logstash_Prefix_Key index_prefix` to route each record to the
  correct index (e.g. `filebeat-fluentbit-dev-usw2-2026.03.13`).
- **Static nested objects** — adds `agent`, `host`, `input`, `tenant`, `container`
  objects to match Filebeat's document structure.

### Environment variables used by the Lua script

| Variable              | Purpose                                   | Default               |
| --------------------- | ----------------------------------------- | --------------------- |
| `ALIAS`               | Override index prefix (e.g. `myalias-fb`) | `unknown`             |
| `SERVICE_LEVEL_INDEX` | If `yes`, include container name in index | `no`                  |
| `HOSTNAME`            | Pod hostname, used in `agent` and `host`  | `unknown`             |
| `INDEX_PREFIX`        | Index name prefix before tenant name      | `filebeat-fluentbit-` |

Environment variables and static tables are cached at module load, not per-record.
Fluent Bit processes records sequentially per worker — no concurrent Lua calls.

## Index naming

| Condition                 | Index pattern                                   |
| ------------------------- | ----------------------------------------------- |
| `ALIAS` is set            | `{ALIAS}-fb-YYYY.MM.DD`                         |
| `SERVICE_LEVEL_INDEX=yes` | `{INDEX_PREFIX}{tenant}-{container}-YYYY.MM.DD` |
| Default                   | `{INDEX_PREFIX}{tenant}-YYYY.MM.DD`             |

The `INDEX_PREFIX` env var defaults to `filebeat-fluentbit-`, producing indices like
`filebeat-fluentbit-dev-usw2-2026.03.13`. The `filebeat-` prefix is intentional — it
ensures indices are matched by the pre-existing `filebeat-*` index pattern in OpenSearch
Dashboards, providing backwards compatibility with existing dashboards, saved searches,
and queries without requiring a new index pattern.

The tenant name in the index is the **short name** extracted from k8s labels
(e.g. `dev-usw2`), not the full namespace (`duploservices-dev-usw2`).

## Sample output document

```json
{
  "@timestamp": "2026-03-13T15:28:52.265Z",
  "message": "{\"log_level\": \"INFO\", \"log_message\": \"200 GET /ready\", ...}",
  "stream": "stdout",
  "log": { "file": { "path": "/var/log/containers/myapp-abc123_duploservices-dev_myapp-5a684a...log" } },
  "kubernetes": {
    "labels": { "app": "myapp-dev", "tenantname": "duploservices-dev", ... },
    "container": { "name": "myapp", "image": "registry/myapp:v1.0" },
    "node": { "hostname": "ip-10-0-1-50.ec2.internal", "name": "ip-10-0-1-50.ec2.internal" },
    "pod": { "uid": "da7d7cb9-...", "name": "myapp-abc123" },
    "namespace": "duploservices-dev"
  },
  "container": { "id": "5a684a...", "image": { "name": "registry/myapp:v1.0" }, "runtime": "containerd" },
  "tenant": { "name": "dev", "id": "" },
  "agent": { "name": "fluentbit-dev-ds-x222z", "type": "fluent-bit", "version": "4.2.3", "hostname": "fluentbit-dev-ds-x222z" },
  "host": { "name": "fluentbit-dev-ds-x222z" },
  "input": { "type": "container" },
  "index_prefix": "filebeat-fluentbit-dev"
}
```

`index_prefix` is consumed by the output plugin for index routing. The field is
also stored in the document (the `es` plugin does not strip it after reading). The
field name avoids a leading `_` to prevent OpenSearch warnings about unsupported
field name prefixes.

## Deployment model

- **One DaemonSet per node-owning tenant.** A DaemonSet pod reads all container logs on
  its node via `/var/log/containers/*.log`, regardless of which namespace those pods
  belong to. Namespaces that share nodes (e.g. workload-only namespaces like knative)
  should NOT get their own DaemonSet — that would cause duplicate log collection.
- **nodeSelector** uses `tenantname: <namespace>` to schedule pods only on nodes owned
  by that tenant.
- **RBAC** — the ServiceAccount needs `get`/`list`/`watch` on `namespaces`, `pods`, and
  `nodes` (ClusterRole) so the kubernetes filter can enrich logs with metadata.

## OpenSearch gotchas

### Field type conflicts

OpenSearch infers field types from the first document indexed. If the same field appears
with different types across indices (e.g. `timestamp` as `date` in one index, `text` in
another), queries across those indices fail with "field type conflict."

**Known case:** `log_processed.timestamp` — different apps emit `timestamp` in different
formats. Fixed by removing `log_processed` entirely in the Lua filter.

**Known case:** `log` field — initially mapped as `text` by existing indices, then we
tried to send `log` as an object (`{file: {path: "..."}}`). Fix required deleting the
old indices so OpenSearch could infer the correct `object` mapping.

### Index lifecycle

Daily indices (`fluentbit-{tenant}-YYYY.MM.DD`) are created automatically. No ILM/ISM
policies are configured by default — add them in OpenSearch if retention management is
needed.

## Differences from Filebeat

| Aspect                  | Filebeat                    | Fluent Bit (this config)       |
| ----------------------- | --------------------------- | ------------------------------ |
| Agent type              | `filebeat`                  | `fluent-bit`                   |
| Index prefix            | `filebeat-{tenant}`         | `filebeat-fluentbit-{tenant}`  |
| K8s metadata structure  | Nested (native)             | Nested (via Lua restructuring) |
| `ecs.version`           | `1.6.0`                     | Omitted (filler)               |
| `datastream`            | `unknown`                   | Omitted (filler)               |
| `tenantLevelIndex`      | `unknown`                   | Omitted (filler)               |
| Log field               | `message` + `log.file.path` | `message` + `log.file.path`    |
| Container runtime field | From autodiscover           | Hardcoded `containerd`         |

## Template placeholders

The `generate.sh` script substitutes these placeholders in the YAML templates:

| Placeholder        | Source       | Used in            |
| ------------------ | ------------ | ------------------ |
| `{{NAMESPACE}}`    | 1st argument | Both templates     |
| `{{DOCKER_IMAGE}}` | 2nd argument | DaemonSet template |
| `{{ES_HOST}}`      | 3rd argument | DaemonSet template |

## DaemonSet environment variables

Set in the DaemonSet template and consumed by `fluent-bit.conf` or the Lua script:

| Variable              | Consumer        | Purpose                                      |
| --------------------- | --------------- | -------------------------------------------- |
| `ES_HOST`             | fluent-bit.conf | OpenSearch endpoint hostname                 |
| `ES_PORT`             | fluent-bit.conf | OpenSearch port (default `443`)              |
| `ES_TLS`              | fluent-bit.conf | TLS on/off (default `On`)                    |
| `ALIAS`               | Lua script      | Override index prefix                        |
| `TENANT_LEVEL_INDEX`  | (reserved)      | Tenant-level index flag                      |
| `SERVICE_LEVEL_INDEX` | Lua script      | Include container name in index if `yes`     |
| `INDEX_PREFIX`        | Lua script      | Index prefix (default `filebeat-fluentbit-`) |

## Docker image

The Dockerfile must be built from the **repository root** (not the fluentbit directory),
because `COPY` paths reference `./diagnostics/opensearch/fluentbit/`:

```bash
docker build -f diagnostics/opensearch/fluentbit/Dockerfile -t duplocloud/fluentbit:tag .
```
