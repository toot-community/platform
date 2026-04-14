#!/usr/bin/env bash
set -euo pipefail

# Migrates all OnePasswordItem secrets to Vault + VaultStaticSecret.
#
# For each OnePasswordItem:
#   1. Reads the current secret data from Kubernetes
#   2. Stores it in Vault at secret/<vault-prefix>/<secret-name>
#   3. Creates Vault policy + Kubernetes auth role (if not exists)
#   4. Generates vault-auth.yaml + <secret-name>.yaml in the app directory
#   5. Replaces the OnePasswordItem YAML with the VaultStaticSecret YAML
#
# Usage:
#   ./migrate-op-to-vault.sh [--dry-run]

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
DRY_RUN=false

[[ "${1:-}" == "--dry-run" ]] && DRY_RUN=true

log() {
  local level="$1"; shift
  printf '[%s] [%s] %s\n' "$(date +%H:%M:%S)" "${level}" "$*"
}

fatal() {
  log "ERROR" "$@"
  exit 1
}

# Each entry: namespace|secret_name|auth_dir|secret_dir|vault_prefix|service_account
# auth_dir: where vault-auth.yaml goes (relative to manifests/applications)
# secret_dir: where <secret-name>.yaml goes (relative to manifests/applications)
# vault_prefix is used for the Vault path, policy name, and auth role name
MIGRATIONS=(
  "dex|dex-secrets|dex|dex|dex|default"
  "dex|static-client-secrets|dex|dex|dex|default"
  "kube-system|hcloud|talos-ccm|talos-ccm|talos-ccm|default"
  "longhorn-system|longhorn-backups-credentials|longhorn|longhorn/secrets|longhorn|default"
  "microblog-network|database-s3-credentials|mastodon/overlays/microblog.network|mastodon/overlays/microblog.network|microblog-network|default"
  "microblog-network|mastodon-secrets-env|mastodon/overlays/microblog.network|mastodon/overlays/microblog.network|microblog-network|default"
  "n8n|database-s3-credentials|n8n|n8n|n8n|default"
  "n8n|n8n-secrets|n8n|n8n|n8n|default"
  "robusta|robusta-secrets-env|robusta|robusta|robusta|default"
  "toot-community|database-s3-credentials|mastodon/overlays/toot.community|mastodon/overlays/toot.community|toot-community|default"
  "toot-community|mastodon-secrets-env|mastodon/overlays/toot.community|mastodon/overlays/toot.community|toot-community|default"
  "victoriametrics|grafana-oidc-credentials|victoriametrics|victoriametrics|victoriametrics|default"
)

# Track which vault prefixes we've already created policies/roles for
declare -A CREATED_ROLES

