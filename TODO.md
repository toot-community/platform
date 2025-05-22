- [x] implement IP ranges: [these](https://github.com/hetznercloud/hcloud-cloud-controller-manager/blob/main/docs/deploy_with_networks.md#considerations-on-the-ip-ranges)
- [x] Update README to work with new file structure
- [x] Create ArgoCD app for microblog.network
- [x] Install Velero
  - [x] Test a full backup and restore

After taking ownership:

- [ ] Run a full recount on all Redis metrics, follower counts, etc. are incorrect (tootctl cache recount)
- [x] Check streaming
- [x] Set up Kubernetes access using OIDC with Dex
- [x] Set up Dex using the GitHub organization
- [x] Configure ArgoCD to use OIDC with Dex
- [x] Configure Grafana to use OIDC with Dex
- [x] Create a migration plan for PostgreSQL, Redis
- [x] Install the Elastic Operator for search
- [x] To drop Fastly, we need a good Varnish configuration
  - [x] For web
  - [x] For static
    - [ ] Test special purging from Mastodon for suspended accounts
  - Look at Fastly TF module for inspiration
- [ ] DeepL no longer free?
- [x] Translation endpoint is causing 500s
- [x] Source IP isn't correctly passed on in the chain
- [ ] Set up MC mirror of Toot assets to NAS (Minio)
- [x] N8N workflows?
- [x] [](https://toot.community/notifications/requests/114508118978012662)
- [x] IMAP migrate support@toot.community
- [x] DNSsec voor toot.c
- [x] es resolving werkt nog niet
- [x] email werkt nog niet
- [ ] iftas sync?
- [x] Talos netkit support [text](https://github.com/siderolabs/talos/issues/9181)
- [x] Velero restore -> first restore PV/pod, then Elastic/DB cluster manager resources
- [x] Was bezig met S3 gateway, werkt niet. Conn refused vanuit ingress. Was template aan 't mounten om echte melding te zien. 
- [x] Prepare secrets and values file for toot.commmunity
- [x] Rotate nodes to bigger ones
- [x] Increase resources for DB, tune values/resources for Mastodon
- [ ] Patch argo haproxy to allow multiple pods on the same node

After migration:
- [ ] Cleanup PSQL users: barman, datadog, n8n, streaming_barman, toot_rep, v-oidc-CgU-tootcomm-KxwpjS1lCNIzfyIMsI1J-1707073445, v-oidc-CgU-tootcomm-g8Ct2h5EpMzPtBuNGjuu-1707051377, vault
  - [ ] Remove replication permission from `app` user
- [ ] [HTST fixen](https://hstspreload.org/?domain=toot.community#submission-form)
- [ ] Database index inconsistency: /usr/local/bundle/gems/activerecord-7.1.5.1/lib/active_record/connection_adapters/postgresql/database_statements.rb:55:in `exec': ERROR:  index row requires 22576 bytes, maximum size is 8191 (PG::ProgramLimitExceeded) (tootctl status remove)

Stage 2 after ownership:

- [ ] Adapt the static Varnish config to gracefully handle the S3 migration (fetch hetzer -> 404? -> fetch wasabi)
- [ ] Migrate S3 to Hetzner. 

At some point
- [ ] Ko-fi aankleden met plaatjes en tekst
- [ ] Patreon aankleden met plaatjes en tekst
- [ ] Eigen PayPal voor toot.c
- [ ] kennismaken met solarbranka
