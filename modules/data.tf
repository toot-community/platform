data "digitalocean_vpc" "this" {
  name = var.vpc_name
}

data "digitalocean_kubernetes_cluster" "this" {
  name = var.kubernetes_cluster_name
}
