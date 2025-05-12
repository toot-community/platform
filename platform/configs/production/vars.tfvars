cluster_name    = "tootcommunity-prod"
resource_prefix = "tc-prod-"
architecture    = "arm64"

talos_version      = "v1.10.1"
kubernetes_version = "v1.30.0"

vpc_name         = "cluster-network"
vpc_cidr         = "10.0.0.0/8"
vpc_subnet_name  = "cluster-network-subnet"
vpc_subnet_cidr  = "10.0.0.0/8"
vpc_network_zone = "eu-central"

controlplane_image = "236768893"
controlplane_nodes = [
  { name = "cp-fsn1-1", ip = "10.0.0.3", location = "fsn1", type = "cax11", },
  { name = "cp-nbg1-2", ip = "10.0.0.4", location = "nbg1", type = "cax11", },
  { name = "cp-fsn1-3", ip = "10.0.0.5", location = "fsn1", type = "cax11", },
]

worker_image = "236768893"
worker_nodes = [
  { name = "worker-nbg1-1", ip = "10.0.0.6", location = "nbg1", type = "cax11", },
  { name = "worker-nbg1-2", ip = "10.0.0.7", location = "nbg1", type = "cax11", },
  # { name = "worker-fsn1-3", ip = "10.0.0.8", location = "fsn1", type = "cax11", },
  # { name = "worker-fsn1-4", ip = "10.0.0.9", location = "fsn1", type = "cax11", },
]

whitelist_admins = [
  "86.93.122.193/32"
]
