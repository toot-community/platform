provider "cloudflare" {
  # Reads CLOUDFLARE_API_TOKEN from environment
}

provider "hcloud" {
  # Reads HCLOUD_TOKEN from environment
}

provider "vault" {
  # Reads VAULT_ADDR and VAULT_TOKEN from environment
}
