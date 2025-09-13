#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
TERRAFORM_DIR="$PROJECT_ROOT/terraform"

echo "🔍 Validating Terraform configuration..."

cd "$TERRAFORM_DIR"

# Format check
echo "📝 Checking Terraform formatting..."
terraform fmt -check -recursive

# Initialize without backend
echo "🚀 Initializing Terraform..."
terraform init -backend=false

# Validate syntax
echo "✅ Validating Terraform syntax..."
terraform validate

# Validate each environment
for env in dev staging prod; do
    if [[ -f "environments/$env/terraform.tfvars" ]]; then
        echo "🔍 Validating $env environment..."
        terraform plan -var-file="environments/$env/terraform.tfvars" -out="/dev/null"
    fi
done

echo "✅ All validations passed!"