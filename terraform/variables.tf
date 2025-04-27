variable "hcloud_token" {
  sensitive = true
}

variable "cluster_name" {
  type    = string
  default = "managed-cluster"
}

variable "vpc_name" {
  type    = string
  default = "talos-cluster-network"
}

variable "vpc_subnet_name" {
  type    = string
  default = "talos-cluster-network-subnet"
}

variable "vpc_network_zone" {
  type    = string
  default = "eu-central"
}

variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "vpc_subnet_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "controlplane_image" {
  type    = string
  default = "debian-11"
}

variable "worker_image" {
  type    = string
  default = "debian-11"
}

variable "controlplane_nodes" {
  type = list(object({
    name     = string
    ip       = string
    location = string
    type     = string
  }))

  default = [
    { name = "cp-1", ip = "10.0.0.3", location = "nbg1", type = "cax11", },
    { name = "cp-2", ip = "10.0.0.4", location = "hel1", type = "cax11", },
    { name = "cp-3", ip = "10.0.0.5", location = "fsn1", type = "cax11", },
  ]
}

variable "worker_nodes" {
  type = list(object({
    name     = string
    ip       = string
    type     = string
    location = string
  }))

  default = [
    { name = "worker-1", ip = "10.0.0.6", location = "nbg1", type = "cax21", },
    { name = "worker-2", ip = "10.0.0.7", location = "hel1", type = "cax21", },
    { name = "worker-3", ip = "10.0.0.8", location = "fsn1", type = "cax21", },
  ]
}

variable "whitelist_admins" {
  type    = list(string)
  default = ["86.93.122.193/32"]
}

variable "talos_version" {
  type    = string
  default = "v1.9.5"
}

variable "talos_schematic_id" {
  type    = string
  default = "ce4c980550dd2ab1b17bbf2b08801c7eb59418eafe8f279833297925d67c7515" # Hetzner
}

variable "talos_platform" {
  type    = string
  default = "hcloud"
}

variable "kubernetes_version" {
  type    = string
  default = "v1.29.0"
}

variable "resource_prefix" {
  type    = string
  default = ""
}

variable "architecture" {
  type    = string
  default = "amd64"
}
