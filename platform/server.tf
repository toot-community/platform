resource "hcloud_placement_group" "controlplane" {
  name = "${var.resource_prefix}controlplane"
  type = "spread"
}

resource "hcloud_placement_group" "worker" {
  name = "${var.resource_prefix}worker"
  type = "spread"
}

resource "hcloud_server" "controlplane" {
  for_each = { for i in var.controlplane_nodes : i.name => i }

  name                     = "${var.resource_prefix}${each.key}"
  location                 = each.value.location
  image                    = var.controlplane_image
  server_type              = each.value.type
  firewall_ids             = [hcloud_firewall.controlplane.id]
  shutdown_before_deletion = true
  placement_group_id       = hcloud_placement_group.controlplane.id

  public_net {
    ipv4_enabled = true
    ipv6_enabled = false
  }

  network {
    network_id = hcloud_network.this.id
    ip         = each.value.ip
  }

  depends_on = [hcloud_network_subnet.this]
  lifecycle { ignore_changes = [image] }
}

resource "hcloud_server" "worker" {
  for_each = { for i in var.worker_nodes : i.name => i }

  name                     = "${var.resource_prefix}${each.key}"
  location                 = each.value.location
  image                    = var.worker_image
  server_type              = each.value.type
  firewall_ids             = [hcloud_firewall.worker.id]
  shutdown_before_deletion = true
  placement_group_id       = hcloud_placement_group.worker.id

  public_net {
    ipv4_enabled = true
    ipv6_enabled = false
  }

  network {
    network_id = hcloud_network.this.id
    ip         = each.value.ip
  }

  depends_on = [hcloud_network_subnet.this, hcloud_server.controlplane, hcloud_floating_ip_assignment.api]
  lifecycle { ignore_changes = [image] }
}
