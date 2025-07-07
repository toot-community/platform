# toot.community Infrastructure

This repository contains the Infrastructure as Code (IaC) and Kubernetes manifests that power toot.community, a Mastodon instance running on Kubernetes. The infrastructure is designed for high availability, scalability, and operational excellence.

## Architecture Overview

The toot.community platform is built on three foundational layers:

- **Infrastructure Layer**: ARM64-based compute on Hetzner Cloud, managed with OpenTofu
- **Platform Layer**: Kubernetes running on Talos Linux with GitOps deployment
- **Application Layer**: Mastodon and supporting services orchestrated by ArgoCD

### Key Design Principles

- **High Availability**: Multi-node architecture with no single points of failure
- **Cost Efficiency**: ARM64 instances and intelligent caching strategies
- **Security First**: Zero-trust networking, encrypted storage, and automated certificate management
- **Observable by Default**: Comprehensive metrics, logging, and alerting
- **GitOps Workflow**: All changes tracked in Git and automatically deployed

## Infrastructure Foundation

### Compute Resources

The platform runs on Hetzner Cloud using ARM64 architecture for cost efficiency:

**Control Plane**
- 3× CAX11 instances (2 vCPU, 4GB RAM)
- Distributed across placement groups for fault tolerance
- Running Talos Linux with custom system extensions

**Worker Nodes**
- 3× CAX41 instances (16 vCPU, 32GB RAM)
- Dedicated to application workloads
- Optimized kernel parameters for high-performance networking

### Networking

- **Private Network**: 10.0.0.0/16 (production subnet: 10.0.1.0/24)
- **Pod Network**: 10.0.16.0/20 via Cilium CNI with eBPF
- **Service Network**: 10.0.8.0/21
- **Load Balancing**: Hetzner Load Balancers with floating IP
- **Ingress**: NGINX controller running as DaemonSet

### Storage

**Object Storage (S3-Compatible)**
- Hetzner Object Storage in fsn1 region
- `toot-community-assets`: Mastodon media files
- `toot-community-cnpg-storage`: PostgreSQL backups
- `toot-community-velero`: Kubernetes cluster backups

**Local Storage**
- NVMe for etcd on control plane nodes
- Container images and ephemeral data on workers

## Platform Layer

### Kubernetes Foundation

- **Operating System**: Talos Linux - immutable, API-driven, purpose-built for Kubernetes
- **Container Runtime**: Containerd with system extensions
- **Network Plugin**: Cilium with eBPF dataplane and network policies
- **Cloud Integration**: Hetzner CCM for load balancers and node lifecycle

### GitOps & Automation

- **ArgoCD**: Continuous deployment with automatic synchronization
- **Kustomize**: Configuration management using base/overlay pattern
- **Helm**: Third-party application packaging
- **Renovate**: Automated dependency updates

## Application Architecture

### Mastodon Services

The Mastodon deployment is composed of four main components:

**1. Web Service**
- Rails application serving the UI and API
- 3 replicas with horizontal pod autoscaling
- Resource limits: 1 CPU, 2Gi memory per pod

**2. Streaming Service**
- WebSocket server for real-time updates
- 3 replicas with session affinity
- Dedicated ingress configuration

**3. Background Workers**
- Sidekiq for job processing
- 3 generic workers with 25 concurrent threads
- 1 scheduler for periodic tasks

**4. Caching Layer**
- Dual Varnish deployment (detailed below)

### Data Layer

**PostgreSQL**
- Managed by CloudNative-PG operator
- 3-node cluster with automatic failover
- PgBouncer for connection pooling
- Daily backups with point-in-time recovery

**Redis**
- Bitnami Redis deployment
- Master with read replicas
- HAProxy for load distribution
- Persistent storage with AOF

**Elasticsearch** (toot.community only)
- Elastic Cloud on Kubernetes operator
- Full-text search capabilities
- TLS encryption throughout

### Caching Strategy

The platform implements a sophisticated dual-cache architecture:

**Application Cache (varnish-for-app)**
- 256MB in-memory cache for dynamic content
- Direct backend to Mastodon web service
- Caches public API endpoints and static assets
- 100-2000 thread pool for concurrent requests

