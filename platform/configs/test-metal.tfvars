cluster_name    = "tootcommunity-prod"
resource_prefix = "tc-prod-"
architecture    = "arm64"
environment     = "test-metal"

talos_version      = "v1.11.3"
kubernetes_version = "v1.34.0"

vpc_name         = "cluster-network"
vpc_cidr         = "10.0.0.0/16"
vpc_subnet_name  = "cloud-servers"
vpc_subnet_cidr  = "10.0.1.0/24"
vpc_network_zone = "eu-central"

talos_metal_schematic_id = "613e1592b2da41ae5e265e8789429f22e121aab91cb4deb6bc3c0b6262961245"

vswitch_id                  = 72535
vswitch_subnet_cidr         = "10.0.2.0/24"
vswitch_subnet_network_zone = "eu-central"

controlplane_image = "327836234"
controlplane_nodes = [
  { name = "adams", ip = "10.0.1.3", location = "fsn1", type = "cax21", },
  { name = "jarkov", ip = "10.0.1.4", location = "fsn1", type = "cax21", },
  { name = "yukagir", ip = "10.0.1.5", location = "fsn1", type = "cax21", },
]

metal_nodes = [
  {
    name                = "yuka",
    private_ip          = "10.0.2.2",
    private_gateway     = "10.0.2.1",
    public_ipv4_address = "136.243.1.98/26"
    public_ipv4_gateway = "136.243.1.65"
    public_ipv6_address = "2a01:4f8:211:1adb::2/64"
    public_ipv6_gateway = "fe80::1"
    install_disk        = "/dev/nvme0n1"
  },
  {
    name                = "lyuba",
    private_ip          = "10.0.2.3",
    private_gateway     = "10.0.2.1",
    public_ipv4_address = "148.251.81.14/27"
    public_ipv4_gateway = "148.251.81.1"
    public_ipv6_address = "2a01:4f8:202:510c::2/64"
    public_ipv6_gateway = "fe80::1"
    install_disk        = "/dev/nvme0n1"
  },
  {
    name                = "dima",
    private_ip          = "10.0.2.4",
    private_gateway     = "10.0.2.1",
    public_ipv4_address = "5.9.13.35/27"
    public_ipv4_gateway = "5.9.13.33"
    public_ipv6_address = "2a01:4f8:160:8333::2/64"
    public_ipv6_gateway = "fe80::1"
    install_disk        = "/dev/nvme0n1"
  },
]

mastodon_s3_buckets = [
  { name = "toot-community-assets" },
  { name = "microblog-network-assets" }
]

generic_s3_buckets = [
  { name = "toot-community-cnpg-storage" },
  { name = "microblog-network-cnpg-storage" }
]
