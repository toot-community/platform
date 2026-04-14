# Vault

HashiCorp Vault OSS deployed as a 3-replica HA Raft cluster with Vault Secrets Operator (VSO).
Replaces 1Password Connect for cluster secret management.

## Architecture

- **Vault** 1.21.4 — 3 pods, Raft integrated storage, AWS KMS auto-unseal
- **VSO** 1.3.0 — 2 replicas, syncs Vault KV secrets to Kubernetes Secrets via `VaultStaticSecret` CRDs
- **TLS** — cert-manager self-signed internal CA (`vault-ca-tls`), no `skipTLSVerify` anywhere
- **Storage** — `local-path` StorageClass (Raft handles replication; no shared storage needed)
- **Backups** — Raft snapshots every 6h to Cloudflare R2 (`toot-community-vault-raft-backups`)
- **Auth** — Kubernetes auth for workloads, userpass + TOTP MFA for admin (`jorijn`)
- **Access** — Teleport at `tc-vault.teleport.jorijn.com`

## Directory structure

```
vault/
├── kustomization.yaml          # Main entry point: Helm charts, patches, resources
├── values.yaml                 # Vault Helm chart values (HA, Raft, KMS, TLS)
├── vso-values.yaml             # VSO Helm chart values (replicas, PDB, connection)
├── namespace.yaml              # vault namespace with pod-security baseline
├── vault-auth-global.yaml      # VaultAuthGlobal — cluster-wide K8s auth defaults
├── networkpolicies.yaml        # Default deny + Raft (8201) + API (8200) allow
├── rules.yaml                  # PrometheusRule alerts (sealed, down, leader, audit, etc.)
├── certificates/
│   └── vault-tls.yaml          # Self-signed CA chain → server certificate
└── backup/
    └── raft-snapshot.yaml      # CronJob: snapshot + upload to R2
```

## KV v2 path convention

```
secret/<service>/<secret-name>
```

Example: `secret/vault/backup/r2` holds the R2 credentials used by the backup CronJob.

## Onboarding a new app (OnePasswordItem migration)

Each app that consumes secrets from Vault needs four things:

### 1. Vault KV secret

Store the secret data at `secret/<app>/<secret-name>` with the same field names the
workload expects (matching the existing Kubernetes Secret keys).

```sh
vault kv put secret/<app>/<secret-name> KEY1=value1 KEY2=value2
```

### 2. Vault policy

Read-only access scoped to the app's path:

```sh
vault policy write <app>-kv-ro - <<EOF
path "secret/data/<app>/*" {
  capabilities = ["read"]
}
path "secret/metadata/<app>/*" {
  capabilities = ["read", "list"]
}
EOF
```

### 3. Vault Kubernetes auth role

Bind the app's namespace and service account to the policy:

```sh
vault write auth/kubernetes/role/<app> \
  bound_service_account_names=default \
  bound_service_account_namespaces=<namespace> \
  policies=<app>-kv-ro \
  audience=vault \
  ttl=1h
```

### 4. Kubernetes CRDs (in the app's namespace)

**VaultAuth** — per-namespace auth binding (inherits globals from `VaultAuthGlobal`):

```yaml
apiVersion: secrets.hashicorp.com/v1beta1
kind: VaultAuth
metadata:
  name: default
  namespace: <namespace>
spec:
  vaultConnectionRef: vault/default
  method: kubernetes
  mount: kubernetes
  kubernetes:
    role: <app>
    serviceAccount: default
  vaultAuthGlobalRef:
    name: default
    namespace: vault
    allowDefault: true
```

**VaultStaticSecret** — replaces `OnePasswordItem`, creates/manages the Kubernetes Secret:

```yaml
apiVersion: secrets.hashicorp.com/v1beta1
kind: VaultStaticSecret
metadata:
  name: <secret-name>
  namespace: <namespace>
spec:
  mount: secret
  type: kv-v2
  path: <app>/<secret-name>
  refreshAfter: "1h"
  destination:
    name: <secret-name>   # must match the existing K8s Secret name
    create: true
    overwrite: true
```

### Checklist

1. `vault kv put` the secret data
2. `vault policy write` the read-only policy
3. `vault write auth/kubernetes/role/...` the auth role
4. Add `VaultAuth` + `VaultStaticSecret` CRDs to the app's manifests
5. Verify the Kubernetes Secret is created with correct data
6. Remove the old `OnePasswordItem` CRD

## Bootstrap secrets

The only secret not managed by Vault itself is `vault-aws-kms-credentials` (AWS KMS unseal
credentials), created manually via `kubectl`. This avoids a circular dependency.

## CLI access

```sh
# via Teleport proxy
tsh proxy app tc-vault --port 18200 &
export VAULT_ADDR=http://127.0.0.1:18200
vault login -method=userpass username=jorijn
```
