# toot.community Kubernetes Cluster

> [!NOTE]  
> The code included in this repository is not meant to be run as-is. It's merely a collection of infrastructure code and Kubernetes manifests that are used to deploy the toot.community Kubernetes cluster. You will need to adapt the code to your own needs and environment.

## Overview

This repository contains the complete infrastructure-as-code setup for deploying a production Kubernetes cluster on Hetzner Cloud. The project uses:

- **OpenTofu/Terraform** - Infrastructure provisioning and management
- **Talos Linux** - Kubernetes-optimized operating system
- **Packer** - Custom OS image building
- **ArgoCD** - GitOps continuous deployment
- **1Password Connect** - Secrets management
- **Helm Charts** - Application packaging (Mastodon, Varnish)
- **Task** - Build automation via [platform/Taskfile.yml](platform/Taskfile.yml)

The infrastructure follows GitOps principles with ArgoCD managing application deployments from the [manifests/](manifests/) directory.

## Project Structure

- [`platform/`](platform/) - OpenTofu infrastructure code for Hetzner Cloud resources
- [`packer/`](packer/) - Talos Linux image building configuration
- [`manifests/`](manifests/) - Kubernetes applications and cluster bootstrap configurations
- [`charts/`](charts/) - Custom Helm charts for Mastodon and Varnish
- [`platform/configs/`](platform/configs/) - Environment-specific configuration files

## Create the template

Build a custom Talos Linux image for Hetzner Cloud using Packer:

```bash
cd packer
packer build .
```

> Note the image ID from the output and update it in `configs/production.tfvars`

## Create infrastructure

Install [OpenTofu](https://opentofu.org/docs/intro/install/) first, then provision the Hetzner Cloud infrastructure:

```bash
cd platform
task plan    # Review planned changes
task apply   # Deploy infrastructure
```

This creates the Kubernetes cluster, networking, storage, and security groups as defined in the OpenTofu configuration files.

## Bootstrap

After infrastructure deployment, bootstrap the cluster with essential services:

```bash
cd platform
task get-kubeconfig   # Download cluster access credentials
task get-talosconfig  # Download Talos management credentials
cd ../

# Setup 1Password Connect for secrets management
kubectl create namespace op-connect
kubectl create --namespace op-connect secret generic op-credentials --from-literal=1password-credentials.json="$(op read 'op://toot.community/toot.community Production on Hetzner Credentials File/1password-credentials.json' | base64 -w 0)"
kubectl create --namespace op-connect secret generic onepassword-token --from-literal=token="$(op read 'op://toot.community/put37jzwsy6wtsfydfdwvpdaxm/credential')"

# Setup Hetzner Cloud integration
kubectl create --namespace kube-system secret generic hcloud \
  --from-literal=network="$(op read 'op://toot.community/6r6v2bqh6dhuunbn6nri4bw3sa/network')" \
  --from-literal=token="$(op read 'op://toot.community/6r6v2bqh6dhuunbn6nri4bw3sa/token')" \
  --from-literal=robot-user="$(op read 'op://toot.community/6r6v2bqh6dhuunbn6nri4bw3sa/robot-user')" \
  --from-literal=robot-password="$(op read 'op://toot.community/6r6v2bqh6dhuunbn6nri4bw3sa/robot-password')"

# Deploy core cluster services via ArgoCD
kustomize build --enable-helm --load-restrictor=LoadRestrictionsNone manifests/cluster-bootstrap | kubectl apply -f -
# Run the command again after ArgoCD and 1Password CRDs are created
```

This bootstrap process installs:
- 1Password Connect for secure secrets management
- ArgoCD for GitOps deployments
- Core networking (Cilium)
- Certificate management (cert-manager)
- Other essential cluster services defined in the manifests