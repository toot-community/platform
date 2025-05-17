cluster_name    = "tootcommunity-prod"
resource_prefix = "tc-prod-"
architecture    = "arm64"

talos_version      = "v1.10.1"
kubernetes_version = "v1.33.0"

vpc_name         = "cluster-network"
vpc_cidr         = "10.0.0.0/16"
vpc_subnet_name  = "cloud-servers"
vpc_subnet_cidr  = "10.0.1.0/24"
vpc_network_zone = "eu-central"

controlplane_image = "236768893"
controlplane_nodes = [
  { name = "cp-1", ip = "10.0.1.3", location = "fsn1", type = "cax11", },
  { name = "cp-2", ip = "10.0.1.4", location = "fsn1", type = "cax11", },
  { name = "cp-3", ip = "10.0.1.5", location = "fsn1", type = "cax11", },
]

worker_image = "236768893"
worker_nodes = [
  { name = "worker-1", ip = "10.0.1.6", location = "fsn1", type = "cax31", },
  { name = "worker-2", ip = "10.0.1.7", location = "fsn1", type = "cax31", },
  { name = "worker-3", ip = "10.0.1.8", location = "fsn1", type = "cax31", },
]

whitelist_admins = [
  "86.93.122.193/32",
  "86.86.243.190/32",
]

s3_buckets = [
  { name = "microblog-network-assets", acl = "public-read" }
]
