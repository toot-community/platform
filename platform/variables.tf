variable "architecture" {
  description = "CPU architecture for cloud nodes (amd64 or arm64)."
  type        = string
  default     = "arm64"

  validation {
    condition     = contains(["amd64", "arm64"], var.architecture)
    error_message = "Architecture must be amd64 or arm64."
  }
}

variable "cloudflare_account_id" {
  description = "Cloudflare account ID for R2 and other Cloudflare resources."
  type        = string
}

variable "cluster_name" {
  description = "Name of the Kubernetes cluster."
  type        = string
}

variable "controlplane_image" {
  description = "Hetzner Cloud image ID (snapshot) for control plane nodes."
  type        = string
}

variable "controlplane_nodes" {
  description = "Map of control plane nodes keyed by name, with location and server type."
  type = map(object({
    location = string
    type     = string
  }))

  validation {
    condition     = length(var.controlplane_nodes) >= 1 && length(var.controlplane_nodes) % 2 == 1
    error_message = "Control plane must have an odd number of nodes (1, 3, 5, ...)."
  }
}

variable "hcloud_token" {
  description = "Hetzner Cloud API token, used by the Talos VIP controller to manage the floating IP."
  type        = string
  sensitive   = true
}

variable "kubernetes_version" {
  description = "Target Kubernetes version for the cluster."
  type        = string
}

variable "metal_nodes" {
  description = "Map of bare-metal worker nodes keyed by name, with network and disk configuration."
  type = map(object({
    public_ipv4_address = string
    public_ipv4_gateway = string
    public_ipv6_address = string
    public_ipv6_gateway = string
    install_disk        = string
  }))
  default = {}
}

variable "r2_buckets" {
  description = "Map of R2 buckets keyed by name. When vault_secret is set, the bucket's S3 credentials are written to Vault KV v2 at the specified path. Use extra_fields to include additional static key/value pairs in the secret."
  type = map(object({
    vault_secret = optional(object({
      mount            = optional(string, "secret")
      path             = string
      access_key_field = optional(string, "access_key_id")
      secret_key_field = optional(string, "secret_access_key")
      extra_fields     = optional(map(string), {})
    }))
  }))
}

variable "resource_prefix" {
  description = "Prefix for all Hetzner resource names to avoid collisions."
  type        = string
  default     = ""
}

variable "talos_metal_schematic_id" {
  description = "Talos image factory schematic ID for bare-metal worker nodes."
  type        = string
}

variable "talos_schematic_id" {
  description = "Talos image factory schematic ID for Hetzner Cloud nodes."
  type        = string
}

variable "talos_version" {
  description = "Version of Talos Linux deployed on cluster nodes."
  type        = string
}

variable "vault_apps" {
  description = "Map of applications that need a Vault app identity (readonly KV policy + Kubernetes auth role). The key is the app name used for policy and role naming."
  type = map(object({
    namespace       = string
    audience        = optional(string)
    service_account = optional(string, "default")
    token_ttl       = optional(number, 3600)
  }))
}

variable "whitelist_admins" {
  description = "List of admin IP CIDRs allowed to access Talos API and Kubernetes API."
  type        = list(string)
}
