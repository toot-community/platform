- [x] implement IP ranges: [these](https://github.com/hetznercloud/hcloud-cloud-controller-manager/blob/main/docs/deploy_with_networks.md#considerations-on-the-ip-ranges)
- [x] Update README to work with new file structure

After taking ownership:

- [ ] Run a full recount on all Redis metrics, follower counts, etc. are incorrect
- [ ] Check streaming
- [ ] Set up Kubernetes access using OIDC with Dex
- [ ] Set up Dex using the GitHub organization
- [ ] Configure ArgoCD to use OIDC with Dex
- [ ] Configure Grafana to use OIDC with Dex
- [ ] Create a migration plan for PostgreSQL, Redis
- [ ] Install the Elastic Operator for search
- [ ] To drop Fastly, we need a good Varnish configuration
  - [ ] For web
  - [ ] For static
- [ ] DeepL no longer free?
- [ ] Translation endpoint is causing 500s

Stage 2 after ownership:

- [ ] Adapt the static Varnish config to gracefully handle the S3 migration (fetch hetzer -> 404? -> fetch wasabi)
- [ ] Migrate S3 to Hetzner. 