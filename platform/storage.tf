data "cloudflare_account_api_token_permission_groups_list" "all" {
  account_id = var.cloudflare_account_id
}

locals {
  r2_permission_groups = {
    for pg in data.cloudflare_account_api_token_permission_groups_list.all.result :
    pg.name => pg.id
    if contains([
      "Workers R2 Storage Bucket Item Read",
      "Workers R2 Storage Bucket Item Write",
    ], pg.name)
  }
}

module "s3_identity" {
  for_each = var.r2_buckets
  source   = "./modules/s3-identity"

  account_id                   = var.cloudflare_account_id
  bucket_name                  = each.key
  r2_read_permission_group_id  = local.r2_permission_groups["Workers R2 Storage Bucket Item Read"]
  r2_write_permission_group_id = local.r2_permission_groups["Workers R2 Storage Bucket Item Write"]
  vault_secret                 = each.value.vault_secret
}
