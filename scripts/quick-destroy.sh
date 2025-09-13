#!/usr/bin/env bash
set -euo pipefail

ENVIRONMENT="${1:-dev}"
cd "$(dirname "$0")/../terraform"

echo "🗑️ Quick destroying $ENVIRONMENT environment..."

terraform workspace select "$ENVIRONMENT" 2>/dev/null || { echo "Environment $ENVIRONMENT not found"; exit 1; }

CLUSTER_NAME=$(terraform output -raw cluster_name 2>/dev/null || echo "")
AWS_REGION=$(grep aws_region "environments/$ENVIRONMENT/terraform.tfvars" | cut -d'"' -f2)

if [[ -n "$CLUSTER_NAME" ]] && command -v kubectl &>/dev/null; then
    aws eks update-kubeconfig --region "$AWS_REGION" --name "$CLUSTER_NAME" 2>/dev/null || true
    kubectl delete svc --all --all-namespaces --timeout=30s 2>/dev/null || true
    kubectl delete pvc --all --all-namespaces --timeout=30s 2>/dev/null || true
    sleep 5
fi

terraform destroy -var-file="environments/$ENVIRONMENT/terraform.tfvars" -auto-approve

echo "✅ Destruction complete!"