# Deployment Instructions

## Before First Use

### 1. Update Manifests with Your Values

**FastAPI App** (`manifests/apps/fastapi-app.yaml`):

```bash
# Replace placeholder with your ECR URL
sed -i 's|<AWS_ACCOUNT_ID>|YOUR_ACCOUNT_ID|g' manifests/apps/fastapi-app.yaml
sed -i 's|<REGION>|us-east-2|g' manifests/apps/fastapi-app.yaml
```

**PostgreSQL App** (`manifests/apps/postgres-app.yaml`):

```bash
# Generate secure password
POSTGRES_PASSWORD=$(openssl rand -base64 32)
POSTGRES_PASSWORD_B64=$(echo -n "$POSTGRES_PASSWORD" | base64)

# Update manifest
sed -i "s|<BASE64_ENCODED_PASSWORD>|$POSTGRES_PASSWORD_B64|g" manifests/apps/postgres-app.yaml
sed -i "s|<POSTGRES_PASSWORD>|$POSTGRES_PASSWORD|g" manifests/apps/postgres-app.yaml
sed -i "s|<PASSWORD>|$POSTGRES_PASSWORD|g" manifests/apps/fastapi-app.yaml
```

### 2. Deploy Infrastructure

```bash
ENV=dev REGION=us-east-2 APP=eks ./deploy-infra.sh
```

### 3. Build and Deploy Applications

```bash
ENV=dev REGION=us-east-2 APP=fastapi-app IMAGE_TAG=v1.0.0 ./build_push.sh
ENV=dev REGION=us-east-2 APP=postgres-app ./deploy-app.sh
ENV=dev REGION=us-east-2 APP=fastapi-app ./deploy-app.sh
```

## Security Notes

- **Never commit real passwords or secrets**
- **Use AWS Secrets Manager for production**
- **Rotate credentials regularly**
- **Follow principle of least privilege**
