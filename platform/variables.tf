variable "environment" {
  description = "Environment for which the resources are being created"
  type        = string
  default     = "production"
}

variable "state_bucket_name" {
  description = "Name of the S3 bucket used for storing Terraform state files."
  type        = string
  default     = "tc-tfstate"
}

variable "hcloud_token" {
  description = "Hetzner Cloud API token used for authentication."
  sensitive   = true
}

variable "cluster_name" {
  description = "Name of the Kubernetes cluster to create."
  type        = string
  default     = "managed-cluster"
}

variable "vpc_name" {
  description = "Name of the VPC (Virtual Private Cloud) to create for the cluster."
  type        = string
  default     = "talos-cluster-network"
}

variable "vpc_subnet_name" {
  description = "Name of the VPC subnet to associate with the cluster network."
  type        = string
  default     = "talos-cluster-network-subnet"
}

variable "vpc_network_zone" {
  description = "Network zone for the VPC (e.g., 'eu-central')."
  type        = string
  default     = "eu-central"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC address space."
  type        = string
  default     = "10.0.0.0/8"
}

variable "vpc_subnet_cidr" {
  description = "CIDR block for the VPC subnet. Should match or be a subset of vpc_cidr."
  type        = string
  default     = "10.0.0.0/8"
}

variable "controlplane_image" {
  description = "Image (OS) used for Kubernetes control plane nodes."
  type        = string
  default     = "debian-11"
}

variable "worker_image" {
  description = "Image (OS) used for Kubernetes worker nodes."
  type        = string
  default     = "debian-11"
}

variable "controlplane_nodes" {
  description = "List of control plane nodes with fixed names, private IPs, locations, and types."
  type = list(object({
    name     = string
    ip       = string
    location = string
    type     = string
  }))
  default = [
    { name = "cp-1", ip = "10.0.0.3", location = "nbg1", type = "cax11" },
    { name = "cp-2", ip = "10.0.0.4", location = "hel1", type = "cax11" },
    { name = "cp-3", ip = "10.0.0.5", location = "fsn1", type = "cax11" },
  ]
}

variable "worker_nodes" {
  description = "List of worker nodes with fixed names, private IPs, locations, and types."
  type = list(object({
    name     = string
    ip       = string
    type     = string
    location = string
  }))
  default = [
    { name = "worker-1", ip = "10.0.0.6", location = "nbg1", type = "cax21" },
    { name = "worker-2", ip = "10.0.0.7", location = "hel1", type = "cax21" },
    { name = "worker-3", ip = "10.0.0.8", location = "fsn1", type = "cax21" },
  ]
}

variable "whitelist_admins" {
  description = "List of IP ranges allowed to access the Kubernetes API server (firewall whitelisting)."
  type        = list(string)
  default     = ["86.93.122.193/32"]
}

variable "talos_version" {
  description = "Version of Talos Linux to deploy on nodes."
  type        = string
  default     = "v1.10.4"
}

variable "talos_schematic_id" {
  description = "Schematic ID used to provision Talos images in Hetzner Cloud."
  type        = string
  default     = "ce4c980550dd2ab1b17bbf2b08801c7eb59418eafe8f279833297925d67c7515"
}

variable "talos_platform" {
  description = "Platform identifier used by Talos (e.g., 'hcloud' for Hetzner Cloud)."
  type        = string
  default     = "hcloud"
}

variable "kubernetes_version" {
  description = "Target Kubernetes version for the cluster."
  type        = string
  default     = "v1.33.2"
}

variable "resource_prefix" {
  description = "Optional prefix for naming all resources to avoid collisions."
  type        = string
  default     = ""
}

variable "architecture" {
  description = "CPU architecture for nodes (e.g., 'amd64' or 'arm64')."
  type        = string
  default     = "arm64"
}

variable "mastodon_s3_buckets" {
  description = "List of S3 buckets for Mastodon"
  type = list(object({
    name = string,
  }))
  default = []
}

variable "generic_s3_buckets" {
  description = "List of S3 buckets for generic purposes"
  type = list(object({
    name = string,
  }))
  default = []
}

variable "upcloud_object_storage_name" {
  description = "Name of the UpCloud Managed Object Storage service"
  type        = string
  default     = "mastodon"
}

variable "upcloud_object_storage_status" {
  description = "Status of the UpCloud Managed Object Storage service"
  type        = string
  default     = "started"
}

variable "upcloud_object_storage_region" {
  description = "Region of the UpCloud Managed Object Storage service"
  type        = string
  default     = "europe-2"
}

variable "upcloud_object_storage_network_family" {
  description = "Network family for the UpCloud Managed Object Storage service"
  type        = string
  default     = "IPv4"
}

variable "upcloud_object_storage_network_name" {
  description = "Network name for the UpCloud Managed Object Storage service"
  type        = string
  default     = "public-network"
}

variable "upcloud_object_storage_network_type" {
  description = "Network type for the UpCloud Managed Object Storage service"
  type        = string
  default     = "public"
}

variable "upcloud_object_storage_management_user_policy_name" {
  description = "Name of the policy to attach to the UpCloud Managed Object Storage management user"
  type        = string
  default     = "ECSS3FullAccess"
}

variable "upcloud_object_storage_management_user_name" {
  description = "Name of the UpCloud Managed Object Storage management user"
  type        = string
  default     = "terraform"
}
