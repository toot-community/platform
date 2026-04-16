output "policy_name" {
  description = "Name of the created Vault policy."
  value       = vault_policy.this.name
}

output "role_name" {
  description = "Name of the created Kubernetes auth role."
  value       = vault_kubernetes_auth_backend_role.this.role_name
}
