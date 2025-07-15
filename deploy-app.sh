#!/bin/bash

# Application deployment script for EKS clusters
# Usage: ENV=dev REGION=us-east-2 PROJECT_NAME=eks-starter APP=fastapi-app ./deploy-app.sh

set -e

# Default values
ENV=${ENV:-dev}
REGION=${REGION:-us-east-2}
APP=${APP:-""}

echo "🚀 Deploying Application"
echo "Environment: $ENV"
echo "Region: $REGION"
echo "App: $APP"
echo "=================================="

# Validate required parameters
if [ -z "$APP" ]; then
    echo "❌ Error: APP parameter is required"
    echo ""
    echo "Usage examples:"
    echo "  ENV=dev REGION=us-east-2 PROJECT_NAME=eks-starter APP=fastapi-app ./deploy-app.sh"
    echo "  ENV=dev REGION=us-east-2 PROJECT_NAME=eks-starter APP=nginx-app ./deploy-app.sh"
    echo "  ENV=dev REGION=us-east-2 PROJECT_NAME=eks-starter APP=nodejs-app ./deploy-app.sh"
    echo "  ENV=dev REGION=us-east-2 PROJECT_NAME=eks-starter APP=postgres-app ./deploy-app.sh"
    echo ""
    echo "Available apps:"
    ls -1 manifests/apps/ | grep '\.yaml$' | sed 's/\.yaml$//' | sed 's/^/  /'
    exit 1
fi

# Step 1: Verify EKS cluster exists and is accessible
echo ""
echo "🔍 Verifying EKS cluster access..."

# Get cluster name from Terraform
cd terraform
CLUSTER_NAME=$(./tf get-cluster-name)
if [ -z "$CLUSTER_NAME" ]; then
    echo "❌ Error: No EKS cluster found in workspace '$WORKSPACE_NAME'"
    echo ""
    echo "🏗️ Deploy infrastructure first:"
    echo "  ENV=$ENV REGION=$REGION APP=eks ./deploy-infra.sh"
    exit 1
fi

cd ..

# Update kubeconfig
echo "🔧 Updating kubeconfig for cluster: $CLUSTER_NAME"
aws eks update-kubeconfig --region $REGION --name $CLUSTER_NAME

# Test kubectl connectivity
echo "🔍 Testing kubectl connectivity..."
if ! kubectl get nodes --request-timeout=30s >/dev/null 2>&1; then
    echo "❌ Error: Cannot connect to EKS cluster"
    echo ""
    echo "🔧 Try these troubleshooting steps:"
    echo "1. Run authentication fix: ENV=$ENV REGION=$REGION PROJECT_NAME=$PROJECT_NAME ./auth-fix.sh"
    echo "2. Check AWS credentials: aws sts get-caller-identity"
    echo "3. Manual diagnostics: ./diagnose-auth.sh"
    exit 1
fi

# Step 2: Find and deploy application manifest
echo ""
echo "📦 Deploying application: $APP"

# Look for manifest file with flexible naming
MANIFEST_FILE="manifests/apps/$APP.yaml"

echo "📄 Using manifest: $MANIFEST_FILE"

# Deploy the application
echo "🚀 Applying Kubernetes manifest..."
kubectl apply -f $MANIFEST_FILE

# Step 3: Wait for deployment and show status
echo ""
echo "⏳ Waiting for deployment to be ready..."

# Extract deployment name from the manifest (assuming it follows naming conventions)
DEPLOYMENT_NAME=$APP

if [ -n "$DEPLOYMENT_NAME" ]; then
    echo "📊 Monitoring deployment: $DEPLOYMENT_NAME"
    kubectl rollout status deployment/$DEPLOYMENT_NAME --timeout=300s
    
    echo ""
    echo "📋 Deployment Status:"
    kubectl get deployment $DEPLOYMENT_NAME
    
    echo ""
    echo "📦 Pods:"
    kubectl get pods -l app=$DEPLOYMENT_NAME 2>/dev/null || kubectl get pods | grep $DEPLOYMENT_NAME || echo "No pods found with label app=$DEPLOYMENT_NAME"
    
    echo ""
    echo "🌐 Services:"
    kubectl get services -l app=$DEPLOYMENT_NAME 2>/dev/null || kubectl get services | grep $DEPLOYMENT_NAME || echo "No services found"
else
    echo "⚠️  Could not determine deployment name, checking general status..."
    echo ""
    echo "📦 All resources from manifest:"
    kubectl get -f $MANIFEST_FILE
fi

echo ""
echo "✅ Application '$APP' deployed successfully!"
echo ""
echo "🧪 Test the deployment:"
echo "  ./test-apps.sh"
echo ""
echo "📊 Monitor your app:"
echo "  kubectl get pods -l app=$DEPLOYMENT_NAME"
echo "  kubectl logs -l app=$DEPLOYMENT_NAME --tail=50"
echo "  kubectl describe deployment $DEPLOYMENT_NAME" 2>/dev/null || echo "  kubectl get all | grep $DEPLOYMENT_NAME"
echo ""
echo "🗑️ To remove this app:"
echo "  kubectl delete -f $MANIFEST_FILE"
