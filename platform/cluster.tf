resource "talos_machine_secrets" "this" {
  talos_version = var.talos_version

  lifecycle {
    ignore_changes = [talos_version]
  }
}

data "talos_image_factory_urls" "this" {
  talos_version = var.talos_version
  schematic_id  = var.talos_schematic_id
  platform      = "hcloud"
  architecture  = var.architecture
}

data "talos_machine_configuration" "controlplane" {
  cluster_name       = var.cluster_name
  machine_type       = "controlplane"
  cluster_endpoint   = "https://${hcloud_floating_ip.api.ip_address}:6443"
  machine_secrets    = talos_machine_secrets.this.machine_secrets
  talos_version      = var.talos_version
  kubernetes_version = var.kubernetes_version
}

data "talos_machine_configuration" "worker" {
  cluster_name       = var.cluster_name
  machine_type       = "worker"
  cluster_endpoint   = "https://${hcloud_floating_ip.api.ip_address}:6443"
  machine_secrets    = talos_machine_secrets.this.machine_secrets
  talos_version      = var.talos_version
  kubernetes_version = var.kubernetes_version
}

data "talos_client_configuration" "this" {
  cluster_name         = var.cluster_name
  client_configuration = talos_machine_secrets.this.client_configuration
  nodes                = [for name, srv in hcloud_server.controlplane : srv.ipv4_address]
  endpoints            = [hcloud_floating_ip.api.ip_address]
}

resource "talos_machine_configuration_apply" "controlplane" {
  for_each = var.controlplane_nodes

  client_configuration        = talos_machine_secrets.this.client_configuration
  machine_configuration_input = data.talos_machine_configuration.controlplane.machine_configuration
  node                        = hcloud_server.controlplane[each.key].ipv4_address
  config_patches = [
    file("${path.module}/talos/patches/all-enable-kubespan.yaml"),
    file("${path.module}/talos/patches/all-kubelet-extra-args.yaml"),
    file("${path.module}/talos/patches/all-no-cni.yaml"),
    file("${path.module}/talos/patches/all-set-timeservers.yaml"),
    file("${path.module}/talos/patches/all-set-up-networking.yaml"),
    file("${path.module}/talos/patches/cp-apiserver-audit-policy.yaml"),
    file("${path.module}/talos/patches/cp-enable-talos-service-accounts.yaml"),
    file("${path.module}/talos/patches/cp-hcloud-install-disk.yaml"),
    templatefile("${path.module}/talos/patches/cp-hcloud-vip-address.yaml", {
      ipv4_vip_addr = hcloud_floating_ip.api.ip_address,
      hcloud_token  = var.hcloud_token,
    }),
    templatefile("${path.module}/talos/patches/cp-kubespan-endpoint-filters.yaml", {
      floating_ip = hcloud_floating_ip.api.ip_address,
    }),
    file("${path.module}/talos/patches/cp-monitoring-listen-all-interfaces.yaml"),
    file("${path.module}/talos/patches/cp-node-labels.yaml"),
    templatefile("${path.module}/talos/patches/cp-set-installer-image.yaml", {
      installer_image = data.talos_image_factory_urls.this.urls.installer,
    }),
    yamlencode({
      machine = {
        network = {
          hostname = "${var.resource_prefix}cp-${each.key}"
        }
      }
    }),
  ]
}

resource "talos_machine_configuration_apply" "metal_worker" {
  for_each = var.metal_nodes

  client_configuration        = talos_machine_secrets.this.client_configuration
  machine_configuration_input = data.talos_machine_configuration.worker.machine_configuration
  node                        = regex("^([^/]+)", each.value.public_ipv4_address)[0]
  config_patches = [
    file("${path.module}/talos/patches/all-enable-kubespan.yaml"),
    file("${path.module}/talos/patches/all-kubelet-extra-args.yaml"),
    file("${path.module}/talos/patches/all-no-cni.yaml"),
    file("${path.module}/talos/patches/all-set-timeservers.yaml"),
    file("${path.module}/talos/patches/all-set-up-networking.yaml"),
    file("${path.module}/talos/patches/worker-elasticsearch.yaml"),
    file("${path.module}/talos/patches/worker-longhorn-volume.yaml"),
    templatefile("${path.module}/talos/patches/worker-metal-install-configuration.yaml", {
      install_disk    = each.value.install_disk,
      installer_image = "factory.talos.dev/metal-installer/${var.talos_metal_schematic_id}:${var.talos_version}",
    }),
    yamlencode({
      machine = {
        network = {
          hostname = "${var.resource_prefix}wk-${each.key}"
          interfaces = [{
            deviceSelector = { busPath = "0*" }
            addresses = [
              each.value.public_ipv4_address,
              each.value.public_ipv6_address,
            ]
            dhcp = false
            routes = [
              { network = "0.0.0.0/0", gateway = each.value.public_ipv4_gateway },
              { network = "::/0", gateway = each.value.public_ipv6_gateway },
            ]
          }]
        }
      }
    }),
  ]
}

resource "talos_machine_bootstrap" "this" {
  client_configuration = talos_machine_secrets.this.client_configuration
  node                 = hcloud_server.controlplane[local.bootstrap_node].ipv4_address

  depends_on = [talos_machine_configuration_apply.controlplane]
}

resource "talos_cluster_kubeconfig" "this" {
  client_configuration = talos_machine_secrets.this.client_configuration
  node                 = hcloud_server.controlplane[local.bootstrap_node].ipv4_address

  depends_on = [talos_machine_bootstrap.this]
}

