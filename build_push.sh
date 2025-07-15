#!/bin/bash

set -e

# ENV=${ENV:-dev}
# REGION=${REGION:-us-east-2}
# APP=${APP:-fastapi-app}
# IMAGE_TAG=${IMAGE_TAG}

echo "🐳 Building and Deploying FastAPI Application"
echo "Environment: $ENV"
echo "Region: $REGION"
echo "App: $APP"
echo "Image Tag: $IMAGE_TAG"
echo "=================================="

# Step 1: Get ECR repository URL from Terraform
echo "🔍 Getting ECR repository URL..."
cd terraform
ECR_URL=$(terraform output -raw ecr_repository_url)
if [ -z "$ECR_URL" ]; then
    echo "❌ Error: ECR repository not found"
    echo "Deploy infrastructure first: ENV=$ENV REGION=$REGION APP=eks ./deploy-infra.sh"
    exit 1
fi
cd ..

echo "📦 ECR Repository: $ECR_URL"

# Step 2: Build Docker image
echo ""
echo "🔨 Building Docker image..."
docker build -t $APP:$IMAGE_TAG src/

# Step 3: Tag for ECR
echo "🏷️  Tagging image for ECR..."
docker tag $APP:$IMAGE_TAG $ECR_URL:$IMAGE_TAG

# Step 4: Login to ECR
echo "🔑 Logging into ECR..."
aws ecr get-login-password --region $REGION | docker login --username AWS --password-stdin $ECR_URL

# Step 5: Push to ECR
echo "📤 Pushing image to ECR..."
docker push $ECR_URL:$IMAGE_TAG

# Step 6: Update manifest with new image
echo ""
echo "📝 Updating Kubernetes manifest..."
MANIFEST_FILE="manifests/apps/$APP.yaml"

# Create a backup
cp $MANIFEST_FILE $MANIFEST_FILE.backup

# Update the image in the manifest
sed -i "s|image: .*|image: \"$ECR_URL:$IMAGE_TAG\"|g" $MANIFEST_FILE

echo "✅ Updated manifest with image: $ECR_URL:$IMAGE_TAG"

# Step 7: Deploy to Kubernetes
echo ""
echo "🚀 Deploying to Kubernetes..."
kubectl apply -f $MANIFEST_FILE

# Step 8: Wait for rollout
echo ""
echo "⏳ Waiting for deployment to complete..."
kubectl rollout status deployment/$APP --timeout=300s

echo ""
echo "📋 Deployment Status:"
kubectl get deployment $APP
kubectl get pods -l app=$APP

echo ""
echo "✅ Build and deployment completed successfully!"
echo ""
echo "🧪 Test your application:"
echo "  ./test_fastapi_endpoints.sh"
echo ""
echo "📊 Monitor your deployment:"
echo "  kubectl logs -l app=$APP --tail=50"
echo "  kubectl describe deployment $APP"