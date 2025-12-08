# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Infrastructure-as-code for toot.community Kubernetes cluster running on Hetzner Cloud. Uses GitOps principles with ArgoCD managing all deployments.

**Note:** This code requires adaptation for other environments - it's not meant to run as-is.

## Key Commands

### Infrastructure (OpenTofu)
```bash
cd platform
task init          # Initialize OpenTofu
task plan          # Review planned changes
task apply         # Deploy infrastructure
task destroy       # Destroy infrastructure
task get-kubeconfig    # Download cluster access credentials
task get-talosconfig   # Download Talos management credentials
```

### Packer (OS Image Building)
```bash
cd packer
packer build .
```

### Kubernetes Deployments
```bash
# Bootstrap cluster
kustomize build --enable-helm --load-restrictor=LoadRestrictionsNone manifests/cluster-bootstrap | kubectl apply -f -

# Build a specific application manifest
kustomize build --enable-helm manifests/applications/<app-name>
```

### Talos Node Upgrades
```bash
./scripts/upgrade-talos.sh
```

## Architecture

### Directory Structure

- **platform/** - OpenTofu infrastructure code with Taskfile automation
  - `*.tf` files define Hetzner Cloud resources, networking, firewall, storage
  - `talos/patches/` - Custom Talos Linux patches
- **packer/** - Talos OS image builder for Hetzner
- **manifests/** - Kubernetes deployments (GitOps via ArgoCD)
  - `cluster-bootstrap/` - Initial cluster setup (ArgoCD, secrets, CNI)
  - `applications/` - All deployed applications
- **charts/** - Custom Helm charts (Mastodon, Varnish, HAProxy, Redis)
- **scripts/** - Operational scripts (CrowdSec banning, Talos upgrades)

### Deployment Flow

1. Packer builds custom Talos Linux image for Hetzner
2. OpenTofu provisions infrastructure (servers, networking, firewall)
3. Talos bootstraps Kubernetes cluster
4. ArgoCD syncs manifests from this repository

### Key Technologies

- **OS:** Talos Linux (immutable, Kubernetes-optimized)
- **IaC:** OpenTofu ~1.54.0
- **GitOps:** ArgoCD
- **CNI:** Cilium
- **Ingress:** Traefik
- **Secrets:** 1Password Connect (OnePasswordItem CRDs)
- **Database:** CloudNative PG (PostgreSQL)
- **Storage:** Longhorn
- **Observability:** VictoriaMetrics, VictoriaLogs, Robusta

### Primary Application

Mastodon social media server with:
- Custom Helm chart in `charts/mastodon/`
- Varnish caching layer
- CloudNative PG for PostgreSQL
- Redis for caching/sidekiq

## Conventions

- Applications are deployed via Kustomize with Helm chart references
- Secrets use 1Password Connect with `OnePasswordItem` CRDs referencing vault paths
- Helm values are stored in `helm-values.yaml` files alongside `kustomization.yaml`
- Renovate manages dependency updates (auto-merges patch/digest updates)

## Environment Setup

Copy `.envrc.dist` to `.envrc` and configure required environment variables. Uses direnv for automatic loading.
