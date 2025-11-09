#!/usr/bin/env bash
set -euo pipefail

echo "🚀 Setting up development environment..."

# Install pre-commit hooks
if command -v pre-commit &> /dev/null; then
    echo "📋 Installing pre-commit hooks..."
    pre-commit install
else
    echo "⚠️  pre-commit not found. Install with: pip install pre-commit"
fi

# Initialize Terraform
echo "🏗️  Initializing Terraform..."
cd terraform
terraform init

# Create dev workspace if it doesn't exist
if ! terraform workspace list | grep -q "dev"; then
    echo "📁 Creating dev workspace..."
    terraform workspace new dev
else
    echo "📁 Selecting dev workspace..."
    terraform workspace select dev
fi

echo "✅ Development environment setup complete!"
echo ""
echo "Next steps:"
echo "1. Configure AWS credentials: aws configure"
echo "2. Review terraform/environments/dev/terraform.tfvars"
echo "3. Deploy: ./scripts/deploy.sh -e dev"# Updated Sun Nov  9 12:50:31 CET 2025
# Updated Sun Nov  9 12:52:07 CET 2025
