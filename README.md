# toot.community Kubernetes Cluster

> [!NOTE]  
> The code included in this repository is not meant to be run as-is. It's merely a collection of Terraform code and Kubernetes manifests that are used to deploy the toot.community Kubernetes cluster. You will need to adapt the code to your own needs and environment.

## Create the template

```
cd packer
packer build .
```

> Note the image ID, update it in configs/production.tfvars

## Create infrastructure

Install [OpenTofu](https://opentofu.org/docs/intro/install/) first.

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
kubectl create namespace op-connect
kubectl create --namespace op-connect secret generic op-credentials --from-literal=1password-credentials.json="$(op read 'op://toot.community/toot.community Production on Hetzner Credentials File/1password-credentials.json' | base64 -w 0)"
kubectl create --namespace op-connect secret generic onepassword-token --from-literal=token="$(op read 'op://toot.community/put37jzwsy6wtsfydfdwvpdaxm/credential')"
kubectl create --namespace kube-system secret generic hcloud --from-literal=network="$(op read 'op://toot.community/fcd7bcotmu6iuxk44nvbs6ocpq/network')" --from-literal=token="$(op read 'op://toot.community/fcd7bcotmu6iuxk44nvbs6ocpq/token')"
kustomize build --enable-helm --load-restrictor=LoadRestrictionsNone manifests/cluster-bootstrap | kubectl apply -f -
# (run again after this command created the argo/1p CRDs)
```