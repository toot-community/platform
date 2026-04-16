cloudflare_account_id = "0ae89288096e9795bb1a5d327d89aec5"

r2_buckets = {
  longhorn-backups = {
    vault_secret = {
      path             = "longhorn/longhorn-backups-credentials"
      access_key_field = "AWS_ACCESS_KEY_ID"
      secret_key_field = "AWS_SECRET_ACCESS_KEY"
      extra_fields = {
        AWS_ENDPOINTS = "https://0ae89288096e9795bb1a5d327d89aec5.r2.cloudflarestorage.com"
      }
    }
  }
  microblog-network-assets = {
    vault_secret = {
      path             = "microblog-network/s3-credentials"
      access_key_field = "AWS_ACCESS_KEY_ID"
      secret_key_field = "AWS_SECRET_ACCESS_KEY"
    }
  }
  microblog-network-cnpg-storage = {
    vault_secret = {
      path             = "microblog-network/database-s3-credentials"
      access_key_field = "ACCESS_KEY_ID"
      secret_key_field = "ACCESS_SECRET_KEY"
    }
  }
  toot-community-assets = {
    vault_secret = {
      path             = "toot-community/s3-credentials"
      access_key_field = "AWS_ACCESS_KEY_ID"
      secret_key_field = "AWS_SECRET_ACCESS_KEY"
    }
  }
  toot-community-cnpg-storage = {
    vault_secret = {
      path             = "toot-community/database-s3-credentials"
      access_key_field = "ACCESS_KEY_ID"
      secret_key_field = "ACCESS_SECRET_KEY"
    }
  }
  toot-community-vault-raft-backups = {
    vault_secret = {
      path             = "vault/backup/r2"
      access_key_field = "AWS_ACCESS_KEY_ID"
      secret_key_field = "AWS_SECRET_ACCESS_KEY"
    }
  }
}

# --- Cluster ---
cluster_name    = "tootcommunity-prod"
resource_prefix = "tc-prod-"

# --- Talos ---
talos_version            = "v1.11.3"
kubernetes_version       = "v1.35.0"
talos_schematic_id       = "ce4c980550dd2ab1b17bbf2b08801c7eb59418eafe8f279833297925d67c7515"
talos_metal_schematic_id = "613e1592b2da41ae5e265e8789429f22e121aab91cb4deb6bc3c0b6262961245"

# --- Control Plane ---
controlplane_image = "327836234"
controlplane_nodes = {
  adams   = { location = "fsn1", type = "cax21" }
  jarkov  = { location = "fsn1", type = "cax21" }
  yukagir = { location = "fsn1", type = "cax21" }
}

# --- Vault App Identities ---
vault_apps = {
  argocd            = { namespace = "argocd", audience = "vault" }
  cloudflared       = { namespace = "cloudflare", audience = "vault" }
  dex               = { namespace = "dex", audience = "vault" }
  longhorn          = { namespace = "longhorn-system", audience = "vault" }
  microblog-network = { namespace = "microblog-network", audience = "vault" }
  n8n               = { namespace = "n8n", audience = "vault" }
  robusta           = { namespace = "robusta", audience = "vault" }
  talos-ccm         = { namespace = "kube-system", audience = "vault" }
  teleport          = { namespace = "teleport", audience = "vault" }
  toot-community    = { namespace = "toot-community", audience = "vault" }
  victoriametrics   = { namespace = "victoriametrics", audience = "vault" }
}

# --- Bare-Metal Workers ---
metal_nodes = {
  yuka = {
    public_ipv4_address = "136.243.1.98/26"
    public_ipv4_gateway = "136.243.1.65"
    public_ipv6_address = "2a01:4f8:211:1adb::2/64"
    public_ipv6_gateway = "fe80::1"
    install_disk        = "/dev/nvme0n1"
  }
  lyuba = {
    public_ipv4_address = "148.251.81.14/27"
    public_ipv4_gateway = "148.251.81.1"
    public_ipv6_address = "2a01:4f8:202:510c::2/64"
    public_ipv6_gateway = "fe80::1"
    install_disk        = "/dev/nvme0n1"
  }
  dima = {
    public_ipv4_address = "5.9.13.35/27"
    public_ipv4_gateway = "5.9.13.33"
    public_ipv6_address = "2a01:4f8:160:8333::2/64"
    public_ipv6_gateway = "fe80::1"
    install_disk        = "/dev/nvme0n1"
  }
}
