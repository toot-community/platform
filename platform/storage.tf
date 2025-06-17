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
