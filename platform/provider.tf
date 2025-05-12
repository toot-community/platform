terraform {
  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = "~> 1.50.1"
    }

    talos = {
      source  = "siderolabs/talos"
      version = "~> 0.8"
    }
  }
}

provider "hcloud" {
  token = var.hcloud_token
}
