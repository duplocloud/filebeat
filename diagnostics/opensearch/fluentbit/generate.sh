#!/usr/bin/env bash
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RBAC_TPL="${DIR}/rbac/rbac.yaml.tpl"
K8S_TPL="${DIR}/ds/fluentbit-k8s.yaml.tpl"

if [ -t 1 ]; then R='\033[0;31m' G='\033[0;32m' B='\033[1m' Z='\033[0m'
else R='' G='' B='' Z=''; fi
err() { echo -e "${R}Error:${Z} $1" >&2; exit 1; }

# Optional --cluster-wide flag
CLUSTER_WIDE=false
if [[ "${1:-}" == "--cluster-wide" ]]; then
    CLUSTER_WIDE=true
    shift
fi

# Kubernetes namespace (full namespace, e.g. duploservices-dev-usw2)
NAMESPACE="${1:-}"
[ -z "$NAMESPACE" ] && read -rp "Enter the K8s namespace (e.g. duploservices-dev-usw2): " NAMESPACE
NAMESPACE="$(echo "$NAMESPACE" | tr -d '[:space:]' | tr '[:upper:]' '[:lower:]')"
[ -z "$NAMESPACE" ] && err "Namespace cannot be empty."
[[ ! "$NAMESPACE" =~ ^[a-z][a-z0-9-]*$ ]] && err "Must be lowercase alphanumeric/hyphens, starting with a letter."

# Docker image
IMAGE="${2:-}"
[ -z "$IMAGE" ] && read -rp "Docker image (e.g. duplocloud/fluentbit:4.2.4-70db2f7...): " IMAGE
[ -z "$IMAGE" ] && err "Docker image cannot be empty."

# ES host - strip scheme, port, and trailing slash to get bare hostname
EHOST="${3:-}"
[ -z "$EHOST" ] && read -rp "Elastic/OpenSearch host (e.g. system-svc-es-oc-default.myapps.duplocloud.net): " EHOST
[ -z "$EHOST" ] && err "Elastic host cannot be empty."
EHOST="$(echo "$EHOST" | sed -E 's|^https?://||; s|:[0-9]+/?$||; s|/$||')"

# Check templates exist
[ ! -f "$RBAC_TPL" ] && err "Template not found: ${RBAC_TPL}"
[ ! -f "$K8S_TPL" ] && err "Template not found: ${K8S_TPL}"

# Mode-dependent values
if $CLUSTER_WIDE; then
    DEPLOY_NAME="cluster"
    TENANT_LOCAL="False"
else
    DEPLOY_NAME="$NAMESPACE"
    TENANT_LOCAL="True"
fi

# Generate RBAC
RBAC_OUT="${DIR}/rbac/rbac-${DEPLOY_NAME}.yaml"
sed -e "s|{{NAMESPACE}}|${NAMESPACE}|g" \
    -e "s|{{DEPLOY_NAME}}|${DEPLOY_NAME}|g" "$RBAC_TPL" > "$RBAC_OUT"

# Generate DaemonSet YAML — first pass: simple sed placeholders
K8S_OUT="${DIR}/ds/fluentbit-k8s-${DEPLOY_NAME}.yaml"
sed -e "s|{{NAMESPACE}}|${NAMESPACE}|g" \
    -e "s|{{DEPLOY_NAME}}|${DEPLOY_NAME}|g" \
    -e "s|{{DOCKER_IMAGE}}|${IMAGE}|g" \
    -e "s|{{ES_HOST}}|${EHOST}|g" \
    -e "s|{{TENANT_LOCAL}}|${TENANT_LOCAL}|g" "$K8S_TPL" > "$K8S_OUT"

# Second pass: replace multi-line block placeholders.
# Write to a temp file and move, avoiding sed -i portability issues (BSD vs GNU).
TMP_OUT="${K8S_OUT}.tmp"
if $CLUSTER_WIDE; then
    # Remove the nodeSelector tenant line; replace tolerations with catch-all
    sed -e '/{{NODE_SELECTOR_TENANT}}/d' \
        -e 's|^{{TOLERATIONS}}$|      tolerations:\
        - operator: Exists|' "$K8S_OUT" > "$TMP_OUT"
else
    # Replace nodeSelector tenant placeholder; replace tolerations with spot-only
    sed -e "s|{{NODE_SELECTOR_TENANT}}|        tenantname: ${NAMESPACE}|" \
        -e 's|^{{TOLERATIONS}}$|      tolerations:\
        - effect: NoExecute\
          key: duplocloud.net/spot-instance\
          operator: Exists|' "$K8S_OUT" > "$TMP_OUT"
fi
mv "$TMP_OUT" "$K8S_OUT"

echo -e "\n${G}Generated:${Z}"
echo -e "  ${RBAC_OUT}"
echo -e "  ${K8S_OUT}"
if $CLUSTER_WIDE; then
    echo -e "\n${B}Mode:${Z} cluster-wide (all nodes, all namespaces)"
fi
echo -e "\n${B}Step 1:${Z} Apply RBAC:"
echo -e "  kubectl apply -f ${RBAC_OUT}"
echo -e "\n${B}Step 2:${Z} Apply the DaemonSet:"
echo -e "  kubectl apply -f ${K8S_OUT}"
