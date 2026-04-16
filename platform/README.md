# Platform

Provisions the base infrastructure for the toot.community Kubernetes cluster on Hetzner Cloud with Talos Linux, including Cloudflare R2 storage buckets and per-bucket S3 credentials.

## Architecture

- **Control plane**: Hetzner Cloud VMs running Talos Linux, spread across a placement group
- **Workers**: Bare-metal dedicated servers running Talos Linux
- **Networking**: KubeSpan (WireGuard mesh) replaces traditional VPC networking
- **API endpoint**: Hetzner floating IP managed by Talos VIP controller
- **State backend**: Cloudflare R2 with S3-compatible API and native lock files
- **Secrets**: HashiCorp Vault with Kubernetes auth, managed by Vault Secrets Operator (VSO)
- **Storage credentials**: R2 bucket credentials written directly to Vault KV v2

## Prerequisites

| Tool | Version |
|------|---------|
| OpenTofu | `~> 1.11` |
| Talos | See `talos_version` in tfvars |

### Required Environment Variables

```bash
export HCLOUD_TOKEN="..."            # Hetzner Cloud API token (provider auth)
export TF_VAR_hcloud_token="..."     # Hetzner Cloud API token (passed to Talos VIP controller)
export CLOUDFLARE_API_TOKEN="..."    # Cloudflare API token (provider auth)
export AWS_ACCESS_KEY_ID="..."       # R2 state backend credentials
export AWS_SECRET_ACCESS_KEY="..."   # R2 state backend credentials
export VAULT_ADDR="..."              # Vault server address
export VAULT_TOKEN="..."             # Vault authentication token
```

## Usage

```bash
tofu init
tofu plan
tofu apply
```

## Modules

