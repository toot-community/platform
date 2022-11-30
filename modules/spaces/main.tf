resource "digitalocean_spaces_bucket" "this" {
  name   = var.spaces_name
  region = var.region
  acl    = "private"

  dynamic "cors_rule" {
    for_each = var.cors_hostname.length > 0 ? [1] : []
    content {
      allowed_methods = ["GET"]
      allowed_origins = [join("", ["https://", var.cors_hostname])]
      max_age_seconds = 0
    }
  }
}

resource "digitalocean_certificate" "this" {
  count             = var.cdn_hostname.length > 0 ? 1 : 0
  name              = "cf-origin-cert"
  type              = "custom"
  private_key       = file("../../../../certificate_temp/origin-cert.key")
  leaf_certificate  = file("../../../../certificate_temp/origin-cert.crt")
  certificate_chain = file("../../../../certificate_temp/origin_ca_rsa_root.pem")
}

resource "digitalocean_cdn" "this" {
  count            = var.cdn_hostname.length > 0 ? 1 : 0
  origin           = digitalocean_spaces_bucket.this.bucket_domain_name
  custom_domain    = var.cdn_hostname
  certificate_name = digitalocean_certificate.this.name
}
