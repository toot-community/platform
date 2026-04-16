variable "app_name" {
  description = "Application name. Used to derive the policy name (<app>-readonly) and Kubernetes auth role name."
  type        = string
}

variable "audience" {
  description = "Audience claim for JWT validation on the Kubernetes auth role."
  type        = string
  default     = null
}

variable "auth_backend_path" {
  description = "Path of the Kubernetes auth backend."
  type        = string
}

variable "kv_mount_path" {
  description = "Path of the KV v2 secrets engine mount."
  type        = string
}

variable "namespace" {
  description = "Kubernetes namespace the application runs in."
  type        = string
}

variable "service_account" {
  description = "Kubernetes service account name bound to the auth role."
  type        = string
  default     = "default"
}

variable "token_ttl" {
  description = "TTL in seconds for tokens issued by the Kubernetes auth role."
  type        = number
  default     = 3600
}
