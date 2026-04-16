resource "hcloud_placement_group" "controlplane" {
  name = "${var.resource_prefix}controlplane"
  type = "spread"
}

resource "hcloud_server" "controlplane" {
  for_each = var.controlplane_nodes

  name        = "${var.resource_prefix}cp-${each.key}"
  location    = each.value.location
  image       = var.controlplane_image
  server_type = each.value.type

  placement_group_id       = hcloud_placement_group.controlplane.id
  shutdown_before_deletion = true
  delete_protection        = true
  rebuild_protection       = true

  public_net {
    ipv4_enabled = true
    ipv6_enabled = false
  }

  lifecycle {
    prevent_destroy = true
    # Image changes are applied out-of-band by Talos upgrades, not by Terraform.
    ignore_changes = [image]
  }
}
