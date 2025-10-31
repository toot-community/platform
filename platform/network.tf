resource "hcloud_network" "this" {
  name                     = "${var.resource_prefix}${var.vpc_name}"
  ip_range                 = var.vpc_cidr
  expose_routes_to_vswitch = true
}

resource "hcloud_network_subnet" "this" {
  type         = "cloud"
  network_id   = hcloud_network.this.id
  network_zone = var.vpc_network_zone
  ip_range     = var.vpc_subnet_cidr
}

resource "hcloud_network_subnet" "vswitch" {
  type         = "vswitch"
  network_id   = hcloud_network.this.id
  network_zone = var.vswitch_subnet_network_zone
  ip_range     = var.vswitch_subnet_cidr
  vswitch_id   = var.vswitch_id
}

resource "hcloud_floating_ip" "api" {
  name          = "${var.resource_prefix}api"
  home_location = var.controlplane_nodes[0].location
  type          = "ipv4"
}

resource "hcloud_floating_ip_assignment" "api" {
  floating_ip_id = hcloud_floating_ip.api.id
  server_id      = hcloud_server.controlplane[var.controlplane_nodes[0].name].id

  lifecycle {
    ignore_changes = [
      server_id,
    ]
  }
}
