# AWS EKS Kubernetes Terraform Makefile

.PHONY: help init plan apply destroy clean validate format docs test

# Default environment
ENV ?= dev

# Colors
CYAN := \033[0;36m
GREEN := \033[0;32m
YELLOW := \033[1;33m
RED := \033[0;31m
NC := \033[0m # No Color

help: ## Show this help message
	@echo "$(CYAN)AWS EKS Kubernetes Terraform$(NC)"
	@echo "$(CYAN)==============================$(NC)"
	@echo ""
	@echo "Available commands:"
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  $(CYAN)%-15s$(NC) %s\n", $$1, $$2}' $(MAKEFILE_LIST)
	@echo ""
	@echo "Environment variables:"
	@echo "  $(YELLOW)ENV$(NC)     Environment to use (dev, staging, prod) [default: dev]"
	@echo ""
	@echo "Examples:"
	@echo "  make plan ENV=dev"
	@echo "  make apply ENV=prod"
	@echo "  make destroy ENV=staging"

init: ## Initialize Terraform
	@echo "$(CYAN)Initializing Terraform...$(NC)"
	cd terraform && terraform init
	@echo "$(GREEN)Terraform initialized successfully$(NC)"

workspace: ## Create and select Terraform workspace
	@echo "$(CYAN)Setting up workspace: $(ENV)$(NC)"
	cd terraform && (terraform workspace select $(ENV) || terraform workspace new $(ENV))
	@echo "$(GREEN)Workspace $(ENV) selected$(NC)"

validate: ## Validate Terraform configuration
	@echo "$(CYAN)Validating Terraform configuration...$(NC)"
	cd terraform && terraform validate
	@echo "$(GREEN)Configuration is valid$(NC)"

format: ## Format Terraform files
	@echo "$(CYAN)Formatting Terraform files...$(NC)"
	cd terraform && terraform fmt -recursive
	@echo "$(GREEN)Files formatted successfully$(NC)"

plan: init workspace validate ## Plan Terraform deployment
	@echo "$(CYAN)Planning deployment for environment: $(ENV)$(NC)"
	cd terraform && terraform plan -var-file="environments/$(ENV)/terraform.tfvars" -out="$(ENV).tfplan"
	@echo "$(GREEN)Plan completed successfully$(NC)"

apply: plan ## Apply Terraform configuration
	@echo "$(CYAN)Applying Terraform configuration for environment: $(ENV)$(NC)"
	cd terraform && terraform apply "$(ENV).tfplan"
	@echo "$(GREEN)Deployment completed successfully$(NC)"

destroy: workspace ## Destroy Terraform resources
	@echo "$(RED)WARNING: This will destroy all resources for environment: $(ENV)$(NC)"
	@read -p "Are you sure? Type 'yes' to confirm: " confirm && [ "$$confirm" = "yes" ]
	cd terraform && terraform destroy -var-file="environments/$(ENV)/terraform.tfvars"
	@echo "$(GREEN)Resources destroyed successfully$(NC)"

clean: ## Clean up temporary files
	@echo "$(CYAN)Cleaning up temporary files...$(NC)"
	cd terraform && rm -f *.tfplan
	@echo "$(GREEN)Cleanup completed$(NC)"

output: workspace ## Show Terraform outputs
	@echo "$(CYAN)Terraform outputs for environment: $(ENV)$(NC)"
	cd terraform && terraform output

kubeconfig: ## Update kubeconfig for the cluster
	@echo "$(CYAN)Updating kubeconfig...$(NC)"
	$(eval CLUSTER_NAME := $(shell cd terraform && terraform output -raw cluster_name 2>/dev/null || echo ""))
	$(eval AWS_REGION := $(shell cd terraform && terraform output -raw aws_region 2>/dev/null || echo "eu-central-1"))
	@if [ -n "$(CLUSTER_NAME)" ]; then \
		aws eks update-kubeconfig --region $(AWS_REGION) --name $(CLUSTER_NAME); \
		echo "$(GREEN)Kubeconfig updated for cluster: $(CLUSTER_NAME)$(NC)"; \
	else \
		echo "$(RED)Error: Could not get cluster name$(NC)"; \
		exit 1; \
	fi

status: kubeconfig ## Show cluster status
	@echo "$(CYAN)Cluster Status$(NC)"
	@echo "$(CYAN)==============$(NC)"
	kubectl get nodes
	@echo ""
	@echo "$(CYAN)System Pods$(NC)"
	@echo "$(CYAN)===========$(NC)"
	kubectl get pods -n kube-system
	@echo ""
	@echo "$(CYAN)All Namespaces$(NC)"
	@echo "$(CYAN)==============$(NC)"
	kubectl get namespaces

deploy-example: kubeconfig ## Deploy example nginx application
	@echo "$(CYAN)Deploying example nginx application...$(NC)"
	kubectl apply -f examples/nginx-deployment.yaml
	@echo "$(GREEN)Example application deployed$(NC)"
	@echo "$(YELLOW)Check status with: kubectl get pods,svc$(NC)"

remove-example: kubeconfig ## Remove example nginx application
	@echo "$(CYAN)Removing example nginx application...$(NC)"
	kubectl delete -f examples/nginx-deployment.yaml --ignore-not-found=true
	@echo "$(GREEN)Example application removed$(NC)"

docs: ## Generate documentation
	@echo "$(CYAN)Generating documentation...$(NC)"
	@if command -v terraform-docs >/dev/null 2>&1; then \
		terraform-docs markdown table --output-file README.md terraform/modules/vpc; \
		terraform-docs markdown table --output-file README.md terraform/modules/eks; \
		terraform-docs markdown table --output-file README.md terraform/modules/security; \
		terraform-docs markdown table --output-file README.md terraform/modules/monitoring; \
		echo "$(GREEN)Documentation generated$(NC)"; \
	else \
		echo "$(YELLOW)terraform-docs not installed. Skipping documentation generation.$(NC)"; \
	fi

test: validate ## Run tests
	@echo "$(CYAN)Running tests...$(NC)"
	@if [ -d "tests" ]; then \
		cd tests && ./run-tests.sh; \
	else \
		echo "$(YELLOW)No tests directory found$(NC)"; \
	fi

security-scan: ## Run security scan with Checkov
	@echo "$(CYAN)Running security scan...$(NC)"
	@if command -v checkov >/dev/null 2>&1; then \
		checkov -d terraform --framework terraform; \
	else \
		echo "$(YELLOW)Checkov not installed. Install with: pip install checkov$(NC)"; \
	fi

cost-estimate: ## Estimate costs with Infracost
	@echo "$(CYAN)Estimating costs...$(NC)"
	@if command -v infracost >/dev/null 2>&1; then \
		cd terraform && infracost breakdown --path . --terraform-var-file environments/$(ENV)/terraform.tfvars; \
	else \
		echo "$(YELLOW)Infracost not installed. Install from: https://www.infracost.io/docs/$(NC)"; \
	fi

# Quick deployment commands
dev: ## Quick deploy to dev environment
	@$(MAKE) apply ENV=dev

staging: ## Quick deploy to staging environment
	@$(MAKE) apply ENV=staging

prod: ## Quick deploy to prod environment
	@$(MAKE) apply ENV=prod

# Monitoring commands
monitoring: kubeconfig ## Check monitoring stack
	@echo "$(CYAN)Monitoring Stack Status$(NC)"
	@echo "$(CYAN)=======================$(NC)"
	@if kubectl get namespace monitoring >/dev/null 2>&1; then \
		kubectl get pods -n monitoring; \
		echo ""; \
		echo "$(CYAN)Grafana Service$(NC)"; \
		kubectl get svc -n monitoring | grep grafana || echo "Grafana not found"; \
		echo ""; \
		echo "$(YELLOW)To access Grafana:$(NC)"; \
		echo "kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80"; \
	else \
		echo "$(YELLOW)Monitoring namespace not found. Enable monitoring in terraform.tfvars$(NC)"; \
	fi

logs: kubeconfig ## Show recent cluster logs
	@echo "$(CYAN)Recent Cluster Events$(NC)"
	@echo "$(CYAN)=====================$(NC)"
	kubectl get events --sort-by='.lastTimestamp' | tail -20

# Utility commands
check-tools: ## Check if required tools are installed
	@echo "$(CYAN)Checking required tools...$(NC)"
	@command -v terraform >/dev/null 2>&1 && echo "$(GREEN)✓ Terraform$(NC)" || echo "$(RED)✗ Terraform$(NC)"
	@command -v aws >/dev/null 2>&1 && echo "$(GREEN)✓ AWS CLI$(NC)" || echo "$(RED)✗ AWS CLI$(NC)"
	@command -v kubectl >/dev/null 2>&1 && echo "$(GREEN)✓ kubectl$(NC)" || echo "$(RED)✗ kubectl$(NC)"
	@command -v helm >/dev/null 2>&1 && echo "$(GREEN)✓ Helm$(NC)" || echo "$(RED)✗ Helm$(NC)"
	@aws sts get-caller-identity >/dev/null 2>&1 && echo "$(GREEN)✓ AWS Credentials$(NC)" || echo "$(RED)✗ AWS Credentials$(NC)"

install-tools: ## Install required tools (macOS only)
	@echo "$(CYAN)Installing required tools...$(NC)"
	@if [[ "$$(uname)" == "Darwin" ]]; then \
		command -v brew >/dev/null 2>&1 || (echo "$(RED)Homebrew not installed$(NC)" && exit 1); \
		brew install terraform awscli kubectl helm; \
		echo "$(GREEN)Tools installed successfully$(NC)"; \
	else \
		echo "$(YELLOW)Auto-install only supported on macOS. Please install tools manually.$(NC)"; \
	fi

# Default target
.DEFAULT_GOAL := help# Updated Sun Nov  9 12:52:07 CET 2025
