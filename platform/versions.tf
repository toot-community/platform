terraform {
  required_version = "~> 1.11"

  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 5.13"
    }

    hcloud = {
      source  = "hetznercloud/hcloud"
      version = "~> 1.60"
    }

    talos = {
      source  = "siderolabs/talos"
      version = "~> 0.11"
    }

    vault = {
      source  = "hashicorp/vault"
      version = "~> 5.0"
    }
  }
}
