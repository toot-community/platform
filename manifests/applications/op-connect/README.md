# Install

kubectl create namespace op-connect
kubectl create --namespace op-connect secret generic op-credentials --from-literal=1password-credentials.json="$(op read 'op://toot.community/toot.community Production on Hetzner Credentials File/1password-credentials.json' | base64 -w 0)"
kubectl create --namespace op-connect secret generic onepassword-token --from-literal=token="$(op read 'op://toot.community/put37jzwsy6wtsfydfdwvpdaxm/credential')"
kustomize build --enable-helm .