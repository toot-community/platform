- [x] implement IP ranges: [these](https://github.com/hetznercloud/hcloud-cloud-controller-manager/blob/main/docs/deploy_with_networks.md#considerations-on-the-ip-ranges)
- [x] Update README to work with new file structure
- [ ] Create ArgoCD app for microblog.network
- [ ] Install Velero
  - [ ] Test a full backup and restore

After taking ownership:

- [ ] Run a full recount on all Redis metrics, follower counts, etc. are incorrect (tootctl cache recount)
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
  - Look at Fastly TF module for inspiration
- [ ] DeepL no longer free?
- [ ] Translation endpoint is causing 500s
- [ ] Source IP isn't correctly passed on in the chain
- [ ] Set up MC mirror of Toot assets to NAS (Minio)
- [ ] N8N workflows?
- [x] [](https://toot.community/notifications/requests/114508118978012662)
- [x] IMAP migrate support@toot.community
- [ ] Ko-fi aankleden met plaatjes en tekst
- [ ] Patreon aankleden met plaatjes en tekst
- [ ] Eigen PayPal voor toot.c
- [x] DNSsec voor toot.c
- [ ] kennismaken met solarbranka
- [x] es resolving werkt nog niet
- [x] email werkt nog niet
- [ ] iftas sync?
- [x] Talos netkit support [text](https://github.com/siderolabs/talos/issues/9181)
- [x] Velero restore -> first restore PV/pod, then Elastic/DB cluster manager resources
- [ ] Database index inconsistency: /usr/local/bundle/gems/activerecord-7.1.5.1/lib/active_record/connection_adapters/postgresql/database_statements.rb:55:in `exec': ERROR:  index row requires 22576 bytes, maximum size is 8191 (PG::ProgramLimitExceeded) (tootctl status remove)
- [ ] Was bezig met S3 gateway, werkt niet. Conn refused vanuit ingress. Was template aan 't mounten om echte melding te zien. 

Stage 2 after ownership:

- [ ] Adapt the static Varnish config to gracefully handle the S3 migration (fetch hetzer -> 404? -> fetch wasabi)
- [ ] Migrate S3 to Hetzner. 