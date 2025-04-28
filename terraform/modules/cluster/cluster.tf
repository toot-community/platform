resource "talos_machine_secrets" "machine_secrets" {
  talos_version = var.talos_version
}

data "talos_image_factory_urls" "this" {
  talos_version = var.talos_version
  schematic_id  = var.talos_schematic_id
  platform      = var.talos_platform
  architecture  = var.architecture
}

data "talos_machine_configuration" "controlplane" {
  cluster_name       = var.cluster_name
  machine_type       = "controlplane"
  cluster_endpoint   = "https://${hcloud_floating_ip.api.ip_address}:6443"
  machine_secrets    = talos_machine_secrets.machine_secrets.machine_secrets
  talos_version      = var.talos_version
  kubernetes_version = var.kubernetes_version
}

data "talos_machine_configuration" "worker" {
  cluster_name       = var.cluster_name
  cluster_endpoint   = "https://${hcloud_floating_ip.api.ip_address}:6443"
  machine_type       = "worker"
  machine_secrets    = talos_machine_secrets.machine_secrets.machine_secrets
  talos_version      = var.talos_version
  kubernetes_version = var.kubernetes_version
}

data "talos_client_configuration" "talosconfig" {
  cluster_name         = var.cluster_name
  client_configuration = talos_machine_secrets.machine_secrets.client_configuration
  nodes = concat(
    [for node in var.controlplane_nodes : node.ip],
    [for node in var.worker_nodes : node.ip]
  )
  endpoints = [hcloud_floating_ip.api.ip_address]
}

resource "talos_machine_configuration_apply" "cp_config_apply" {
  for_each                    = { for i in var.controlplane_nodes : i.name => i }
  client_configuration        = talos_machine_secrets.machine_secrets.client_configuration
  machine_configuration_input = data.talos_machine_configuration.controlplane.machine_configuration
  node                        = hcloud_server.controlplane[each.key].ipv4_address
  config_patches = [
    templatefile("${path.module}/talos/patches/all.yaml", {
      vpc_subnet_cidr : var.vpc_subnet_cidr,
      installer_image : data.talos_image_factory_urls.this.urls.installer
    }),
    templatefile("${path.module}/talos/patches/controlplane.yaml", {
      ipv4_vip_addr : hcloud_floating_ip.api.ip_address,
      hcloud_token : var.hcloud_token,
      vpc_subnet_cidr : var.vpc_subnet_cidr
    })
  ]

  depends_on = [
    hcloud_server.controlplane,
    talos_machine_secrets.machine_secrets,
    data.talos_machine_configuration.controlplane,
    hcloud_floating_ip_assignment.api
  ]
}

resource "talos_machine_configuration_apply" "worker_config_apply" {
  for_each                    = { for i in var.worker_nodes : i.name => i }
  client_configuration        = talos_machine_secrets.machine_secrets.client_configuration
  machine_configuration_input = data.talos_machine_configuration.worker.machine_configuration
  node                        = hcloud_server.worker[each.key].ipv4_address
  config_patches = [
    templatefile("${path.module}/talos/patches/all.yaml", {
      vpc_subnet_cidr : var.vpc_subnet_cidr,
      installer_image : data.talos_image_factory_urls.this.urls.installer
    }),
    templatefile("${path.module}/talos/patches/worker.yaml", {
      vpc_subnet_cidr : var.vpc_subnet_cidr
    })
  ]

  depends_on = [
    hcloud_server.worker,
    talos_machine_secrets.machine_secrets,
    data.talos_machine_configuration.controlplane,
    hcloud_floating_ip_assignment.api
  ]
}

resource "talos_machine_bootstrap" "bootstrap" {
  depends_on           = [hcloud_server.controlplane]
  client_configuration = talos_machine_secrets.machine_secrets.client_configuration
  node                 = hcloud_server.controlplane[var.controlplane_nodes[0].name].ipv4_address
}

# data "talos_cluster_health" "health" {
#   depends_on             = [talos_machine_configuration_apply.cp_config_apply, talos_machine_configuration_apply.worker_config_apply]
#   client_configuration   = data.talos_client_configuration.talosconfig.client_configuration
#   control_plane_nodes    = [for node in var.controlplane_nodes : node.ip]
#   worker_nodes           = [for node in var.worker_nodes : node.ip]
#   endpoints              = [hcloud_floating_ip.api.ip_address]
#   skip_kubernetes_checks = true # no CNI available yet
# }

resource "talos_cluster_kubeconfig" "kubeconfig" {
  depends_on = [
    talos_machine_bootstrap.bootstrap
  ]
  client_configuration = talos_machine_secrets.machine_secrets.client_configuration
  node                 = hcloud_server.controlplane[var.controlplane_nodes[0].name].ipv4_address
}
