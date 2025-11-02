## CLI

### Host Audit Mode Toggle
* `cilium endpoint config $(cilium endpoint list -o jsonpath='{[?(@.status.identity.id==1)].id}') PolicyAuditMode=Enabled`

### Inspect host policies
* `cilium monitor -t policy-verdict --related-to $(cilium endpoint list -o jsonpath='{[?(@.status.identity.id==1)].id}')`
  * https://editor.networkpolicy.io/

