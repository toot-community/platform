# toot.community Infrastructure

This repository contains the Infrastructure as Code (IaC) and Kubernetes manifests that power toot.community, a Mastodon instance running on Kubernetes. The infrastructure is designed for high availability, scalability, and operational excellence.

## Overview

The toot.community platform consists of:
- **Infrastructure Layer**: Managed with OpenTofu (Terraform) on Hetzner Cloud
- **Kubernetes Layer**: Running Talos Linux with a GitOps deployment model
- **Application Layer**: Mastodon and supporting services deployed via ArgoCD

### Architecture Highlights

- **High Availability**: 3 control plane nodes and 3 worker nodes across different availability zones
- **ARM64 Architecture**: Cost-efficient CAX instances from Hetzner
- **GitOps Workflow**: All changes deployed through ArgoCD with automatic synchronization
- **Cloud-Native Storage**: S3-compatible object storage for media and backups
- **Comprehensive Monitoring**: Full observability stack with metrics, logs, and alerting

## Infrastructure Details

### Image Building

The platform uses custom Talos Linux images built with Packer:

- **Image Factory**: Talos Factory service generates custom images with required system extensions
- **Schematic ID**: `ce4c980550dd2ab1b17bbf2b08801c7eb59418eafe8f279833297925d67c7515`
- **Build Process**: Packer provisions a temporary Hetzner instance and writes the Talos image
- **Output**: Hetzner Cloud snapshot labeled with Talos version
- **Architecture**: ARM64-specific images for CAX instances

### Compute Infrastructure

The platform runs on Hetzner Cloud with the following specifications:

#### Control Plane Nodes
- **Instance Type**: CAX11 (ARM64, 2 vCPU, 4GB RAM)
- **Count**: 3 nodes for etcd quorum
- **Operating System**: Talos Linux
- **Distribution**: Spread across placement groups for fault tolerance

#### Worker Nodes
- **Instance Type**: CAX41 (ARM64, 16 vCPU, 32GB RAM)
- **Count**: 3 nodes for workload distribution
- **Operating System**: Talos Linux
- **Role**: Running application workloads

### Networking Architecture

- **Private Network**: 10.0.0.0/16 with 10.0.1.0/24 subnet
- **Pod Network**: 10.0.16.0/20 managed by Cilium CNI
- **Service Network**: 10.0.8.0/21 for Kubernetes services
- **Load Balancing**: Hetzner Load Balancers with floating IP for API endpoint
- **Ingress**: NGINX Ingress Controller with DaemonSet deployment

### Storage Architecture

#### Object Storage (S3-Compatible)
- **Provider**: Hetzner Object Storage (fsn1 region)
- **Buckets**:
  - `toot-community-assets`: Mastodon media files
  - `toot-community-cnpg-storage`: PostgreSQL backups
  - `toot-community-velero`: Kubernetes backups

#### Block Storage
- **Control Plane**: Local NVMe storage for etcd
- **Worker Nodes**: Local storage for container images and ephemeral data

## Kubernetes Platform

### Core Components

#### Cluster Management
- **Container Runtime**: Containerd with Talos System Extensions
- **CNI**: Cilium with eBPF dataplane
- **Cloud Provider**: Hetzner Cloud Controller Manager
- **Certificate Management**: cert-manager with Let's Encrypt

#### GitOps & Deployment
- **ArgoCD**: Continuous deployment with automatic sync
- **Kustomize**: Configuration management with base/overlay pattern
- **Helm**: Package management for third-party applications

### Application Stack

#### Mastodon Components

The Mastodon deployment consists of:

1. **Web Service**: Rails application serving the web interface
   - 3 replicas with horizontal pod autoscaling
   - Resource limits: 1 CPU, 2Gi memory per pod
   - Health checks and readiness probes configured

2. **Streaming Service**: WebSocket server for real-time updates
   - 3 replicas for high availability
   - Dedicated ingress for WebSocket traffic
   - Session affinity enabled

3. **Sidekiq Workers**: Background job processing
   - Generic workers: 3 replicas with 25 concurrency
   - Scheduler: 1 replica for periodic tasks
   - Separate queues for different job priorities

4. **Caching Layer**: Varnish cache instances
   - App cache: Dynamic content caching
   - Static cache: Asset caching with S3 backend
   - Cache invalidation on content updates

#### Data Layer

