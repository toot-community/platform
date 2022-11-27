variable "vpc_name" {
  type        = string
  description = "Name to give to the VPC"
}

variable "region" {
  type        = string
  description = "Name of the region to target"
  default     = "ams3"
}

variable "vpc_cidr" {
  type        = string
  description = "CIDR/IP range of the VPC"
}
