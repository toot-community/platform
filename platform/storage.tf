resource "minio_s3_bucket" "buckets" {
  for_each = { for bucket in var.s3_buckets : bucket.name => bucket }

  bucket = each.value.name
  acl    = each.value.acl
}
