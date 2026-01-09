# k8s-oidc-issuer

Issuer URL
- https://oidc.toot.community

Public endpoints
- https://oidc.toot.community/.well-known/openid-configuration
- https://oidc.toot.community/openid/v1/jwks

Talos patch (issuer URL)
- Apply to control plane nodes (replace the TALOSCONFIG path and node IPs):
  ```bash
  cat <<'EOF' > /tmp/oidc-issuer-patch.yaml
  cluster:
    apiServer:
      extraArgs:
        service-account-issuer: https://oidc.toot.community
        service-account-jwks-uri: https://oidc.toot.community/openid/v1/jwks
  EOF

  TALOSCONFIG=/path/to/talosconfig.yaml \
  talosctl patch mc --nodes 10.0.1.3,10.0.1.4,10.0.1.5 --patch @/tmp/oidc-issuer-patch.yaml
  ```

Verification
- From outside the cluster:
  - `curl -sSf https://oidc.toot.community/.well-known/openid-configuration`
  - `curl -sSf https://oidc.toot.community/openid/v1/jwks`
- From inside cert-manager (projected token claims):
  - Run:
    ```bash
    kubectl -n cert-manager exec deploy/cert-manager -c cert-manager -- sh -c '
    python - <<'"'"'PY'"'"'
    import base64, json
    raw = open("/var/run/secrets/aws/token").read().strip()
    payload = raw.split(".")[1]
    payload += "=" * (-len(payload) % 4)
    print(json.dumps(json.loads(base64.urlsafe_b64decode(payload)), indent=2))
    PY'
    ```
  - Confirm `iss` is `https://oidc.toot.community`, `aud` contains `sts.amazonaws.com`, and `sub` matches `system:serviceaccount:cert-manager:cert-manager` (or your configured service account).

AWS IAM
- Create an IAM OIDC provider for `https://oidc.toot.community`.
- Example trust policy (replace `<ACCOUNT_ID>`):

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::<ACCOUNT_ID>:oidc-provider/oidc.toot.community"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "oidc.toot.community:aud": "sts.amazonaws.com",
          "oidc.toot.community:sub": "system:serviceaccount:cert-manager:cert-manager"
        }
      }
    }
  ]
}
```