**Static Asset Cache (varnish-for-static)**
- 5GB persistent file-based cache
- Fronts S3 object storage via HAProxy
- Sophisticated TTL policies by path:
  - `/cache/`: 2 hours (48h grace)
  - `/media_attachments/`: 7 days (30d grace)
  - Avatar and emoji assets: 7 days
- PURGE support for cache invalidation
- Migration mode for bucket transitions

## Observability

### Metrics & Monitoring
- **VictoriaMetrics**: Time-series database
- **Grafana**: Visualization with SSO via Dex
- **Pre-built Dashboards**: ArgoCD, NGINX, Redis, PostgreSQL

### Logging
- **VictoriaLogs**: Centralized log aggregation
- **Sources**: Container, system, and application logs
- **Retention**: Configurable policies per log type

### Alerting
- **VMAlert**: Rule evaluation engine
- **Alertmanager**: Alert routing and grouping
- **Robusta**: Automated remediation
- **Coverage**: Infrastructure, application, and security alerts

## Security & Compliance

### Access Control
- **Dex**: OIDC provider for single sign-on
- **RBAC**: Fine-grained Kubernetes permissions
- **Network Policies**: Cilium-enforced microsegmentation

### Secrets Management
- **1Password Connect**: External secret synchronization
- **Encrypted Storage**: Secrets encrypted at rest
- **Automated Rotation**: Regular credential updates

### Certificates
- **cert-manager**: Automated TLS provisioning
- **Let's Encrypt**: Free SSL certificates
- **Auto-renewal**: Before expiration

## Multi-Instance Architecture

The platform supports multiple Mastodon instances through Kustomize overlays:

**Base Configuration** (`manifests/applications/mastodon/base/`)
- Shared Helm values and configurations
- Common resource definitions
- Default scaling parameters

**Instance Overlays** (`manifests/applications/mastodon/overlays/`)

*toot.community*
- Production instance with full federation
- Elasticsearch-powered search
- 3 replicas for all services
- Premium resource allocations

*microblog.network*
- Testing environment
- Limited federation mode
- Single replica deployments
- Minimal resource usage

## Disaster Recovery

### Backup Strategy

**Cluster Backups (Velero)**
- Daily snapshots of all Kubernetes resources
- 30-day retention in S3
- Regular restore testing

**Database Backups**
- Continuous WAL archiving
- Daily full backups
- Point-in-time recovery capability
- Encrypted S3 storage

### High Availability Features
- Multi-zone node distribution
- Automatic pod rescheduling
- Database failover automation
- Floating IP for API endpoint

## Platform Provisioning

### Build Pipeline

**1. Image Creation**
- Custom Talos images built with Packer
- Talos Factory integration for system extensions
- Output: Hetzner Cloud snapshots

**2. Infrastructure Deployment**
- OpenTofu manages cloud resources
- Task automation for common operations
- Remote state in S3 backend

**3. Cluster Bootstrap**
- Initial credential setup via 1Password
- Kustomize deployment of core components
- ArgoCD takes over for continuous operations

### Repository Structure

```
├── packer/              # Talos image building
├── platform/            # OpenTofu infrastructure code
│   ├── configs/         # Environment configurations
│   └── talos/          # Machine customizations
├── manifests/          # Kubernetes resources
│   ├── applications/   # Application deployments
│   └── cluster-bootstrap/ # Initial setup
└── charts/             # Helm chart dependencies
```

## Operational Excellence

### Continuous Deployment
- Git commits trigger ArgoCD synchronization
- Automated rollouts with health checks
- Instant rollback capabilities

### Maintenance Automation
- Database vacuum and reindexing
- Media file cleanup
- Certificate renewal
- Security patching via Renovate

### Performance Optimization
- Kernel tuning for high connection counts
- Optimized thread pools
- Strategic resource limits
- Intelligent caching policies

This architecture represents a production-grade Kubernetes platform optimized for running Mastodon at scale, with emphasis on reliability, security, and operational excellence. The infrastructure serves as a reference implementation for cloud-native social media platforms.