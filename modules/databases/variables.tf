# Postgresql
variable "db_cluster_name" {
  type        = string
  description = "Name of the DB cluster"
}

variable "db_cluster_version" {
  type        = string
  description = "Engine version used by the DB cluster (ex. 14 for PostgreSQL 14)"
}

variable "db_node_count" {
  type        = string
  description = "Number of nodes in the DB cluster"
}

variable "db_cluster_size" {
  type        = string
  description = "Sizing of the DB cluster"
}

variable "db_username" {
  type        = string
  description = "Name of the user to create on the DB cluster"
}

variable "db_name" {
  type        = string
  description = "Naem of the database to create on the DB cluster"
}

variable "connection_pool_name" {
  type        = string
  description = "Name of the connection pool on the DB cluster"
}

variable "connection_pool_size" {
  type        = string
  description = "Size of the connection pool on the DB cluster"
}

# Redis
variable "redis_cluster_name" {
  type        = string
  description = "Name of the Redis cluster"
}

variable "redis_cluster_version" {
  type        = string
  description = "Engine version used by the Redis cluster"
}

variable "redis_node_count" {
  type        = string
  description = "Number of nodes in the Redis cluster"
}

variable "redis_cluster_size" {
  type        = string
  description = "Sizing of the DB cluster"
}

variable "region" {
  type        = string
  description = "Name of the region to target"
  default     = "ams3"
}

variable "vpc_name" {
  type        = string
  description = "Name of the VPC to put the resources in"
}

variable "kubernetes_cluster_name" {
  type        = string
  description = "Name of the Kubernetes cluster to trust incoming connections from"
}
