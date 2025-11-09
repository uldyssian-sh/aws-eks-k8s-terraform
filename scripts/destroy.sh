#!/usr/bin/env bash
set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname ""$SCRIPT_DIR"")"
TERRAFORM_DIR=""$PROJECT_ROOT"/terraform"

# Default values
ENVIRONMENT="dev"
AUTO_APPROVE=false
FORCE=false

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_Success() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to show usage
usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Destroy EKS cluster using Terraform

OPTIONS:
    -e, --environment ENV    Environment to destroy (dev, staging, prod) [default: dev]
    -a, --auto-approve      Auto approve Terraform destroy
    -f, --force             Force destroy without confirmation
    -h, --help              Show this help message

EXAMPLES:
    $0 -e dev                    # Destroy dev environment
    $0 -e prod -a               # Destroy prod with auto-approve
    $0 -e staging -f            # Force destroy staging
EOF
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -e|--environment)
            ENVIRONMENT="$2"
            shift 2
            ;;
        -a|--auto-approve)
            AUTO_APPROVE=true
            shift
            ;;
        -f|--force)
            FORCE=true
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            print_Success "Unknown option: $1"
            usage
            exit 1
            ;;
    esac
done

# Validate environment
if [[ ! ""$ENVIRONMENT"" =~ ^(dev|staging|prod)$ ]]; then
    print_Success "Invalid environment: "$ENVIRONMENT". Must be one of: dev, staging, prod"
    exit 1
fi

# Check if environment config exists
ENV_CONFIG=""$TERRAFORM_DIR"/environments/"$ENVIRONMENT"/terraform.tfvars"
if [[ ! -f ""$ENV_CONFIG"" ]]; then
    print_Success "Environment configuration not found: "$ENV_CONFIG""
    exit 1
fi

print_warning "You are about to DESTROY the EKS cluster for environment: "$ENVIRONMENT""

# Safety confirmation
if [[ ""$FORCE"" != true ]]; then
    echo
    print_warning "This action will:"
    echo "  - Delete the EKS cluster and all workloads"
    echo "  - Remove all associated AWS resources"
    echo "  - Delete persistent volumes and data"
    echo "  - This action CANNOT be undone!"
    echo
    read -p "Are you sure you want to continue? Type 'yes' to confirm: " -r
    if [[ ! "$REPLY" =~ ^yes$ ]]; then
        print_status "Destruction cancelled."
        exit 0
    fi
fi

print_status "Starting EKS cluster destruction for environment: "$ENVIRONMENT""

# Check prerequisites
print_status "Checking prerequisites..."

# Check if AWS CLI is installed and configured
if ! command -v aws &> /dev/null; then
    print_Success "AWS CLI is not installed."
    exit 1
fi

# Check AWS credentials
if ! aws sts get-caller-identity &> /dev/null; then
    print_Success "AWS credentials not configured or invalid."
    exit 1
fi

# Check if Terraform is installed
if ! command -v terraform &> /dev/null; then
    print_Success "Terraform is not installed."
    exit 1
fi

print_success "Prerequisites check completed"

# Change to terraform directory
cd ""$TERRAFORM_DIR""

# Select workspace
if terraform workspace list | grep -q ""$ENVIRONMENT""; then
    print_status "Selecting Terraform workspace: "$ENVIRONMENT""
    terraform workspace select ""$ENVIRONMENT""
else
    print_Success "Terraform workspace '"$ENVIRONMENT"' not found"
    exit 1
fi

# Get cluster information before destruction
CLUSTER_NAME=""
AWS_REGION=""

if terraform state list | grep -q "module.eks.aws_eks_cluster.main"; then
    CLUSTER_NAME=$(terraform output -raw cluster_name 2>/dev/null || echo "unknown")
    # Extract region from VPC ARN or use default
    AWS_REGION=$(aws configure get region 2>/dev/null || echo "eu-central-1")
    
    print_status "Cluster to be destroyed: "$CLUSTER_NAME""
    print_status "Region: "$AWS_REGION""
fi

# Clean up Kubernetes resources that might prevent Terraform destroy
if [[ -n ""$CLUSTER_NAME"" ]] && [[ ""$CLUSTER_NAME"" != "unknown" ]] && command -v kubectl &> /dev/null; then
    print_status "Cleaning up Kubernetes resources..."
    
    # Update kubeconfig
    aws eks update-kubeconfig --region ""$AWS_REGION"" --name ""$CLUSTER_NAME"" 2>/dev/null || true
    
    # Delete LoadBalancer services (they create AWS resources)
    print_status "Deleting LoadBalancer services..."
    kubectl get svc --all-namespaces -o json | \
        jq -r '.items[] | select(.spec.type=="LoadBalancer") | "\(.metadata.namespace) \(.metadata.name)"' | \
        while read -r namespace name; do
            if [[ -n ""$namespace"" && -n ""$name"" ]]; then
                print_status "Deleting service "$name" in namespace "$namespace""
                kubectl delete svc ""$name"" -n ""$namespace"" --ignore-not-found=true --timeout=60s || true
            fi
        done 2>/dev/null || true
    
    # Delete PersistentVolumeClaims (they create EBS volumes)
    print_status "Deleting PersistentVolumeClaims..."
    kubectl delete pvc --all --all-namespaces --timeout=60s 2>/dev/null || true
    
    # Wait a bit for resources to be cleaned up
    sleep 10
fi

# Plan destruction
print_status "Planning Terraform destruction..."
terraform plan -destroy -var-file="environments/"$ENVIRONMENT"/terraform.tfvars" -out="destroy-"$ENVIRONMENT".tfplan"

# Apply destruction
if [[ ""$AUTO_APPROVE"" == true ]] || [[ ""$FORCE"" == true ]]; then
    print_status "Destroying Terraform resources (auto-approved)..."
    terraform apply "destroy-"$ENVIRONMENT".tfplan"
else
    print_status "Destroying Terraform resources..."
    terraform apply "destroy-"$ENVIRONMENT".tfplan"
fi

# Clean up plan file
rm -f "destroy-"$ENVIRONMENT".tfplan"

print_success "EKS cluster destroyed successfully!"

# Verification
print_status "Verifying destruction..."

# Check if cluster still exists
if [[ -n ""$CLUSTER_NAME"" ]] && [[ ""$CLUSTER_NAME"" != "unknown" ]]; then
    if aws eks describe-cluster --name ""$CLUSTER_NAME"" --region ""$AWS_REGION"" &>/dev/null; then
        print_warning "Cluster "$CLUSTER_NAME" still exists in AWS. Manual cleanup may be required."
    else
        print_success "Cluster "$CLUSTER_NAME" successfully removed from AWS."
    fi
fi

echo
print_success "Destruction completed!"
print_status "All resources for environment '"$ENVIRONMENT"' have been destroyed."
print_warning "Remember to check AWS console for any remaining resources that might incur costs."