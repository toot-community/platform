module "databases" {
  source = "../../../modules/databases"

  droplet_image = "debian-12-x64"
  droplet_name  = "dbs-toot-community-1"
  droplet_size  = "s-8vcpu-16gb-amd"
  region        = "ams3"

  firewall_name = "dbs-toot-community-1"

  # Networking datasource
  vpc_name = "ams3-vpc-toot-community-01"

  # Kubernetes datasource
  kubernetes_cluster_name = "k8s-toot-community-1"
}
