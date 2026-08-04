# Vault Setup & Initialization

Vault requires a one-time initialization that cannot be GitOps-managed since it is bootstrapping the secrets system itself:

```bash
kubectl port-forward svc/vault -n vault 8200:8200 &
export VAULT_ADDR='http://127.0.0.1:8200'
export VAULT_TOKEN='root'

vault auth enable kubernetes
vault write auth/kubernetes/config kubernetes_host="https://kubernetes.default.svc"
vault secrets enable -path=secret kv-v2
vault policy write mattermost - <<EOF
path "secret/data/mattermost/*" { capabilities = ["read"] }
EOF
vault write auth/kubernetes/role/mattermost \
  bound_service_account_names="*" \
  bound_service_account_namespaces="mattermost" \
  policies=mattermost ttl=1h
vault kv put secret/mattermost/db \
  DB_CONNECTION_STRING="postgres://mmuser:mmpassword@postgres-postgresql.mattermost.svc.cluster.local:5432/mattermost?sslmode=disable" \
  password=mmpassword postgres-password=mmpassword
vault kv put secret/mattermost/minio \
  accesskey=minioadmin secretkey=minioadmin123
```