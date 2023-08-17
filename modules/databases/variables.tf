variable "droplet_image" {
  description = "The image to use for the droplet"
  type        = string
  default     = "debian-12-x64"
}

variable "droplet_name" {
  description = "The name of the droplet"
  type        = string
  default     = "dbs-toot-community-1"
}

variable "region" {
  description = "The region to deploy the droplet"
  type        = string
  default     = "ams3"
}

variable "droplet_size" {
  description = "The size of the droplet"
  type        = string
  default     = "s-8vcpu-16gb-amd"
}

variable "firewall_name" {
  description = "The name of the firewall"
  type        = string
  default     = "dbs-toot-community-1"
}

variable "vpc_name" {
  description = "The name of the VPC"
  type        = string
  default     = "ams3-vpc-toot-community-01"
}

variable "kubernetes_cluster_name" {
  description = "The name of the Kubernetes cluster"
  type        = string
  default     = "k8s-toot-community-1"
}
