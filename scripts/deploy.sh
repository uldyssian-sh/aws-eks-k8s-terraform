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
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
TERRAFORM_DIR="$PROJECT_ROOT/terraform"

# Default values
ENVIRONMENT="dev"
AUTO_APPROVE=false
PLAN_ONLY=false

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

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to show usage
usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Deploy EKS cluster using Terraform

OPTIONS:
    -e, --environment ENV    Environment to deploy (dev, staging, prod) [default: dev]
    -a, --auto-approve      Auto approve Terraform apply
    -p, --plan-only         Only run terraform plan
    -h, --help              Show this help message

EXAMPLES:
    $0 -e dev                    # Deploy to dev environment
    $0 -e prod -a               # Deploy to prod with auto-approve
    $0 -e staging -p            # Plan only for staging
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
        -p|--plan-only)
            PLAN_ONLY=true
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            print_error "Unknown option: $1"
            usage
            exit 1
            ;;
    esac
done

# Validate environment
if [[ ! "$ENVIRONMENT" =~ ^(dev|staging|prod)$ ]]; then
    print_error "Invalid environment: $ENVIRONMENT. Must be one of: dev, staging, prod"
    exit 1
fi

# Check if environment config exists
ENV_CONFIG="$TERRAFORM_DIR/environments/$ENVIRONMENT/terraform.tfvars"
if [[ ! -f "$ENV_CONFIG" ]]; then
    print_error "Environment configuration not found: $ENV_CONFIG"
    exit 1
fi

print_status "Starting EKS deployment for environment: $ENVIRONMENT"

# Check prerequisites
print_status "Checking prerequisites..."

# Check if AWS CLI is installed and configured
if ! command -v aws &> /dev/null; then
    print_error "AWS CLI is not installed. Please install it first."
    exit 1
fi

# Check AWS credentials
if ! aws sts get-caller-identity &> /dev/null; then
    print_error "AWS credentials not configured or invalid. Please run 'aws configure'."
    exit 1
fi

# Check if Terraform is installed
if ! command -v terraform &> /dev/null; then
    print_error "Terraform is not installed. Please install it first."
    exit 1
fi

# Check if kubectl is installed
if ! command -v kubectl &> /dev/null; then
    print_warning "kubectl is not installed. You'll need it to interact with the cluster."
fi

# Check if helm is installed
if ! command -v helm &> /dev/null; then
    print_warning "Helm is not installed. Some features may not work properly."
fi

print_success "Prerequisites check completed"

# Change to terraform directory
cd "$TERRAFORM_DIR"

# Initialize Terraform
print_status "Initializing Terraform..."
terraform init

# Validate Terraform configuration
print_status "Validating Terraform configuration..."
terraform validate

# Format Terraform files
terraform fmt -recursive

# Create workspace for environment if it doesn't exist
if ! terraform workspace list | grep -q "$ENVIRONMENT"; then
    print_status "Creating Terraform workspace: $ENVIRONMENT"
    terraform workspace new "$ENVIRONMENT"
else
    print_status "Selecting Terraform workspace: $ENVIRONMENT"
    terraform workspace select "$ENVIRONMENT"
fi

# Plan deployment
print_status "Planning Terraform deployment..."
terraform plan -var-file="environments/$ENVIRONMENT/terraform.tfvars" -out="$ENVIRONMENT.tfplan"

if [[ "$PLAN_ONLY" == true ]]; then
    print_success "Plan completed. Review the plan above."
    exit 0
fi

# Apply deployment
if [[ "$AUTO_APPROVE" == true ]]; then
    print_status "Applying Terraform configuration (auto-approved)..."
    terraform apply "$ENVIRONMENT.tfplan"
else
    print_status "Applying Terraform configuration..."
    terraform apply "$ENVIRONMENT.tfplan"
fi

# Get cluster information
CLUSTER_NAME=$(terraform output -raw cluster_name)
AWS_REGION=$(terraform output -raw vpc_id | cut -d':' -f4)

print_success "EKS cluster deployed successfully!"
print_status "Cluster Name: $CLUSTER_NAME"
print_status "Region: $AWS_REGION"

# Update kubeconfig
if command -v kubectl &> /dev/null; then
    print_status "Updating kubeconfig..."
    aws eks update-kubeconfig --region "$AWS_REGION" --name "$CLUSTER_NAME"
    
    print_status "Verifying cluster access..."
    kubectl get nodes
    
    print_success "Cluster is ready!"
else
    print_warning "kubectl not found. To connect to your cluster, run:"
    echo "aws eks update-kubeconfig --region $AWS_REGION --name $CLUSTER_NAME"
fi

# Show useful information
echo
print_status "Useful commands:"
echo "  kubectl get nodes                    # List cluster nodes"
echo "  kubectl get pods --all-namespaces   # List all pods"
echo "  kubectl get svc --all-namespaces    # List all services"
echo
print_status "To destroy the cluster, run:"
echo "  ./scripts/destroy.sh -e $ENVIRONMENT"# Updated Sun Nov  9 12:50:31 CET 2025
# Updated Sun Nov  9 12:52:07 CET 2025
