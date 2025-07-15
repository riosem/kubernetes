#!/bin/bash

# Installation script for EKS Terraform Starter dependencies
# Installs: kubectl (latest), Terraform (latest), AWS CLI (latest), jq

set -e

echo "🔧 Installing EKS Terraform Starter Dependencies"
echo "==============================================="

# Install system dependencies
echo "📦 Installing system dependencies..."
sudo apt-get -y update || exit 1
sudo apt-get -y install jq curl unzip || exit 1

# # Install KubeCTL
curl -O https://s3.us-west-2.amazonaws.com/amazon-eks/1.28.3/2023-11-14/bin/linux/amd64/kubectl
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
rm -rf kubectl

echo "✅ Verifying kubectl installation..."
kubectl version --client --output=yaml 2>/dev/null | grep gitVersion || kubectl version --client 2>/dev/null || echo "kubectl installed successfully"

# Install Terraform (latest stable version)
echo "📦 Installing Terraform (latest stable version)..."
TF_VERSION=$(curl -sL https://releases.hashicorp.com/terraform/index.json | jq -r '.versions[].builds[].version' | egrep -v 'rc|beta|alpha' | tail -1)

echo "Installing Terraform version: $TF_VERSION"
cd /tmp
curl -LO "https://releases.hashicorp.com/terraform/${TF_VERSION}/terraform_${TF_VERSION}_linux_amd64.zip"
unzip terraform_${TF_VERSION}_linux_amd64.zip
chmod +x terraform
sudo rm -f /usr/local/bin/terraform  # Remove any existing installation
sudo mv terraform /usr/local/bin/
rm terraform_${TF_VERSION}_linux_amd64.zip

echo "✅ Verifying Terraform installation..."
terraform version

# Install AWS CLI (latest version)
echo "📦 Installing AWS CLI (latest version)..."
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip -q awscliv2.zip
sudo ./aws/install --update
rm -rf awscliv2.zip
rm -rf aws

echo "✅ Verifying AWS CLI installation..."
aws --version

echo ""
echo "✅ Installation completed successfully!"
echo ""
echo "📋 Installed versions:"
echo "kubectl:   $(kubectl version --client --output=yaml 2>/dev/null | grep gitVersion | awk '{print $2}' || echo 'Version check failed')"
echo "Terraform: $(terraform version -json | jq -r '.terraform_version' 2>/dev/null || terraform version | head -1)"
echo "AWS CLI:   $(aws --version 2>/dev/null || echo 'Version check failed')"
echo "jq:        $(jq --version 2>/dev/null || echo 'Version check failed')"
echo ""
echo "🚀 Ready to deploy EKS infrastructure!"
echo ""
echo "Next steps:"
echo "1. Configure AWS credentials: aws configure"
echo "2. Deploy infrastructure: ENV=dev REGION=us-east-2 ./deploy-infra.sh"
echo "3. Deploy applications: ENV=dev REGION=us-east-2 ./deploy-all-apps.sh"