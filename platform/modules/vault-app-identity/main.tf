resource "vault_policy" "this" {
  name = "${var.app_name}-readonly"

  policy = <<-EOT
    path "${var.kv_mount_path}/data/${var.app_name}/*" {
      capabilities = ["read"]
    }

    path "${var.kv_mount_path}/metadata/${var.app_name}/*" {
      capabilities = ["read", "list"]
    }
  EOT
}

resource "vault_kubernetes_auth_backend_role" "this" {
  backend                          = var.auth_backend_path
  role_name                        = var.app_name
  audience                         = var.audience
  bound_service_account_names      = [var.service_account]
  bound_service_account_namespaces = [var.namespace]
  token_ttl                        = var.token_ttl
  token_policies                   = [vault_policy.this.name]
}
