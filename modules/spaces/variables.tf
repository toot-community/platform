variable "spaces_name" {
  type        = string
  description = "Name of the Space"
}

variable "region" {
  type        = string
  description = "Name of the region to target"
  default     = "ams3"
}

variable "cdn_hostname" {
  type        = string
  description = "Hostname for the CDN"
}

variable "cors_hostname" {
  type        = string
  description = "Hostname to trust for CORS"
}
