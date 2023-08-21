resource "digitalocean_firewall" "dbs" {
  droplet_ids = [digitalocean_droplet.dbs.id]
  name        = var.firewall_name # "dbs-toot-community-1"

  inbound_rule {
    port_range            = "5432"
    protocol              = "tcp"
    source_kubernetes_ids = [data.digitalocean_kubernetes_cluster.this.id]
  }
  inbound_rule {
    port_range            = "6379"
    protocol              = "tcp"
    source_kubernetes_ids = [data.digitalocean_kubernetes_cluster.this.id]
  }
  outbound_rule {
    destination_addresses = ["0.0.0.0/0", "::/0"]
    protocol              = "icmp"
  }
  outbound_rule {
    destination_addresses = ["0.0.0.0/0", "::/0"]
    port_range            = "all"
    protocol              = "tcp"
  }
  outbound_rule {
    destination_addresses = ["0.0.0.0/0", "::/0"]
    port_range            = "all"
    protocol              = "udp"
  }
}
