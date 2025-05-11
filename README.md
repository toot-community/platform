# toot.community Kubernetes Cluster

## Create the template

```
cd packer
packer build .
# note the image ID, update it in terraform/environments/production
```

## Create infrastructure

```
cd terraform/environments/production
terraform apply
```

## Bootstrap

```
cd terraform/environments/production
terraform output -raw kubeconfig > ../../../kubeconfig.yaml
cd ../../../
kubectl create secret generic -n kube-system hcloud --from-literal=token=${HCLOUD_TOKEN} --from-literal=network=tc-prod-cluster-network
kustomize build --enable-helm --load-restrictor=LoadRestrictionsNone manifests/cluster-bootstrap | kubectl apply -f -
```