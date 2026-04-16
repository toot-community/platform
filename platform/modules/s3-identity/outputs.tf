output "access_key_id" {
  description = "S3-compatible access key ID derived from the Cloudflare API token ID."
  value       = cloudflare_account_token.this.id
  sensitive   = true
}

output "bucket_name" {
  description = "Name of the R2 bucket."
  value       = cloudflare_r2_bucket.this.name
}

output "secret_access_key" {
  description = "S3-compatible secret access key derived from the SHA-256 hash of the Cloudflare API token value."
  value       = sha256(cloudflare_account_token.this.value)
  sensitive   = true
}
