variable "project_name" {
  type        = string
  description = "Project name"
}

variable "project_description" {
  type        = string
  description = "Project description"
}

variable "project_purpose" {
  type        = string
  description = "Project purpose"
  default     = "Web Application"
}

variable "project_environment" {
  type        = string
  description = "Project environment"
  validation {
    condition     = contains(["Development", "Staging", "Production"], var.project_environment)
    error_message = "Variable project_environment must be one of 'Development', 'Staging', 'Production'"
  }
}
