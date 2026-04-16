resource "hcloud_floating_ip" "api" {
  name          = "${var.resource_prefix}api"
  type          = "ipv4"
  home_location = var.controlplane_nodes[local.bootstrap_node].location
}

resource "hcloud_floating_ip_assignment" "api" {
  floating_ip_id = hcloud_floating_ip.api.id
  server_id      = hcloud_server.controlplane[local.bootstrap_node].id

  lifecycle {
    # Talos VIP controller manages the actual assignment at runtime.
    ignore_changes = [server_id]
  }
}
