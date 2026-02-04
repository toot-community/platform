# Cloudflare Tunnel migration plan (replace Traefik/CrowdSec/Ingress)

This plan describes how to migrate the current ingress/gateway setup to Cloudflare Tunnel with zero downtime, while preserving source IP for Mastodon and keeping the platform highly available.

## Current ingress/gateway inventory (hostnames + wiring)

### Ingresses (Traefik)

* **argocd.toot.community** → `argocd-server:80` via Ingress `argocd` (traefik class).
* **workflows.toot.community** → `n8n:80` via Ingress `n8n` (traefik class).
* **idp.toot.community** → `dex` service (ports 80/443) via Dex Helm ingress (traefik class).
* **toot.community** → Mastodon web via chart ingress/gateway configuration.
* **streaming.toot.community** → Mastodon streaming via chart ingress/gateway configuration.
* **static.toot.community** → Mastodon static (S3/Varnish) via chart ingress/gateway configuration.
* **microblog.network** → Mastodon web via chart ingress/gateway configuration.
* **streaming.microblog.network** → Mastodon streaming via chart ingress/gateway configuration.
* **static.microblog.network** → Mastodon static (S3/Varnish) via chart ingress/gateway configuration.

### Gateway API (Traefik)

* **Gateway `shared`** serves `toot.community`, `*.toot.community`, `microblog.network`, `*.microblog.network` on ports 8000/8443 with TLS termination. HTTPRoutes (e.g., OIDC issuer) reference `shared` listener sections.
* **oidc.toot.community** → `oidc-proxy:80` via HTTPRoute bound to `shared` / `wildcard-toot-community-https`.

### Existing ingress/gateway snippets (for reference)

```yaml
# manifests/applications/traefik/gateway-api/shared-gateway.yaml
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: shared
spec:
  gatewayClassName: traefik
  listeners:
    - protocol: HTTPS
      port: 8443
      name: wildcard-toot-community-https
      hostname: "*.toot.community"
    - protocol: HTTPS
      port: 8443
      name: wildcard-microblog-network-https
      hostname: "*.microblog.network"
```

```yaml
# manifests/applications/argocd/ingress.yaml
spec:
  ingressClassName: traefik
  rules:
    - host: argocd.toot.community
      http:
        paths:
          - backend:
              service:
                name: argocd-server
                port:
                  number: 80
```

```yaml
# manifests/applications/n8n/ingress.yaml
spec:
  ingressClassName: traefik
  rules:
    - host: workflows.toot.community
      http:
        paths:
          - backend:
              service:
                name: n8n
                port:
                  number: 80
```

```yaml
# manifests/applications/k8s-oidc-issuer/httproute.yaml
spec:
  parentRefs:
  - name: shared
    namespace: traefik-system
    sectionName: wildcard-toot-community-https
  hostnames:
  - oidc.toot.community
  rules:
  - backendRefs:
    - name: oidc-proxy
      port: 80
```

```yaml
# manifests/applications/mastodon/overlays/toot.community/helm-values/mastodon.yaml
.ingress:
  web:
    host: toot.community
  streaming:
    host: streaming.toot.community
```

```yaml
# manifests/applications/mastodon/overlays/microblog.network/helm-values/mastodon.yaml
.ingress:
  web:
    host: microblog.network
  streaming:
    host: streaming.microblog.network
```

```yaml
# manifests/applications/mastodon/overlays/*/helm-values/mastodon.yaml
s3Gateway:
  ingress:
    host: static.<domain>
```

## Target architecture (Cloudflare Tunnel)

### Core goals

1. **Replace Traefik/CrowdSec/Ingress** with Cloudflare Tunnel (cloudflared) + Cloudflare Zero Trust.
2. **Preserve source IP** for Mastodon and other services.
3. **Zero-downtime migration** through parallel routing and DNS cutover.
4. **High availability** across nodes and zones.

### High-level wiring (proposed)

```
Client
  ↳ Cloudflare edge (WAF, DDoS, bot/ratelimit, TLS)
      ↳ Cloudflare Tunnel (cloudflared, k8s deployment)
          ↳ Internal service (ClusterIP / Service)
```

**Key change:** public traffic no longer hits Traefik LoadBalancer. Instead Cloudflare Tunnel connects outbound from the cluster to Cloudflare edge.

## Cloudflare Tunnel deployment plan

### 1) Create Cloudflare tunnel(s)

* Create **one tunnel per cluster** or **per environment** (prod/staging). For HA, run **multiple connectors** (cloudflared replicas) for the same tunnel.
* Prefer **Named Tunnels** with **JSON/remote config** managed in Git (or via ArgoCD) so routing is declarative.

### 2) Run cloudflared in Kubernetes

Deploy `cloudflared` as a **Deployment** with:

* **replicas: 2-3** (spread across nodes).
* PodDisruptionBudget to keep at least 1-2 replicas.
* `--metrics` endpoint + Prometheus scrape for monitoring.
* Optional `topologySpreadConstraints` for zone/host spread.