1. **PostgreSQL**: Primary database
   - **Operator**: CloudNative-PG for lifecycle management
   - **High Availability**: 3 instances with automatic failover
   - **Connection Pooling**: PgBouncer for connection management
   - **Backups**: Automated daily backups to S3 with point-in-time recovery
   - **Monitoring**: Prometheus metrics and alerts

2. **Redis**: Caching and job queue
   - **Deployment**: Bitnami Redis chart
   - **Architecture**: Master with read replicas
   - **Load Balancing**: HAProxy for connection distribution
   - **Persistence**: RDB snapshots and AOF logging

3. **Elasticsearch**: Full-text search (toot.community only)
   - **Operator**: Elastic Cloud on Kubernetes (ECK)
   - **Resources**: Dedicated node pool allocation
   - **Security**: TLS encryption and authentication

### Observability Stack

#### Metrics
- **VictoriaMetrics**: Time-series database replacing Prometheus
- **VMAgent**: Metric collection from all components
- **Grafana**: Visualization with pre-built dashboards
- **Dashboards**: ArgoCD, NGINX, Redis, PostgreSQL, Kubernetes

#### Logging
- **VictoriaLogs**: Log aggregation and search
- **Log Sources**: Container logs, system logs, application logs
- **Retention**: Configurable retention policies

#### Alerting
- **VMAlert**: Alert rule evaluation
- **Alertmanager**: Alert routing and grouping
- **Robusta**: Automated troubleshooting and remediation
- **Alert Coverage**: Infrastructure, application, and security alerts

### Security & Compliance

#### Authentication & Authorization
- **Dex**: OIDC provider for single sign-on
- **RBAC**: Role-based access control for Kubernetes
- **Network Policies**: Cilium-based microsegmentation

#### Secrets Management
- **1Password Connect**: External secret synchronization
- **Sealed Secrets**: Encrypted secrets in Git

#### Certificate Management
- **cert-manager**: Automatic TLS certificate provisioning
- **Let's Encrypt**: Free SSL certificates
- **Certificate Rotation**: Automatic renewal before expiration

### Backup & Disaster Recovery

#### Velero
- **Schedule**: Daily backups of Kubernetes resources
- **Storage**: S3-compatible backend
- **Retention**: 30-day retention policy
- **Restore Testing**: Periodic restore verification

#### Database Backups
- **Frequency**: Daily full backups, continuous WAL archiving
- **Storage**: Dedicated S3 bucket with encryption
- **Recovery**: Point-in-time recovery capability
- **Testing**: Regular backup verification

## Multi-Instance Support

The infrastructure supports multiple Mastodon instances through Kustomize overlays:

### Base Configuration
Located in `manifests/applications/mastodon/base/`, containing:
- Common Helm values
- Shared database configuration
- Default resource allocations

### Instance Overlays
Each instance has its own overlay in `manifests/applications/mastodon/overlays/`:

#### toot.community (Production)
- Full federation enabled
- Elasticsearch search
- 3 web/streaming replicas
- Premium resource allocations

#### microblog.network (Staging/Testing)
- Limited federation mode
- No search functionality
- Single replica deployment
- Minimal resource usage

## Operational Workflows

### Deployment Process
1. Code changes pushed to GitHub repository
2. ArgoCD detects changes and syncs automatically
3. Kubernetes resources updated in-place
4. Health checks verify successful deployment

### Monitoring & Alerting
- **Metrics Collection**: 15-second scrape interval
- **Alert Evaluation**: 1-minute evaluation cycle
- **Notification Channels**: Configured in Alertmanager
- **On-Call Integration**: Via Robusta platform

### Maintenance Operations
- **Database Maintenance**: Automated vacuum and reindexing
- **Media Cleanup**: Scheduled removal of orphaned files
- **Certificate Renewal**: Automatic via cert-manager
- **Security Updates**: Automated via Renovate

## Infrastructure as Code

### OpenTofu Configuration
The `platform/` directory contains:
- **Server provisioning**: Compute instances and networking
- **Storage configuration**: S3 buckets and policies
- **Firewall rules**: Security group configuration
- **State management**: Remote state in S3

### Talos Machine Configuration
- **Control plane patches**: API server configuration
- **Worker patches**: Kubelet optimization
- **System extensions**: Required kernel modules
- **Network optimization**: Sysctl tuning for performance
