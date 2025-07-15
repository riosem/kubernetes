#!/bin/bash

# EKS Infrastructure deployment script with Terraform workspaces
# Usage: ENV=dev REGION=us-east-2 APP=eks ./deploy-infra.sh

set -e

ENV=$ENV
REGION=$REGION
APP=$APP

echo "🏗️ Deploying EKS Infrastructure"
echo "Environment: $ENV"
echo "Region: $REGION"
echo "App: $APP"
echo "=================================="

# Step 1: Install dependencies if needed
if ! command -v terraform &> /dev/null || ! command -v kubectl &> /dev/null || ! command -v jq &> /dev/null; then
    echo "📦 Installing dependencies..."
    ./install.sh
fi

# Step 2: Deploy infrastructure
echo ""
echo "🏗️ Deploying EKS infrastructure..."
cd terraform

# Use terraform script for initializing, planning, applying
APP=$APP REGION=$REGION ENV=$ENV ./tf plan || exit 1
APP=$APP REGION=$REGION ENV=$ENV ./tf apply || exit 1

# Step 3: Update kubeconfig and verify authentication
echo ""
echo "🔧 Configuring kubectl access..."
CLUSTER_NAME=$(terraform output -raw cluster_name)
echo "Cluster Name: $CLUSTER_NAME"
aws eks update-kubeconfig --region $REGION --name $CLUSTER_NAME

# Clear authentication caches to avoid stale tokens
echo "🧹 Clearing authentication caches..."
rm -rf ~/.kube/cache/ 2>/dev/null || true
rm -rf ~/.aws/cli/cache/ 2>/dev/null || true

# Verify kubectl authentication works
echo ""
echo "🔍 Verifying kubectl authentication..."
KUBECTL_RETRIES=3
KUBECTL_SUCCESS=false

for i in $(seq 1 $KUBECTL_RETRIES); do
    echo "Attempt $i/$KUBECTL_RETRIES: Testing kubectl connection..."
    if kubectl get nodes --request-timeout=30s >/dev/null 2>&1; then
        KUBECTL_SUCCESS=true
        break
    else
        echo "⚠️  kubectl authentication failed, retrying in 30 seconds..."
        sleep 30
    fi
done

cd ..

if [ "$KUBECTL_SUCCESS" = true ]; then
    echo ""
    echo "✅ EKS Infrastructure deployed successfully!"
    echo ""
    echo "📋 Infrastructure Summary:"
    echo "  Cluster Name: $CLUSTER_NAME"
    echo "  Region: $REGION"
    echo "  Workspace: $WORKSPACE_NAME"
    echo ""
    echo "🚀 Next Steps - Deploy Applications:"
    echo "  ENV=$ENV REGION=$REGION APP=fastapi-app ./deploy-app.sh"
    echo "  ENV=$ENV REGION=$REGION APP=nginx-app ./deploy-app.sh"
    echo "  ENV=$ENV REGION=$REGION APP=nodejs-app ./deploy-app.sh"
    echo "  ENV=$ENV REGION=$REGION APP=postgres-app ./deploy-app.sh"
    echo ""
    echo "🧪 Test Applications:"
    echo "  ./test-apps.sh"
    echo ""
    echo "🗑️ To destroy infrastructure:"
    echo "  ENV=$ENV REGION=$REGION AAPP=$APP ./destroy.sh"
else
    echo ""
    echo "❌ kubectl authentication failed after $KUBECTL_RETRIES attempts"
    echo ""
    echo "🔧 Try these troubleshooting steps:"
    echo "1. Check AWS credentials: aws sts get-caller-identity"
    echo "2. Run authentication fix: ENV=$ENV REGION=$REGION APP=$PROJECT_NAME ./auth-fix.sh"
    echo "3. Manual kubeconfig update: aws eks update-kubeconfig --region $REGION --name $CLUSTER_NAME"
    echo ""
    echo "📋 Infrastructure was deployed, but kubectl access needs to be fixed."
    exit 1
fi
