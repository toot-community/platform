# s3-identity

Creates a Cloudflare R2 bucket and a scoped API token with read/write permissions, producing S3-compatible credentials for application use.

## Usage

```hcl
module "s3_identity" {
  source = "./modules/s3-identity"

  account_id                   = "your-cloudflare-account-id"
  bucket_name                  = "my-bucket"
  r2_read_permission_group_id  = "read-permission-group-id"
  r2_write_permission_group_id = "write-permission-group-id"
}
```

## How credentials are derived

- `access_key_id` is the Cloudflare API token ID
- `secret_access_key` is the SHA-256 hash of the Cloudflare API token value

These are compatible with any S3 client when pointed at the R2 endpoint.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.10.0 |
| <a name="requirement_cloudflare"></a> [cloudflare](#requirement\_cloudflare) | >= 5.13 |
| <a name="requirement_vault"></a> [vault](#requirement\_vault) | >= 4.7 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_cloudflare"></a> [cloudflare](#provider\_cloudflare) | >= 5.13 |
| <a name="provider_vault"></a> [vault](#provider\_vault) | >= 4.7 |

## Modules

No modules.

## Resources

| Name | Type |
| ---- | ---- |
| [cloudflare_account_token.this](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/account_token) | resource |
| [cloudflare_r2_bucket.this](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/r2_bucket) | resource |
| [vault_kv_secret_v2.this](https://registry.terraform.io/providers/hashicorp/vault/latest/docs/resources/kv_secret_v2) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_account_id"></a> [account\_id](#input\_account\_id) | Cloudflare account ID. | `string` | n/a | yes |
| <a name="input_bucket_name"></a> [bucket\_name](#input\_bucket\_name) | Name of the R2 bucket to create or manage. | `string` | n/a | yes |
| <a name="input_r2_read_permission_group_id"></a> [r2\_read\_permission\_group\_id](#input\_r2\_read\_permission\_group\_id) | Cloudflare permission group ID for Workers R2 Storage Bucket Item Read. | `string` | n/a | yes |
| <a name="input_r2_write_permission_group_id"></a> [r2\_write\_permission\_group\_id](#input\_r2\_write\_permission\_group\_id) | Cloudflare permission group ID for Workers R2 Storage Bucket Item Write. | `string` | n/a | yes |
| <a name="input_vault_secret"></a> [vault\_secret](#input\_vault\_secret) | Optional Vault KV v2 configuration. When set, writes the bucket's S3 credentials to the specified mount and path with configurable key names. | <pre>object({<br/>    mount            = optional(string, "secret")<br/>    path             = string<br/>    access_key_field = optional(string, "access_key_id")<br/>    secret_key_field = optional(string, "secret_access_key")<br/>  })</pre> | `null` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_access_key_id"></a> [access\_key\_id](#output\_access\_key\_id) | S3-compatible access key ID derived from the Cloudflare API token ID. |
| <a name="output_bucket_name"></a> [bucket\_name](#output\_bucket\_name) | Name of the R2 bucket. |
| <a name="output_secret_access_key"></a> [secret\_access\_key](#output\_secret\_access\_key) | S3-compatible secret access key derived from the SHA-256 hash of the Cloudflare API token value. |
<!-- END_TF_DOCS -->