Example (simplified) Kubernetes spec:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: cloudflared
spec:
  replicas: 3
  template:
    spec:
      containers:
      - name: cloudflared
        image: cloudflare/cloudflared:latest
        args: ["tunnel", "--config", "/etc/cloudflared/config.yaml", "run"]
        volumeMounts:
        - name: config
          mountPath: /etc/cloudflared
      volumes:
      - name: config
        secret:
          secretName: cloudflared-config
```

### 3) Configure tunnel ingress rules

Map each hostname to a **Kubernetes Service** (ClusterIP or Headless) through a local service (e.g., `traefik` or direct service). Example:

```yaml
# cloudflared config.yaml
ingress:
  - hostname: argocd.toot.community
    service: http://argocd-server.argocd.svc.cluster.local:80
  - hostname: workflows.toot.community
    service: http://n8n.n8n.svc.cluster.local:80
  - hostname: idp.toot.community
    service: https://dex.dex.svc.cluster.local:443
  - hostname: oidc.toot.community
    service: http://oidc-proxy.oidc-issuer.svc.cluster.local:80
  - hostname: toot.community
    service: http://mastodon-web.mastodon.svc.cluster.local:3000
  - hostname: streaming.toot.community
    service: http://mastodon-streaming.mastodon.svc.cluster.local:4000
  - hostname: static.toot.community
    service: http://varnish-for-static.mastodon.svc.cluster.local:80
  - hostname: microblog.network
    service: http://mastodon-web.mastodon.svc.cluster.local:3000
  - hostname: streaming.microblog.network
    service: http://mastodon-streaming.mastodon.svc.cluster.local:4000
  - hostname: static.microblog.network
    service: http://varnish-for-static.mastodon.svc.cluster.local:80
  - service: http_status:404
```

> Note: adjust service names/namespaces to match actual chart releases (e.g., `mastodon-web` vs `toot-community-web`).

### 4) Source IP preservation for Mastodon

Cloudflare Tunnel terminates client connections at the edge. To preserve the true client IP:

1. **Enable CF-Connecting-IP / True-Client-IP** headers at Cloudflare.
2. Configure the **application** (Mastodon) or **proxy** to trust these headers.
3. Ensure **cloudflared** is the only source of those headers inside the cluster.

For Mastodon, you can set:

* `TRUSTED_PROXY_IP` / `TRUSTED_PROXY_IPS` env values to include the cloudflared pods’ IP range.
* Configure the Rails app to accept `CF-Connecting-IP`.

If using an internal reverse proxy (e.g., NGINX) in front of Mastodon, explicitly set:

```nginx
real_ip_header CF-Connecting-IP;
set_real_ip_from <cloudflared-pod-cidr>;
```

### 5) Make it robust & highly available

**Tunnel layer**

* 3+ `cloudflared` replicas; PDB minAvailable 2.
* Spread across nodes/zones.
* Use named tunnel with **multiple connectors**; Cloudflare handles connector health.

**Cloudflare edge**

* Enable **WAF**, **DDoS protection**, and **rate limiting** (replacing CrowdSec).
* Use **Cache Rules** / **Tiered Cache** for static content.

**Service layer**

* Ensure internal services (Mastodon web/streaming, Varnish) have multiple replicas and autoscaling.
* Define readiness/liveness probes for all exposed services.

**Observability**

* cloudflared metrics scraped by Prometheus.
* Cloudflare logs (Logpush) for analytics and auditing.

### 6) Zero-downtime migration strategy

1. **Deploy cloudflared** and configure tunnel routes in parallel with Traefik.
2. **Create Cloudflare DNS records** pointing to tunnel (`CNAME` to `uuid.cfargotunnel.com`).
3. **Lower DNS TTL** (24-48 hours before cutover) to 60s.
4. **Test per-hostname** using temporary hostnames or `hosts` override.
5. **Cutover in phases**:
   * Non-critical (argocd, workflows) → then idp/oidc → then static → then web/streaming.
6. Monitor traffic, logs, and health checks after each phase.
7. When stable, **remove Traefik ingress/gateway resources** and decommission CrowdSec.

### 7) Decommission Traefik/CrowdSec/Ingress

* Remove `traefik` Helm release or disable all ingress/gateway providers.
* Remove Gateways/Ingresses (or keep for internal-only use).
* Update cert-manager solver (ACME HTTP01) to use DNS01 in Cloudflare.

## Risks & mitigations

| Risk | Mitigation |
|------|------------|
| Loss of client IP | Configure `CF-Connecting-IP` headers and trusted proxy settings. |
| Streaming/websocket issues | Ensure Cloudflare proxied mode supports WebSocket; use appropriate timeouts. |
| Unexpected downtime | Use phased DNS cutover + low TTL. |
| TLS cert issues | Switch cert-manager to DNS01 with Cloudflare API. |

## Open questions / required inputs

1. Confirm exact Mastodon service names in the cluster for web/streaming/static.
2. Decide if you want **one tunnel** or **multiple tunnels** per domain.
3. Decide Cloudflare plan features (WAF, rate limiting tiers).
4. Validate firewall rules to allow outbound cloudflared connections.
