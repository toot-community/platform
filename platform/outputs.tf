output "controlplane_ips" {
  description = "Map of control plane node names to their public IPv4 addresses."
  value       = { for name, srv in hcloud_server.controlplane : name => srv.ipv4_address }
}

output "floating_ip" {
  description = "The floating IP address used as the Kubernetes API endpoint."
  value       = hcloud_floating_ip.api.ip_address
}

output "kubeconfig" {
  description = "Kubeconfig for the Kubernetes cluster."
  value       = talos_cluster_kubeconfig.this.kubeconfig_raw
  sensitive   = true
}

output "talosconfig" {
  description = "Talos client configuration for talosctl."
  value       = data.talos_client_configuration.this.talos_config
  sensitive   = true
}
