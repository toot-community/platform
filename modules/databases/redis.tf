resource "digitalocean_database_cluster" "redis" {
  engine               = "redis"
  name                 = var.redis_cluster_name
  version              = var.redis_cluster_version
  node_count           = var.redis_node_count
  region               = var.region
  size                 = var.redis_cluster_size
  private_network_uuid = data.digitalocean_vpc.this.id
  eviction_policy      = "noeviction"
}
