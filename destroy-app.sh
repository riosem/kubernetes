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
    echo "  ENV=dev REGION=us-east-2 APP=fastapi-app ./destroy-app.sh"
    echo "  ENV=dev REGION=us-east-2 APP=nginx-app ./destroy-app.sh"
    echo "  ENV=dev REGION=us-east-2 APP=nodejs-app ./destroy-app.sh"
    echo "  ENV=dev REGION=us-east-2 APP=postgres-app ./destroy-app.sh"
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
fi

# Step 2: Find and deploy application manifest
echo ""
echo "📦 Destroying application: $APP"

# Look for manifest file with flexible naming
MANIFEST_FILE="manifests/apps/$APP.yaml"

echo "📄 Using manifest: $MANIFEST_FILE"

# Deploy the application
echo "🚀 Applying Kubernetes manifest..."
kubectl delete -f $MANIFEST_FILE --ignore-not-found

# Step 3: Wait for resources to be cleaned up
echo ""
echo "⏳ Waiting for deployment to be deleted..."

# Extract deployment name from the manifest (assuming it follows naming conventions)
DEPLOYMENT_NAME=$APP

# Validate if deployment exists
if kubectl get deployment $DEPLOYMENT_NAME >/dev/null 2>&1; then
    echo "📊 Monitoring deletion of deployment: $DEPLOYMENT_NAME"
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
echo "✅ Application '$APP' destroyed successfully!"
echo ""
