module "kubernetes" {
  source = "../../../modules/kubernetes"

  # Cluster
  doks_cluster_name    = "k8s-toot-community-1"
  doks_cluster_version = "1.28.2-do.0"
  region               = "ams3"
  high_availability    = true

  # Node pool - generic
  generic_pool_name      = "pool-toot-1"
  generic_pool_size      = "s-8vcpu-16gb-amd"
  generic_pool_min_nodes = 3
  generic_pool_max_nodes = 10

  # Networking
  vpc_name = "ams3-vpc-toot-community-01"
}
