module "databases" {
  source = "../../../modules/databases"

  # PostgreSQL
  db_cluster_name      = "db-postgresql-ams3-toot-community"
  db_cluster_version   = "14"
  db_node_count        = "1"
  db_cluster_size      = "db-s-2vcpu-4gb"
  connection_pool_name = "mastodon-pool"
  connection_pool_size = 97

  # Postgresql replica
  db_cluster_replica_name  = "db-ro-postgresql-ams3-toot-community"
  db_cluster_replica_size  = "db-s-2vcpu-4gb"
  db_cluster_replica_count = 2

  # Postgresql database
  db_username = "mastodon"
  db_name     = "mastodon"

  # Redis
  redis_cluster_name    = "db-redis-ams3-toot-community"
  redis_cluster_version = "7"
  redis_node_count      = "1"
  redis_cluster_size    = "db-s-2vcpu-4gb"

  # Networking
  vpc_name = "ams3-vpc-toot-community-01"

  # Kubernetes
  kubernetes_cluster_name = "k8s-toot-community-1"
}
