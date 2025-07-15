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
APP=$APP REGION=$REGION ENV=$ENV ./tf plan-destroy || exit 1
APP=$APP REGION=$REGION ENV=$ENV ./tf apply-destroy || exit 1