cluster_name    = "tootcommunity-prod"
resource_prefix = "tc-prod-"
architecture    = "arm64"

talos_version      = "v1.10.4"
kubernetes_version = "v1.33.2"

vpc_name         = "cluster-network"
vpc_cidr         = "10.0.0.0/16"
vpc_subnet_name  = "cloud-servers"
vpc_subnet_cidr  = "10.0.1.0/24"
vpc_network_zone = "eu-central"

controlplane_image = "238071418"
controlplane_nodes = [
  { name = "cp-1", ip = "10.0.1.3", location = "fsn1", type = "cax21", },
  { name = "cp-2", ip = "10.0.1.4", location = "fsn1", type = "cax21", },
  { name = "cp-3", ip = "10.0.1.5", location = "fsn1", type = "cax21", },
]

worker_image = "238071418"
worker_nodes = [
  { name = "worker-1", ip = "10.0.1.6", location = "fsn1", type = "cax41", },
  { name = "worker-2", ip = "10.0.1.7", location = "fsn1", type = "cax41", },
  { name = "worker-3", ip = "10.0.1.8", location = "fsn1", type = "cax41", },
]

mastodon_s3_buckets = [
  { name = "toot-community-assets" },
  { name = "microblog-network-assets" }
]

generic_s3_buckets = [
  { name = "toot-community-cnpg-storage" }
]
