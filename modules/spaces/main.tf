resource "digitalocean_spaces_bucket" "this" {
  name   = var.spaces_name
  region = var.region
  acl    = "private"

  cors_rule {
    allowed_methods = ["GET"]
    allowed_origins = [join("", ["https://", var.cors_hostname])]
    max_age_seconds = 0
  }
}

resource "digitalocean_certificate" "this" {
  name              = "cf-origin-cert"
  type              = "custom"
  private_key       = file("../../../../certificate_temp/origin-cert.key")
  leaf_certificate  = file("../../../../certificate_temp/origin-cert.crt")
  certificate_chain = file("../../../../certificate_temp/origin_ca_rsa_root.pem")
}

resource "digitalocean_cdn" "this" {
  origin           = digitalocean_spaces_bucket.this.bucket_domain_name
  custom_domain    = var.cdn_hostname
  certificate_name = digitalocean_certificate.this.name
}