store_secret_in_vault() {
  local vault_prefix="$1"
  local secret_name="$2"
  local namespace="$3"

  log "INFO" "Reading secret ${namespace}/${secret_name} from Kubernetes"
  local secret_json
  secret_json=$(kubectl get secret "${secret_name}" -n "${namespace}" -o json 2>&1) || {
    log "ERROR" "Failed to read secret ${namespace}/${secret_name}: ${secret_json}"
    return 1
  }

  # Build vault kv put arguments from secret data
  local -a kv_args=()
  while IFS='=' read -r key value; do
    [[ -z "${key}" ]] && continue
    kv_args+=("${key}=${value}")
  done < <(echo "${secret_json}" | python3 -c "
import sys, json, base64
data = json.load(sys.stdin).get('data', {})
for k, v in sorted(data.items()):
    print(f'{k}={base64.b64decode(v).decode(\"utf-8\", errors=\"replace\")}')
")

  if ((${#kv_args[@]} == 0)); then
    log "WARN" "No data keys found in secret ${namespace}/${secret_name}, skipping Vault write"
    return 0
  fi

  local vault_path="secret/${vault_prefix}/${secret_name}"
  log "INFO" "Writing ${#kv_args[@]} keys to Vault at ${vault_path}"

  if [[ "${DRY_RUN}" == "true" ]]; then
    log "INFO" "[dry-run] vault kv put ${vault_path} <${#kv_args[@]} keys>"
  else
    vault kv put "${vault_path}" "${kv_args[@]}"
  fi
}

create_vault_role() {
  local vault_prefix="$1"
  local namespace="$2"
  local service_account="$3"

  # Skip if already created in this run
  if [[ -n "${CREATED_ROLES[${vault_prefix}]:-}" ]]; then
    log "INFO" "Vault role '${vault_prefix}' already created, skipping"
    return 0
  fi

  local policy_name="${vault_prefix}-readonly"
  local policy_hcl
  policy_hcl=$(cat <<EOF
path "secret/data/${vault_prefix}/*" {
  capabilities = ["read"]
}

path "secret/metadata/${vault_prefix}/*" {
  capabilities = ["read", "list"]
}
EOF
)

  log "INFO" "Creating Vault policy: ${policy_name}"
  if [[ "${DRY_RUN}" == "true" ]]; then
    log "INFO" "[dry-run] vault policy write ${policy_name}"
  else
    echo "${policy_hcl}" | vault policy write "${policy_name}" -
  fi

  log "INFO" "Creating Kubernetes auth role: ${vault_prefix} (ns=${namespace}, sa=${service_account})"
  if [[ "${DRY_RUN}" == "true" ]]; then
    log "INFO" "[dry-run] vault write auth/kubernetes/role/${vault_prefix}"
  else
    vault write "auth/kubernetes/role/${vault_prefix}" \
      bound_service_account_names="${service_account}" \
      bound_service_account_namespaces="${namespace}" \
      policies="${policy_name}" \
      audience=vault \
      ttl=1h
  fi

  CREATED_ROLES[${vault_prefix}]=1
}

write_vault_auth() {
  local app_dir="$1"
  local vault_prefix="$2"
  local namespace="$3"
  local service_account="$4"
  local vault_auth_file="${app_dir}/vault-auth.yaml"

  if [[ -f "${vault_auth_file}" ]]; then
    log "INFO" "vault-auth.yaml already exists in ${app_dir}, skipping"
    return 0
  fi

  log "INFO" "Writing ${vault_auth_file}"
  if [[ "${DRY_RUN}" == "true" ]]; then
    log "INFO" "[dry-run] would write vault-auth.yaml"
    return 0
  fi

  cat > "${vault_auth_file}" <<EOF
apiVersion: secrets.hashicorp.com/v1beta1
kind: VaultAuth
metadata:
  name: default
  namespace: ${namespace}
spec:
  vaultConnectionRef: vault/default
  method: kubernetes
  mount: kubernetes
  kubernetes:
    role: ${vault_prefix}
    serviceAccount: ${service_account}
  vaultAuthGlobalRef:
    name: default
    namespace: vault
    allowDefault: true
EOF
}

write_vault_static_secret() {
  local app_dir="$1"
  local vault_prefix="$2"
  local secret_name="$3"
  local namespace="$4"
  local secret_file="${app_dir}/${secret_name}.yaml"

  if [[ -f "${secret_file}" ]]; then
    if grep -q "kind: OnePasswordItem" "${secret_file}" 2>/dev/null; then
      log "INFO" "${secret_name}.yaml is an old OnePasswordItem, replacing"
    else
      log "WARN" "${secret_name}.yaml already exists as VaultStaticSecret in ${app_dir}, skipping"
      return 0
    fi
  fi

  log "INFO" "Writing ${secret_file}"
  if [[ "${DRY_RUN}" == "true" ]]; then
    log "INFO" "[dry-run] would write ${secret_name}.yaml"
    return 0
  fi

  cat > "${secret_file}" <<EOF
apiVersion: secrets.hashicorp.com/v1beta1
kind: VaultStaticSecret
metadata:
  name: ${secret_name}
  namespace: ${namespace}
spec:
  vaultAuthRef: default
  mount: secret
  type: kv-v2
  path: ${vault_prefix}/${secret_name}
  refreshAfter: "1h"
  destination:
    name: ${secret_name}
    create: true
    overwrite: true
EOF
}

# --- Main ---

log "INFO" "Starting 1Password -> Vault migration (mode: $([[ "${DRY_RUN}" == "true" ]] && echo "dry-run" || echo "apply"))"
log "INFO" "Migrating ${#MIGRATIONS[@]} secrets"
echo ""

for entry in "${MIGRATIONS[@]}"; do
  IFS='|' read -r namespace secret_name auth_dir_rel secret_dir_rel vault_prefix service_account <<< "${entry}"
  auth_dir="${REPO_ROOT}/manifests/applications/${auth_dir_rel}"
  secret_dir="${REPO_ROOT}/manifests/applications/${secret_dir_rel}"

  log "INFO" "=== Migrating ${namespace}/${secret_name} ==="

  if [[ ! -d "${secret_dir}" ]]; then
    log "ERROR" "Secret directory not found: ${secret_dir}, skipping"
    continue
  fi

  # 1. Store secret in Vault
  store_secret_in_vault "${vault_prefix}" "${secret_name}" "${namespace}" || continue

  # 2. Create Vault policy + role (once per vault_prefix)
  create_vault_role "${vault_prefix}" "${namespace}" "${service_account}"

  # 3. Write vault-auth.yaml
  write_vault_auth "${auth_dir}" "${vault_prefix}" "${namespace}" "${service_account}"

  # 4. Write VaultStaticSecret
  write_vault_static_secret "${secret_dir}" "${vault_prefix}" "${secret_name}" "${namespace}"

  echo ""
done

log "INFO" "Migration complete!"
log "INFO" ""
log "INFO" "Next steps:"
log "INFO" "  1. Remove the old OnePasswordItem YAMLs from each app directory"
log "INFO" "  2. Update each kustomization.yaml to reference vault-auth.yaml + <secret>.yaml"
log "INFO" "  3. Commit, push, and let ArgoCD sync"
