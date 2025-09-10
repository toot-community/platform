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

resource "upcloud_managed_object_storage" "this" {
  configured_status = var.upcloud_object_storage_status
  name              = var.upcloud_object_storage_name
  region            = var.upcloud_object_storage_region

  network {
    family = var.upcloud_object_storage_network_family
    name   = var.upcloud_object_storage_network_name
    type   = var.upcloud_object_storage_network_type
  }
}

resource "upcloud_managed_object_storage_bucket" "this" {
  for_each = { for bucket in concat(var.generic_s3_buckets, var.mastodon_s3_buckets) : bucket.name => bucket }

  service_uuid = upcloud_managed_object_storage.this.id
  name         = each.value.name
  depends_on   = [upcloud_managed_object_storage.this]
}

resource "objsto_bucket_policy" "public_read_on_mastodon_buckets" {
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

  depends_on = [upcloud_managed_object_storage_bucket.this]
}

resource "upcloud_managed_object_storage_policy" "this" {
  for_each = { for bucket in concat(var.generic_s3_buckets, var.mastodon_s3_buckets) : bucket.name => bucket }

  name         = "FullAccessOn${replace(title(each.value.name), "-", "")}"
  description  = "Full access for bucket ${each.value.name}"
  service_uuid = upcloud_managed_object_storage.this.id

  document = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "s3:*"
        ],
        Resource = [
          "arn:aws:s3:::${each.value.name}",
          "arn:aws:s3:::${each.value.name}/*"
        ]
      }
    ]
  })
}

resource "upcloud_managed_object_storage_user" "this" {
  for_each = { for bucket in concat(var.generic_s3_buckets, var.mastodon_s3_buckets) : bucket.name => bucket }

  service_uuid = upcloud_managed_object_storage.this.id
  username     = "${each.value.name}-rw"
}

resource "upcloud_managed_object_storage_user_access_key" "this" {
  for_each = upcloud_managed_object_storage_user.this

  username     = each.value.username
  status       = "Active"
  service_uuid = upcloud_managed_object_storage.this.id
  depends_on   = [upcloud_managed_object_storage_user.this]
}

resource "upcloud_managed_object_storage_user_policy" "this" {
  for_each = upcloud_managed_object_storage_user.this

  username     = each.value.username
  name         = upcloud_managed_object_storage_policy.this[each.key].name
  service_uuid = upcloud_managed_object_storage.this.id
  depends_on   = [upcloud_managed_object_storage_user.this, upcloud_managed_object_storage_policy.this]
}

resource "upcloud_managed_object_storage_user" "terraform" {
  service_uuid = upcloud_managed_object_storage.this.id
  username     = "terraform"
}

resource "upcloud_managed_object_storage_user_access_key" "terraform" {
  username     = upcloud_managed_object_storage_user.terraform.username
  status       = var.upcloud_object_storage_management_user_name
  service_uuid = upcloud_managed_object_storage.this.id
  depends_on   = [upcloud_managed_object_storage_user.terraform]
}

resource "upcloud_managed_object_storage_user_policy" "terraform" {
  username     = upcloud_managed_object_storage_user.terraform.username
  name         = var.upcloud_object_storage_management_user_policy_name
  service_uuid = upcloud_managed_object_storage.this.id
  depends_on   = [upcloud_managed_object_storage_user_policy.terraform, upcloud_managed_object_storage_user.terraform]
}
