resource "hcloud_firewall" "controlplane" {
  name = "${var.resource_prefix}controlplane"

  rule {
    direction   = "in"
    protocol    = "tcp"
    port        = "50000"
    source_ips  = var.whitelist_admins
    description = "Allow TCP 50000 (Talos APId) from admins"
  }

  rule {
    direction   = "in"
    protocol    = "udp"
    port        = "51820"
    source_ips  = ["0.0.0.0/0", "::/0"]
    description = "KubeSpan WireGuard"
  }

  # Commented: API traffic flows through Teleport proxy. You do need
  # this rule if you ever bootstrap this cluster from scratch again.
  # rule {
  #   direction   = "in"
  #   protocol    = "tcp"
  #   port        = "6443"
  #   source_ips  = var.whitelist_admins
  #   description = "Allow TCP 6443 (Kubernetes API) from admins"
  # }
}

resource "hcloud_firewall_attachment" "controlplane" {
  firewall_id = hcloud_firewall.controlplane.id
  server_ids  = [for s in hcloud_server.controlplane : s.id]
}
