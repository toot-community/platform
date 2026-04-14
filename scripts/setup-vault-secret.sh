#!/usr/bin/env bash
set -euo pipefail

# Sets up everything needed for an application to consume secrets from Vault:
#   1. Creates a Vault KV v2 policy (read-only on secret/data/<app>/*)
#   2. Creates a Kubernetes auth role binding
#   3. Generates VaultAuth and VaultStaticSecret manifests in manifests/applications/<app>/
#
# Usage:
#   ./setup-vault-secret.sh <app-name> <secret-name> [service-account]
#
# Examples:
#   ./setup-vault-secret.sh n8n credentials
#   ./setup-vault-secret.sh mastodon smtp-credentials mastodon-web

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

log() {
  local level="$1"; shift
  printf '[%s] [%s] %s\n' "$(date +%H:%M:%S)" "${level}" "$*"
}

fatal() {
  log "ERROR" "$@"
  exit 1
}

usage() {
  cat <<'USAGE'
Set up Vault secret access for a Kubernetes application.

Usage:
  ./setup-vault-secret.sh [options] <app-name> <secret-name> [service-account]

Arguments:
  app-name          Application name (must match namespace and manifests/applications/ dir)
  secret-name       Name for the secret in Vault (stored at secret/<app>/<secret-name>)
  service-account   Kubernetes service account to bind (default: "default")

Options:
  --label KEY=VALUE   Add a label to the destination Secret (can be repeated)
  -h, --help          Show this help

What this script does:
  1. Creates a Vault policy "<app>-readonly" with read access to secret/data/<app>/*
  2. Creates a Kubernetes auth role "<app>" bound to the service account and namespace
  3. Generates vault-auth.yaml and <secret-name>.yaml in manifests/applications/<app>/

Prerequisites:
  - vault CLI authenticated and configured (VAULT_ADDR, VAULT_TOKEN, etc.)
  - KV v2 secrets engine mounted at "secret"
  - Kubernetes auth method enabled at "kubernetes"

Examples:
  ./setup-vault-secret.sh n8n credentials
  ./setup-vault-secret.sh mastodon smtp-credentials mastodon-web
  ./setup-vault-secret.sh --label app.kubernetes.io/part-of=argocd argocd argocd-secrets
USAGE
}

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || fatal "Missing required command: $1"
}

# --- Parse arguments ---

LABELS=()
POSITIONAL=()
while (($# > 0)); do
  case "$1" in
    -h|--help)
      usage
      exit 0
      ;;
    --label)
      [[ -z "${2:-}" ]] && fatal "--label requires a KEY=VALUE argument"
      LABELS+=("$2")
      shift 2
      ;;
    -*)
      fatal "Unknown flag: $1"
      ;;
    *)
      POSITIONAL+=("$1")
      shift
      ;;
  esac
done

if ((${#POSITIONAL[@]} < 2)); then
  usage
  fatal "Required arguments: <app-name> <secret-name>"
fi

APP_NAME="${POSITIONAL[0]}"
SECRET_NAME="${POSITIONAL[1]}"
SERVICE_ACCOUNT="${POSITIONAL[2]:-default}"

require_cmd vault

APP_DIR="${REPO_ROOT}/manifests/applications/${APP_NAME}"
if [[ ! -d "${APP_DIR}" ]]; then
  fatal "Application directory not found: ${APP_DIR}"
fi

# --- Step 1: Create Vault policy ---

POLICY_NAME="${APP_NAME}-readonly"
POLICY_HCL=$(cat <<EOF
path "secret/data/${APP_NAME}/*" {
  capabilities = ["read"]
}

path "secret/metadata/${APP_NAME}/*" {
  capabilities = ["read", "list"]
}
EOF
)

log "INFO" "Creating Vault policy: ${POLICY_NAME}"
echo "${POLICY_HCL}" | vault policy write "${POLICY_NAME}" -
log "INFO" "Policy '${POLICY_NAME}' created"

# --- Step 2: Create Kubernetes auth role ---

log "INFO" "Creating Kubernetes auth role: ${APP_NAME}"
vault write "auth/kubernetes/role/${APP_NAME}" \
  bound_service_account_names="${SERVICE_ACCOUNT}" \
  bound_service_account_namespaces="${APP_NAME}" \
  policies="${POLICY_NAME}" \
  audience=vault \
  ttl=1h
log "INFO" "Kubernetes auth role '${APP_NAME}' created (sa=${SERVICE_ACCOUNT}, ns=${APP_NAME})"

# --- Step 3: Generate Kubernetes manifests ---

VAULT_AUTH_FILE="${APP_DIR}/vault-auth.yaml"
VAULT_SECRET_FILE="${APP_DIR}/${SECRET_NAME}.yaml"

if [[ -f "${VAULT_AUTH_FILE}" ]]; then
  log "WARN" "vault-auth.yaml already exists at ${VAULT_AUTH_FILE}, skipping"
else
  log "INFO" "Writing ${VAULT_AUTH_FILE}"
  cat > "${VAULT_AUTH_FILE}" <<EOF
apiVersion: secrets.hashicorp.com/v1beta1
kind: VaultAuth
metadata:
  name: default
  namespace: ${APP_NAME}
spec:
  vaultConnectionRef: vault/default
  method: kubernetes
  mount: kubernetes
  kubernetes:
    role: ${APP_NAME}
    serviceAccount: ${SERVICE_ACCOUNT}
  vaultAuthGlobalRef:
    name: default
    namespace: vault
    allowDefault: true
EOF
fi

if [[ -f "${VAULT_SECRET_FILE}" ]]; then
  log "WARN" "${SECRET_NAME}.yaml already exists at ${VAULT_SECRET_FILE}, skipping"
else
  log "INFO" "Writing ${VAULT_SECRET_FILE}"
  cat > "${VAULT_SECRET_FILE}" <<EOF
apiVersion: secrets.hashicorp.com/v1beta1
kind: VaultStaticSecret
metadata:
  name: ${SECRET_NAME}
  namespace: ${APP_NAME}
spec:
  vaultAuthRef: default
  mount: secret
  type: kv-v2
  path: ${APP_NAME}/${SECRET_NAME}
  refreshAfter: "1h"
  destination:
    name: ${SECRET_NAME}
    create: true
    overwrite: true
EOF
  if ((${#LABELS[@]} > 0)); then
    echo "    labels:" >> "${VAULT_SECRET_FILE}"
    for label in "${LABELS[@]}"; do
      echo "      ${label%%=*}: ${label#*=}" >> "${VAULT_SECRET_FILE}"
    done
  fi
fi

# --- Step 4: Remind about kustomization.yaml ---

KUSTOMIZATION_FILE="${APP_DIR}/kustomization.yaml"
if [[ -f "${KUSTOMIZATION_FILE}" ]]; then
  MISSING_RESOURCES=()
  if ! grep -q "vault-auth.yaml" "${KUSTOMIZATION_FILE}"; then
    MISSING_RESOURCES+=("vault-auth.yaml")
  fi
  if ! grep -q "${SECRET_NAME}.yaml" "${KUSTOMIZATION_FILE}"; then
    MISSING_RESOURCES+=("${SECRET_NAME}.yaml")
  fi
  if ((${#MISSING_RESOURCES[@]} > 0)); then
    log "WARN" "Add the following to ${KUSTOMIZATION_FILE} under resources:"
    for r in "${MISSING_RESOURCES[@]}"; do
      log "WARN" "  - ${r}"
    done
  fi
else
  log "WARN" "No kustomization.yaml found in ${APP_DIR} — make sure the new files are included"
fi

# --- Done ---

log "INFO" ""
log "INFO" "Setup complete for '${APP_NAME}'!"
log "INFO" ""
log "INFO" "Next steps:"
log "INFO" "  1. Store your secret in Vault:"
log "INFO" "     vault kv put secret/${APP_NAME}/${SECRET_NAME} KEY=value"
log "INFO" "  2. Add vault-auth.yaml and vault-static-secret.yaml to your kustomization.yaml"
log "INFO" "  3. Commit and push — ArgoCD will sync the VaultAuth and VaultStaticSecret resources"
log "INFO" "  4. The secret '${SECRET_NAME}' will appear in namespace '${APP_NAME}'"
