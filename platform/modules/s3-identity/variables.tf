variable "account_id" {
  description = "Cloudflare account ID."
  type        = string
}

variable "bucket_name" {
  description = "Name of the R2 bucket to create or manage."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-]{1,61}[a-z0-9]$", var.bucket_name))
    error_message = "Bucket name must be 3-63 lowercase alphanumeric characters or hyphens, starting and ending with alphanumeric."
  }
}

variable "r2_read_permission_group_id" {
  description = "Cloudflare permission group ID for Workers R2 Storage Bucket Item Read."
  type        = string
}

variable "r2_write_permission_group_id" {
  description = "Cloudflare permission group ID for Workers R2 Storage Bucket Item Write."
  type        = string
}

variable "vault_secret" {
  description = "Optional Vault KV v2 configuration. When set, writes the bucket's S3 credentials to the specified mount and path with configurable key names. Use extra_fields to include additional static key/value pairs in the secret."
  type = object({
    mount            = optional(string, "secret")
    path             = string
    access_key_field = optional(string, "access_key_id")
    secret_key_field = optional(string, "secret_access_key")
    extra_fields     = optional(map(string), {})
  })
  default = null
}
