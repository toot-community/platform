data "digitalocean_kubernetes_cluster" "this" {
  name = var.kubernetes_cluster_name
}

resource "digitalocean_database_firewall" "postgresql" {
  cluster_id = digitalocean_database_cluster.postgresql.id

  rule {
    type  = "k8s"
    value = data.digitalocean_kubernetes_cluster.this.id
  }
}

resource "digitalocean_database_firewall" "redis" {
  cluster_id = digitalocean_database_cluster.redis.id

  rule {
    type  = "k8s"
    value = data.digitalocean_kubernetes_cluster.this.id
  }
}
