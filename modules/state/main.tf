resource "digitalocean_spaces_bucket" "state" {
  name   = var.state_name
  region = var.region
  acl    = "private"

  lifecycle_rule {
    enabled = true
    noncurrent_version_expiration {
      days = 90
    }
  }

  versioning {
    enabled = true
  }
}

# resource "digitalocean_spaces_bucket_policy" "this" {
#   region = digitalocean_spaces_bucket.state.region
#   bucket = digitalocean_spaces_bucket.state.name

#   policy = jsonencode({
#     "Version" : "2012-10-17",
#     "Statement" : [
#       {
#         "Sid" : "IPAllow",
#         "Effect" : "Deny",
#         "Principal" : "*",
#         "Action" : "s3:*",
#         "Resource" : [
#           "arn:aws:s3:::${digitalocean_spaces_bucket.state.name}",
#           "arn:aws:s3:::${digitalocean_spaces_bucket.state.name}/*"
#         ],
#         "Condition" : {
#           "NotIpAddress" : {
#             "aws:SourceIp" : [var.state_allowed_ips]
#           }
#         }
#       }
#     ]
#   })
# }
