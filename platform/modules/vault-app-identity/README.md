# Vault App Identity

Creates a standard Vault "app identity" for a Kubernetes workload: a readonly KV policy and a Kubernetes auth role that binds a service account to that policy.

## What it creates

1. **Vault policy** (`<app_name>-readonly`) granting read access to `<kv_mount>/data/<app_name>/*` and read/list access to `<kv_mount>/metadata/<app_name>/*`.
2. **Kubernetes auth role** (`<app_name>`) bound to the specified service account and namespace, issuing tokens with the readonly policy.

## Usage

```hcl
module "vault_app_identity" {
  for_each = var.vault_apps
  source   = "./modules/vault-app-identity"

  app_name          = each.key
  namespace         = each.value.namespace
  auth_backend_path = vault_auth_backend.kubernetes.path
  kv_mount_path     = vault_mount.kv.path
}
```

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.10.0 |
| <a name="requirement_vault"></a> [vault](#requirement\_vault) | >= 4.7 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_vault"></a> [vault](#provider\_vault) | >= 4.7 |

## Modules

No modules.

## Resources

| Name | Type |
| ---- | ---- |
| [vault_kubernetes_auth_backend_role.this](https://registry.terraform.io/providers/hashicorp/vault/latest/docs/resources/kubernetes_auth_backend_role) | resource |
| [vault_policy.this](https://registry.terraform.io/providers/hashicorp/vault/latest/docs/resources/policy) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_app_name"></a> [app\_name](#input\_app\_name) | Application name. Used to derive the policy name (<app>-readonly) and Kubernetes auth role name. | `string` | n/a | yes |
| <a name="input_audience"></a> [audience](#input\_audience) | Audience claim for JWT validation on the Kubernetes auth role. | `string` | `null` | no |
| <a name="input_auth_backend_path"></a> [auth\_backend\_path](#input\_auth\_backend\_path) | Path of the Kubernetes auth backend. | `string` | n/a | yes |
| <a name="input_kv_mount_path"></a> [kv\_mount\_path](#input\_kv\_mount\_path) | Path of the KV v2 secrets engine mount. | `string` | n/a | yes |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | Kubernetes namespace the application runs in. | `string` | n/a | yes |
| <a name="input_service_account"></a> [service\_account](#input\_service\_account) | Kubernetes service account name bound to the auth role. | `string` | `"default"` | no |
| <a name="input_token_ttl"></a> [token\_ttl](#input\_token\_ttl) | TTL in seconds for tokens issued by the Kubernetes auth role. | `number` | `3600` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_policy_name"></a> [policy\_name](#output\_policy\_name) | Name of the created Vault policy. |
| <a name="output_role_name"></a> [role\_name](#output\_role\_name) | Name of the created Kubernetes auth role. |
<!-- END_TF_DOCS -->
