
resource "hcloud_firewall" "controlplane" {
  name = "${var.resource_prefix}controlplane"

  rule {
    direction  = "in"
    protocol   = "icmp"
    source_ips = concat(var.whitelist_admins, [var.vpc_cidr])
  }
  rule {
    direction  = "in"
    protocol   = "udp"
    port       = "any"
    source_ips = [var.vpc_cidr]
  }
  rule {
    direction  = "in"
    protocol   = "tcp"
    port       = "any"
    source_ips = [var.vpc_cidr]
  }

  rule {
    direction  = "in"
    protocol   = "tcp"
    port       = "50000"
    source_ips = concat(var.whitelist_admins, [var.vpc_cidr])
  }
  rule {
    direction  = "in"
    protocol   = "tcp"
    port       = "50001"
    source_ips = [var.vpc_cidr]
  }

  rule {
    direction  = "in"
    protocol   = "tcp"
    port       = "6443"
    source_ips = concat(var.whitelist_admins, [var.vpc_cidr])
  }
}

# resource "hcloud_firewall" "worker" {
#   name = "${var.resource_prefix}worker"

#   rule {
#     direction  = "in"
#     protocol   = "icmp"
#     source_ips = [var.vpc_cidr]
#   }
#   rule {
#     direction  = "in"
#     protocol   = "udp"
#     port       = "any"
#     source_ips = [var.vpc_cidr]
#   }
#   rule {
#     direction  = "in"
#     protocol   = "tcp"
#     port       = "any"
#     source_ips = [var.vpc_cidr]
#   }

#   rule {
#     direction  = "in"
#     protocol   = "tcp"
#     port       = "50000"
#     source_ips = concat(var.whitelist_admins, [var.vpc_cidr])
#   }
#   rule {
#     direction  = "in"
#     protocol   = "tcp"
#     port       = "50001"
#     source_ips = [var.vpc_cidr]
#   }
# }
