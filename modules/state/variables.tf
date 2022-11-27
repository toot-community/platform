variable "state_name" {
  type        = string
  description = "Name of the Space to store the Statefile in"
}

variable "region" {
  type        = string
  description = "Name of the region to target"
  default     = "ams3"
}

# variable "state_allowed_ips" {
#   type        = string
#   description = "IP addresses that are allowed to accses the state bucket"
# }
