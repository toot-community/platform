output "talosconfig" {
  value     = module.mmh_eu_prod.talosconfig
  sensitive = true
}

output "kubeconfig" {
  value     = module.mmh_eu_prod.kubeconfig
  sensitive = true
}
