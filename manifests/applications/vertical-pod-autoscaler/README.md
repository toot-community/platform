# Vertical Pod Autoscaler (VPA)

This app installs the upstream VPA controller components (recommender, updater, admission controller) from the autoscaler repo pinned to v1.5.1.

## Check recommendations

```bash
kubectl get vpa -A
kubectl describe vpa <name> -n <namespace>
```

## VPA resources

VPA custom resources are managed by the `vpa-resources` application and rendered from a single values file:

`manifests/applications/vpa-resources/helm-values.yaml`

## Enable VPA updates (InPlaceOrRecreate)

Stage 1 ships with `updateMode: "Off"` for every VPA. To enable updates later, set:

```yaml
updateMode: "InPlaceOrRecreate"
```

in `manifests/applications/vpa-resources/helm-values.yaml`.

## Add a VPA

Add a new entry under `vpas:` in `manifests/applications/vpa-resources/helm-values.yaml` with the targetRef and resourcePolicy for the workload.
