resource "digitalocean_database_cluster" "postgresql" {
  engine               = "pg"
  name                 = var.db_cluster_name
  version              = var.db_cluster_version
  node_count           = var.db_node_count
  region               = var.region
  size                 = var.db_cluster_size
  private_network_uuid = data.digitalocean_vpc.this.id
}

resource "digitalocean_database_user" "postgresql" {
  cluster_id = digitalocean_database_cluster.postgresql.id
  name       = var.db_username
}

resource "digitalocean_database_db" "postgresql" {
  cluster_id = digitalocean_database_cluster.postgresql.id
  name       = var.db_name
}

resource "digitalocean_database_connection_pool" "postgresql" {
  cluster_id = digitalocean_database_cluster.postgresql.id
  db_name    = var.db_name
  user       = var.db_username
  mode       = "transaction"
  name       = var.connection_pool_name
  size       = var.connection_pool_size
}
