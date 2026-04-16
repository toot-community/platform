locals {
  # Explicitly designate the first control plane node for bootstrap operations
  # (floating IP assignment, talos bootstrap, kubeconfig retrieval).
  bootstrap_node = keys(var.controlplane_nodes)[0]
}
