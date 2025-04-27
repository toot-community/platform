- [ ] placement groups
- [ ] cilium installeren vanuit terraform
- [ ] health check werkt nog niet vanuit TF
- [ ] cilium native routing hcloud ccm voor kubernetes
- [ ] [GH actions](https://developer.hashicorp.com/terraform/tutorials/automation/github-actions)
- [ ] verbinding loopt nu buitenlangs, wil ik dit toch binnenlangs met een jumphost doen? hoe?
- [ ] prefix met clusternaam-omgevingsnaam
- [ ] floating ip switch testen OF ombouwen naar LB (is wel beter denk ik)

[IMPLEMENT](https://github.com/siderolabs/contrib/tree/main/examples/terraform/hcloud/terraform/templates)

│ waiting for etcd to be healthy: rpc error: code = PermissionDenied desc = no request forwarding
│ waiting for etcd to be healthy: 2 errors occurred:
│       * 91.99.48.184: rpc error: code = Unavailable desc = connection error: desc = "transport: Error while dialing: dial tcp 91.99.48.184:50000: i/o timeout"
│       * 49.12.35.142: rpc error: code = Unavailable desc = connection error: desc = "transport: Error while dialing: dial tcp 49.12.35.142:50000: i/o timeout"

[text](https://github.com/sergelogvinov/terraform-talos/blob/main/hetzner/inventory.tf)

[text](https://github.com/hetznercloud/hcloud-cloud-controller-manager)