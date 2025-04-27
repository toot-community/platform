helm upgrade -i --namespace=kube-system -f values.yaml \
  talos-cloud-controller-manager oci://ghcr.io/siderolabs/charts/talos-cloud-controller-manager