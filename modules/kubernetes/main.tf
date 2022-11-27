resource "digitalocean_kubernetes_cluster" "this" {
  name          = var.doks_cluster_name
  region        = var.region
  version       = var.doks_cluster_version
  vpc_uuid      = data.digitalocean_vpc.this.id
  auto_upgrade  = true
  surge_upgrade = true
  ha            = false

  maintenance_policy {
    day        = "any"
    start_time = "05:00"
  }

  node_pool {
    name       = var.generic_pool_name
    size       = var.generic_pool_size
    auto_scale = true
    min_nodes  = var.generic_pool_min_nodes
    max_nodes  = var.generic_pool_max_nodes
  }
}
