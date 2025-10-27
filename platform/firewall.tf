
resource "hcloud_firewall" "controlplane" {
  name = "${var.resource_prefix}controlplane"

  rule {
    direction   = "in"
    protocol    = "icmp"
    source_ips  = concat(var.whitelist_admins, [var.vpc_cidr])
    description = "Allow ICMP from admins and VPC"
  }
  rule {
    direction   = "in"
    protocol    = "udp"
    port        = "any"
    source_ips  = [var.vpc_cidr]
    description = "Allow UDP from VPC"
  }
  rule {
    direction   = "in"
    protocol    = "tcp"
    port        = "any"
    source_ips  = [var.vpc_cidr]
    description = "Allow TCP from VPC"
  }

  rule {
    direction = "in"
    protocol  = "tcp"
    port      = "50000"
    source_ips = concat(var.whitelist_admins, [var.vpc_cidr],
      [for n in var.metal_nodes : regex("^([^/]+)", n.public_ipv4_address)[0]],
    [for name, srv in hcloud_server.controlplane : srv.ipv4_address])
    description = "Allow TCP 50000 (Talos APId) from admins and VPC"
  }
  rule {
    direction = "in"
    protocol  = "tcp"
    port      = "50001"
    source_ips = concat([var.vpc_cidr],
      [for n in var.metal_nodes : regex("^([^/]+)", n.public_ipv4_address)[0]],
    [for name, srv in hcloud_server.controlplane : srv.ipv4_address])
    description = "Allow TCP 50001 (Talos Trustd) from VPC"
  }

  rule {
    direction = "in"
    protocol  = "tcp"
    port      = "6443"
    source_ips = concat(var.whitelist_admins, [var.vpc_cidr],
      [for n in var.metal_nodes : regex("^([^/]+)", n.public_ipv4_address)[0]],
    [for name, srv in hcloud_server.controlplane : srv.ipv4_address])
    description = "Allow TCP 6443 (Kubernetes API) from admins and VPC"
  }

  rule {
    direction = "in"
    protocol  = "tcp"
    port      = "6443"
    source_ips = concat(
      var.whitelist_admins,
      [var.vpc_cidr],
      [for n in var.metal_nodes : regex("^([^/]+)", n.public_ipv4_address)[0]],
      [for name, srv in hcloud_server.controlplane : srv.ipv4_address]
    )
    description = "Allow TCP 6443 (Kubernetes API) from admins, VPC, and nodes"
  }
}

# resource "hcloud_firewall_attachment" "controlplane" {
#   firewall_id = hcloud_firewall.controlplane.id
#   server_ids  = [for s in hcloud_server.controlplane : s.id]
# }

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
