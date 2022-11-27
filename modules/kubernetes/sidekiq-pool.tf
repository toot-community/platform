resource "digitalocean_kubernetes_node_pool" "this" {
  cluster_id = digitalocean_kubernetes_cluster.this.id

  name       = var.sidekiq_pool_name
  size       = var.sidekiq_pool_size
  auto_scale = true
  min_nodes  = var.sidekiq_pool_min_nodes
  max_nodes  = var.sidekiq_pool_max_nodes

  taint {
    key    = "limit"
    value  = "sidekiq"
    effect = "NoSchedule"
  }
}
