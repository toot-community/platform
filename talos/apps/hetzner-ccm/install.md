helm repo add hcloud https://charts.hetzner.cloud
helm repo update hcloud
helm install hccm hcloud/hcloud-cloud-controller-manager -n kube-system --values values.yaml

helm upgrade -i hcloud-csi hcloud/hcloud-csi -n kube-system --set controller.replicaCount=2