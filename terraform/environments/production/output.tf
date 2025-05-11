output "talosconfig" {
  value     = module.tc_prod.talosconfig
  sensitive = true
}

output "kubeconfig" {
  value     = module.tc_prod.kubeconfig
  sensitive = true
}
