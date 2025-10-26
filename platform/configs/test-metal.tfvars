cluster_name    = "tootcommunity-prod"
resource_prefix = "tc-prod-"
architecture    = "arm64"
environment     = "test-metal"

talos_version      = "v1.11.0"
kubernetes_version = "v1.34.0"

vpc_name         = "cluster-network"
vpc_cidr         = "10.0.0.0/16"
vpc_subnet_name  = "cloud-servers"
vpc_subnet_cidr  = "10.0.1.0/24"
vpc_network_zone = "eu-central"

vswitch_id                  = 51860
vswitch_subnet_cidr         = "10.0.2.0/24"
vswitch_subnet_network_zone = "eu-central"

controlplane_image = "327836234"
controlplane_nodes = [
  { name = "cp-1", ip = "10.0.1.3", location = "fsn1", type = "cax21", },
  { name = "cp-2", ip = "10.0.1.4", location = "fsn1", type = "cax21", },
  { name = "cp-3", ip = "10.0.1.5", location = "fsn1", type = "cax21", },
]

mastodon_s3_buckets = [
  { name = "toot-community-assets" },
  { name = "microblog-network-assets" }
]

generic_s3_buckets = [
  { name = "toot-community-cnpg-storage" },
  { name = "microblog-network-cnpg-storage" }
]