| Module | Description |
|--------|-------------|
| [s3-identity](modules/s3-identity/) | Creates an R2 bucket with a scoped API token for S3-compatible access, optionally writing credentials to Vault |
| [vault-app-identity](modules/vault-app-identity/) | Creates a Vault readonly KV policy and Kubernetes auth role for an application |

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | ~> 1.11 |
| <a name="requirement_cloudflare"></a> [cloudflare](#requirement\_cloudflare) | ~> 5.13 |
| <a name="requirement_hcloud"></a> [hcloud](#requirement\_hcloud) | ~> 1.60 |
| <a name="requirement_talos"></a> [talos](#requirement\_talos) | ~> 0.10 |
| <a name="requirement_vault"></a> [vault](#requirement\_vault) | ~> 4.7 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_cloudflare"></a> [cloudflare](#provider\_cloudflare) | 5.18.0 |
| <a name="provider_hcloud"></a> [hcloud](#provider\_hcloud) | 1.60.1 |
| <a name="provider_talos"></a> [talos](#provider\_talos) | 0.10.1 |
| <a name="provider_vault"></a> [vault](#provider\_vault) | 4.8.0 |

## Modules

| Name | Source | Version |
| ---- | ------ | ------- |
| <a name="module_s3_identity"></a> [s3\_identity](#module\_s3\_identity) | ./modules/s3-identity | n/a |
| <a name="module_vault_app_identity"></a> [vault\_app\_identity](#module\_vault\_app\_identity) | ./modules/vault-app-identity | n/a |

## Resources

| Name | Type |
| ---- | ---- |
| [hcloud_firewall.controlplane](https://registry.terraform.io/providers/hetznercloud/hcloud/latest/docs/resources/firewall) | resource |
| [hcloud_firewall_attachment.controlplane](https://registry.terraform.io/providers/hetznercloud/hcloud/latest/docs/resources/firewall_attachment) | resource |
| [hcloud_floating_ip.api](https://registry.terraform.io/providers/hetznercloud/hcloud/latest/docs/resources/floating_ip) | resource |
| [hcloud_floating_ip_assignment.api](https://registry.terraform.io/providers/hetznercloud/hcloud/latest/docs/resources/floating_ip_assignment) | resource |
| [hcloud_placement_group.controlplane](https://registry.terraform.io/providers/hetznercloud/hcloud/latest/docs/resources/placement_group) | resource |
| [hcloud_server.controlplane](https://registry.terraform.io/providers/hetznercloud/hcloud/latest/docs/resources/server) | resource |
| [talos_cluster_kubeconfig.this](https://registry.terraform.io/providers/siderolabs/talos/latest/docs/resources/cluster_kubeconfig) | resource |
| [talos_machine_bootstrap.this](https://registry.terraform.io/providers/siderolabs/talos/latest/docs/resources/machine_bootstrap) | resource |
| [talos_machine_configuration_apply.controlplane](https://registry.terraform.io/providers/siderolabs/talos/latest/docs/resources/machine_configuration_apply) | resource |
| [talos_machine_configuration_apply.metal_worker](https://registry.terraform.io/providers/siderolabs/talos/latest/docs/resources/machine_configuration_apply) | resource |
| [talos_machine_secrets.this](https://registry.terraform.io/providers/siderolabs/talos/latest/docs/resources/machine_secrets) | resource |
| [vault_auth_backend.kubernetes](https://registry.terraform.io/providers/hashicorp/vault/latest/docs/resources/auth_backend) | resource |
| [vault_auth_backend.userpass](https://registry.terraform.io/providers/hashicorp/vault/latest/docs/resources/auth_backend) | resource |
| [vault_kubernetes_auth_backend_config.this](https://registry.terraform.io/providers/hashicorp/vault/latest/docs/resources/kubernetes_auth_backend_config) | resource |
| [vault_kubernetes_auth_backend_role.vault](https://registry.terraform.io/providers/hashicorp/vault/latest/docs/resources/kubernetes_auth_backend_role) | resource |
| [vault_kubernetes_auth_backend_role.vault_backup](https://registry.terraform.io/providers/hashicorp/vault/latest/docs/resources/kubernetes_auth_backend_role) | resource |
| [vault_kubernetes_auth_backend_role.vault_metrics_rotation](https://registry.terraform.io/providers/hashicorp/vault/latest/docs/resources/kubernetes_auth_backend_role) | resource |
| [vault_mount.kv](https://registry.terraform.io/providers/hashicorp/vault/latest/docs/resources/mount) | resource |
| [vault_policy.metrics_token_rotation](https://registry.terraform.io/providers/hashicorp/vault/latest/docs/resources/policy) | resource |
| [vault_policy.prometheus_metrics](https://registry.terraform.io/providers/hashicorp/vault/latest/docs/resources/policy) | resource |
| [vault_policy.vault_admin](https://registry.terraform.io/providers/hashicorp/vault/latest/docs/resources/policy) | resource |
| [vault_policy.vault_backup](https://registry.terraform.io/providers/hashicorp/vault/latest/docs/resources/policy) | resource |
| [vault_policy.vault_metrics_token_read](https://registry.terraform.io/providers/hashicorp/vault/latest/docs/resources/policy) | resource |
| [vault_token_auth_backend_role.prometheus_metrics](https://registry.terraform.io/providers/hashicorp/vault/latest/docs/resources/token_auth_backend_role) | resource |
| [cloudflare_account_api_token_permission_groups_list.all](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/data-sources/account_api_token_permission_groups_list) | data source |
| [talos_client_configuration.this](https://registry.terraform.io/providers/siderolabs/talos/latest/docs/data-sources/client_configuration) | data source |
| [talos_image_factory_urls.this](https://registry.terraform.io/providers/siderolabs/talos/latest/docs/data-sources/image_factory_urls) | data source |
| [talos_machine_configuration.controlplane](https://registry.terraform.io/providers/siderolabs/talos/latest/docs/data-sources/machine_configuration) | data source |
| [talos_machine_configuration.worker](https://registry.terraform.io/providers/siderolabs/talos/latest/docs/data-sources/machine_configuration) | data source |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_architecture"></a> [architecture](#input\_architecture) | CPU architecture for cloud nodes (amd64 or arm64). | `string` | `"arm64"` | no |
| <a name="input_cloudflare_account_id"></a> [cloudflare\_account\_id](#input\_cloudflare\_account\_id) | Cloudflare account ID for R2 and other Cloudflare resources. | `string` | n/a | yes |
| <a name="input_cluster_name"></a> [cluster\_name](#input\_cluster\_name) | Name of the Kubernetes cluster. | `string` | n/a | yes |
| <a name="input_controlplane_image"></a> [controlplane\_image](#input\_controlplane\_image) | Hetzner Cloud image ID (snapshot) for control plane nodes. | `string` | n/a | yes |
| <a name="input_controlplane_nodes"></a> [controlplane\_nodes](#input\_controlplane\_nodes) | Map of control plane nodes keyed by name, with location and server type. | <pre>map(object({<br/>    location = string<br/>    type     = string<br/>  }))</pre> | n/a | yes |
| <a name="input_hcloud_token"></a> [hcloud\_token](#input\_hcloud\_token) | Hetzner Cloud API token, used by the Talos VIP controller to manage the floating IP. | `string` | n/a | yes |
| <a name="input_kubernetes_version"></a> [kubernetes\_version](#input\_kubernetes\_version) | Target Kubernetes version for the cluster. | `string` | n/a | yes |
| <a name="input_metal_nodes"></a> [metal\_nodes](#input\_metal\_nodes) | Map of bare-metal worker nodes keyed by name, with network and disk configuration. | <pre>map(object({<br/>    public_ipv4_address = string<br/>    public_ipv4_gateway = string<br/>    public_ipv6_address = string<br/>    public_ipv6_gateway = string<br/>    install_disk        = string<br/>  }))</pre> | `{}` | no |
| <a name="input_r2_buckets"></a> [r2\_buckets](#input\_r2\_buckets) | Map of R2 buckets keyed by name. When vault\_secret is set, the bucket's S3 credentials are written to Vault KV v2 at the specified path. | <pre>map(object({<br/>    vault_secret = optional(object({<br/>      mount            = optional(string, "secret")<br/>      path             = string<br/>      access_key_field = optional(string, "access_key_id")<br/>      secret_key_field = optional(string, "secret_access_key")<br/>    }))<br/>  }))</pre> | n/a | yes |
| <a name="input_resource_prefix"></a> [resource\_prefix](#input\_resource\_prefix) | Prefix for all Hetzner resource names to avoid collisions. | `string` | `""` | no |
| <a name="input_talos_metal_schematic_id"></a> [talos\_metal\_schematic\_id](#input\_talos\_metal\_schematic\_id) | Talos image factory schematic ID for bare-metal worker nodes. | `string` | n/a | yes |
| <a name="input_talos_schematic_id"></a> [talos\_schematic\_id](#input\_talos\_schematic\_id) | Talos image factory schematic ID for Hetzner Cloud nodes. | `string` | n/a | yes |
| <a name="input_talos_version"></a> [talos\_version](#input\_talos\_version) | Version of Talos Linux deployed on cluster nodes. | `string` | n/a | yes |
| <a name="input_vault_apps"></a> [vault\_apps](#input\_vault\_apps) | Map of applications that need a Vault app identity (readonly KV policy + Kubernetes auth role). The key is the app name used for policy and role naming. | <pre>map(object({<br/>    namespace       = string<br/>    audience        = optional(string)<br/>    service_account = optional(string, "default")<br/>    token_ttl       = optional(number, 3600)<br/>  }))</pre> | n/a | yes |
| <a name="input_whitelist_admins"></a> [whitelist\_admins](#input\_whitelist\_admins) | List of admin IP CIDRs allowed to access Talos API and Kubernetes API. | `list(string)` | n/a | yes |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_controlplane_ips"></a> [controlplane\_ips](#output\_controlplane\_ips) | Map of control plane node names to their public IPv4 addresses. |
| <a name="output_floating_ip"></a> [floating\_ip](#output\_floating\_ip) | The floating IP address used as the Kubernetes API endpoint. |
| <a name="output_kubeconfig"></a> [kubeconfig](#output\_kubeconfig) | Kubeconfig for the Kubernetes cluster. |
| <a name="output_talosconfig"></a> [talosconfig](#output\_talosconfig) | Talos client configuration for talosctl. |
<!-- END_TF_DOCS -->
