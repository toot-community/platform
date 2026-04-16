terraform {
  required_version = ">= 1.10.0"

  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = ">= 5.13"
    }

    vault = {
      source  = "hashicorp/vault"
      version = ">= 4.7"
    }
  }
}
