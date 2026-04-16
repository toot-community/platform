resource "cloudflare_r2_bucket" "this" {
  account_id = var.account_id
  name       = var.bucket_name

  lifecycle {
    prevent_destroy = true
    # Cloudflare auto-assigns the bucket location on creation; it cannot be
    # changed afterwards and drifts from the Terraform config.
    ignore_changes = [location]
  }
}

resource "vault_kv_secret_v2" "this" {
  count = var.vault_secret != null ? 1 : 0

  mount = var.vault_secret.mount
  name  = var.vault_secret.path

  data_json = jsonencode(merge(
    var.vault_secret.extra_fields,
    {
      (var.vault_secret.access_key_field) = cloudflare_account_token.this.id
      (var.vault_secret.secret_key_field) = sha256(cloudflare_account_token.this.value)
    },
  ))
}

resource "cloudflare_account_token" "this" {
  account_id = var.account_id
  name       = "${var.bucket_name}-rw"

  policies = [{
    effect = "allow"
    resources = jsonencode({
      "com.cloudflare.edge.r2.bucket.${var.account_id}_default_${cloudflare_r2_bucket.this.name}" = "*"
    })
    permission_groups = [
      { id = var.r2_read_permission_group_id },
      { id = var.r2_write_permission_group_id },
    ]
  }]
}
