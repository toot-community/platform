resource "digitalocean_vpc" "this" {
  name     = var.vpc_name
  region   = var.region
  ip_range = var.vpc_cidr
}
