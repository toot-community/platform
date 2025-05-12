# toot.community Kubernetes Cluster

## Create the template

```
cd packer
packer build .
```

> Note the image ID, update it in configs/production/vars.tfvars

## Create infrastructure

```
task plan
task apply
```

## Bootstrap

```
cd platform
task get-kubeconfig
task get-talosconfig
cd ../
kustomize build --enable-helm --load-restrictor=LoadRestrictionsNone manifests/cluster-bootstrap | kubectl apply -f -
```