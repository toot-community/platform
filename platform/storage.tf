resource "minio_s3_bucket" "mastodon_buckets" {
  for_each = { for bucket in var.mastodon_s3_buckets : bucket.name => bucket }

  bucket = each.value.name
  acl    = "private"
}

resource "minio_s3_bucket_policy" "public_read" {
  for_each = minio_s3_bucket.mastodon_buckets

  bucket = each.value.bucket
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          AWS = ["*"]
        },
        Action = [
          "s3:GetObject"
        ],
        Resource = [
          "arn:aws:s3:::${each.value.bucket}/*"
        ]
      }
    ]
  })
}

resource "minio_s3_bucket" "generic_buckets" {
  for_each = { for bucket in var.generic_s3_buckets : bucket.name => bucket }

  bucket = each.value.name
  acl    = "private"
}

resource "exoscale_iam_role" "toot_community_cnpg_storage_rw" {
  description = "Role for Cloudnative-PG to read and write to the toot-community-cnpg-storage bucket"
  editable    = true
  name        = "toot-community-cnpg-storage-rw"
  permissions = []
  policy = {
    default_service_strategy = "deny"
    services = {
      sos = {
        rules = [
          {
            action     = "allow"
            expression = "parameters.bucket == 'toot-community-cnpg-storage' && (operation in ['head-bucket','get-bucket-location','list-objects','list-object-versions','list-multipart-uploads','get-object','head-object','put-object','delete-object','abort-multipart-upload'])"
          },
          {
            action     = "allow"
            expression = "operation == 'list-buckets'"
          },
        ]
        type = "rules"
      }
    }
  }
}
