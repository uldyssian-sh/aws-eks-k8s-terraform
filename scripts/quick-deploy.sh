#!/usr/bin/env bash
set -euo pipefail

ENVIRONMENT="${1:-dev}"
cd "$(dirname "$0")/../terraform"

echo "🚀 Quick deploying $ENVIRONMENT environment..."

terraform init
terraform workspace select "$ENVIRONMENT" || terraform workspace new "$ENVIRONMENT"
terraform apply -var-file="environments/$ENVIRONMENT/terraform.tfvars" -auto-approve

CLUSTER_NAME=$(terraform output -raw cluster_name)
AWS_REGION=$(grep aws_region "environments/$ENVIRONMENT/terraform.tfvars" | cut -d'"' -f2)

aws eks update-kubeconfig --region "$AWS_REGION" --name "$CLUSTER_NAME"

echo "✅ Deployment complete!"
echo "Cluster: $CLUSTER_NAME"
echo "Region: $AWS_REGION"# Updated Sun Nov  9 12:50:31 CET 2025
# Updated Sun Nov  9 12:52:07 CET 2025
