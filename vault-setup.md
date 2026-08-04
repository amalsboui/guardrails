# Vault Setup & Initialization

Vault requires a one-time bootstrap process that cannot be managed through GitOps because Vault must be configured before it can provide secrets to the cluster.

This setup performs the following:

- Enables Kubernetes authentication so workloads can authenticate using their ServiceAccount tokens
- Creates the KV secrets engine used to store application secrets
- Creates a Mattermost read-only policy
- Configures a Kubernetes auth role for the Mattermost namespace
- Stores the database and MinIO credentials consumed by External Secrets Operator

## Connect to Vault

Start a local port-forward and configure the Vault CLI:

```bash
kubectl port-forward svc/vault -n vault 8200:8200 &

export VAULT_ADDR='http://127.0.0.1:8200'
export VAULT_TOKEN='<vault-token>'
```

## Configure Kubernetes Authentication

```bash
vault auth enable kubernetes

vault write auth/kubernetes/config \
  kubernetes_host="https://kubernetes.default.svc"
```

## Create Secrets Engine

```bash
vault secrets enable -path=secret kv-v2
```

## Create Mattermost Policy

```bash
vault policy write mattermost - <<EOF
path "secret/data/mattermost/*" {
  capabilities = ["read"]
}
EOF
```

## Create Kubernetes Auth Role

```bash
vault write auth/kubernetes/role/mattermost \
  bound_service_account_names="*" \
  bound_service_account_namespaces="mattermost" \
  policies=mattermost \
  ttl=1h
```

## Store Application Secrets

Database credentials:

```bash
vault kv put secret/mattermost/db \
  DB_CONNECTION_STRING="postgres://mmuser:mmpassword@postgres-postgresql.mattermost.svc.cluster.local:5432/mattermost?sslmode=disable" \
  password=mmpassword \
  postgres-password=mmpassword
```

MinIO credentials:

```bash
vault kv put secret/mattermost/minio \
  accesskey=minioadmin \
  secretkey=minioadmin123
```

After this bootstrap step, secret management becomes fully GitOps-driven. External Secrets Operator authenticates with Vault using Kubernetes authentication and automatically synchronizes secrets into Kubernetes resources consumed by Mattermost.