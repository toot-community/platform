resource "digitalocean_droplet" "dbs" {
  backups       = true
  image         = var.droplet_image
  droplet_agent = true
  ipv6          = false
  monitoring    = true
  name          = var.droplet_name
  region        = var.region
  resize_disk   = true
  size          = var.droplet_size
  #ssh_keys           = "24636884"
  vpc_uuid = data.digitalocean_vpc.this.id
}
