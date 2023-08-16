resource "digitalocean_droplet" "dbs" {
  backups           = true
  image             = var.droplet_image
  ipv6              = false
  monitoring        = true
  name              = var.droplet_name
  region            = var.region
  graceful_shutdown = true
  resize_disk       = true
  size              = var.droplet_size
  vpc_uuid          = data.digitalocean_vpc.this.id
}
