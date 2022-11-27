variable "doks_cluster_name" {
  type        = string
  description = "Name of the DOKS cluster"
}

variable "doks_cluster_version" {
  type        = string
  description = "Version of the DOKS cluster"
}

variable "region" {
  type        = string
  description = "Name of the region to target"
  default     = "ams3"
}

variable "generic_pool_name" {
  type        = string
  description = "Name of the generic pool"
}

variable "sidekiq_pool_name" {
  type        = string
  description = "Name of the sidekiq pool"
}

variable "generic_pool_size" {
  type        = string
  description = "Size slug for the generic pool"
}

variable "sidekiq_pool_size" {
  type        = string
  description = "Size slug for the sidekiq pool"
}

variable "generic_pool_min_nodes" {
  type        = number
  description = "Minimum number of nodes in the generic pool"
}

variable "generic_pool_max_nodes" {
  type        = string
  description = "Maximum number of nodes in the generic pool"
}

variable "sidekiq_pool_min_nodes" {
  type        = number
  description = "Minimum number of nodes in the sidekiq pool"
}

variable "sidekiq_pool_max_nodes" {
  type        = string
  description = "Maximum number of nodes in the sidekiq pool"
}

variable "vpc_name" {
  type        = string
  description = "Name to give to the VPC"
}


