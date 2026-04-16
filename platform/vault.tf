# --- KV v2 Secrets Engine ---

resource "vault_mount" "kv" {
  path = "secret"
  type = "kv"

  options = {
    version = "2"
  }
}

# --- Auth Backend Mounts ---

resource "vault_auth_backend" "kubernetes" {
  type = "kubernetes"
}

resource "vault_auth_backend" "userpass" {
  type = "userpass"
  # User accounts managed out-of-band.
}

# --- Kubernetes Auth Configuration ---

resource "vault_kubernetes_auth_backend_config" "this" {
  backend                = vault_auth_backend.kubernetes.path
  kubernetes_host        = "https://kubernetes.default.svc.cluster.local:443"
  disable_iss_validation = true
  disable_local_ca_jwt   = false
}

# --- App Identities (standard readonly KV + K8s auth role) ---

module "vault_app_identity" {
  for_each = var.vault_apps
  source   = "./modules/vault-app-identity"

  app_name          = each.key
  audience          = each.value.audience
  namespace         = each.value.namespace
  service_account   = each.value.service_account
  token_ttl         = each.value.token_ttl
  auth_backend_path = vault_auth_backend.kubernetes.path
  kv_mount_path     = vault_mount.kv.path
}

# --- Custom Kubernetes Auth Roles ---
# Special roles that do not follow the standard app-identity pattern.

resource "vault_kubernetes_auth_backend_role" "vault" {
  backend                          = vault_auth_backend.kubernetes.path
  role_name                        = "vault"
  audience                         = "vault"
  bound_service_account_names      = ["default"]
  bound_service_account_namespaces = ["vault"]
  token_ttl                        = 3600
  token_policies                   = ["default", vault_policy.vault_metrics_token_read.name]
}

resource "vault_kubernetes_auth_backend_role" "vault_backup" {
  backend                          = vault_auth_backend.kubernetes.path
  role_name                        = "vault-backup"
  bound_service_account_names      = ["vault-backup"]
  bound_service_account_namespaces = ["vault"]
  token_ttl                        = 900
  token_policies                   = [vault_policy.vault_backup.name]
  # No audience — backup CronJob uses the default SA token without a custom audience.
}

resource "vault_kubernetes_auth_backend_role" "vault_metrics_rotation" {
  backend                          = vault_auth_backend.kubernetes.path
  role_name                        = "vault-metrics-rotation"
  bound_service_account_names      = ["vault-metrics-rotation"]
  bound_service_account_namespaces = ["vault"]
  token_ttl                        = 300
  token_policies                   = [vault_policy.metrics_token_rotation.name, vault_policy.prometheus_metrics.name]
  # No audience — metrics rotation job uses the default SA token without a custom audience.
}

# --- Token Auth Roles ---

resource "vault_token_auth_backend_role" "prometheus_metrics" {
  role_name        = "prometheus-metrics"
  orphan           = true
  token_period     = 1209600
  token_type       = "service"
  allowed_policies = [vault_policy.prometheus_metrics.name]
}

# --- Custom Policies ---
# Special policies that do not follow the standard app-readonly pattern.

resource "vault_policy" "vault_admin" {
  name = "vault-admin"

  policy = <<-EOT
    path "*" {
      capabilities = ["create", "read", "update", "delete", "list", "sudo"]
    }
  EOT
}

resource "vault_policy" "vault_backup" {
  name = "vault-backup"

  policy = <<-EOT
    path "sys/storage/raft/snapshot" {
      capabilities = ["read", "sudo"]
    }

    path "secret/data/vault/backup/r2" {
      capabilities = ["read"]
    }

    path "secret/metadata/vault/backup/r2" {
      capabilities = ["read"]
    }
  EOT
}

resource "vault_policy" "metrics_token_rotation" {
  name = "metrics-token-rotation"

  policy = <<-EOT
    path "auth/token/create/prometheus-metrics" {
      capabilities = ["create", "update"]
    }

    path "secret/data/vault/metrics-token" {
      capabilities = ["create", "update", "read"]
    }

    path "secret/metadata/vault/metrics-token" {
      capabilities = ["read"]
    }

    path "auth/token/revoke" {
      capabilities = ["update"]
    }
  EOT
}

resource "vault_policy" "prometheus_metrics" {
  name = "prometheus-metrics"

  policy = <<-EOT
    path "sys/metrics" {
      capabilities = ["read"]
    }
  EOT
}

resource "vault_policy" "vault_metrics_token_read" {
  name = "vault-metrics-token-read"

  policy = <<-EOT
    path "secret/data/vault/metrics-token" {
      capabilities = ["read"]
    }

    path "secret/metadata/vault/metrics-token" {
      capabilities = ["read"]
    }
  EOT
}
