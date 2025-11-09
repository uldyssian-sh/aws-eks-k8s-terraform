# Deployment Guide

This guide provides detailed instructions for deploying AWS EKS clusters using this Terraform configuration.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Initial Setup](#initial-setup)
- [Environment Configuration](#environment-configuration)
- [Deployment Process](#deployment-process)
- [Post-Deployment](#post-deployment)
- [Troubleshooting](#troubleshooting)

## Prerequisites

### 1. Install Required Tools

#### Terraform
```bash
# macOS
brew install terraform

# Linux
wget https://releases.hashicorp.com/terraform/1.5.0/terraform_1.5.0_linux_amd64.zip
unzip terraform_1.5.0_linux_amd64.zip
sudo mv terraform /usr/local/bin/
```

#### AWS CLI
```bash
# macOS
brew install awscli

# Linux
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
```

#### kubectl
```bash
# macOS
brew install kubectl

# Linux
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
```

#### Helm
```bash
# macOS
brew install helm

# Linux
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
```

### 2. AWS Configuration

#### Configure AWS Credentials
```bash
aws configure
```

Enter your:
- AWS Access Key ID
- AWS Secret Access Key
- Default region (e.g., `eu-central-1`)
- Default output format (`json`)

#### Verify Configuration
```bash
aws sts get-caller-identity
```

### 3. Required AWS Permissions

Ensure your AWS user/role has the following permissions:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "eks:*",
        "ec2:*",
        "iam:*",
        "elasticloadbalancing:*",
        "autoscaling:*",
        "cloudformation:*",
        "kms:*",
        "logs:*"
      ],
      "Resource": "*"
    }
  ]
}
```

## Initial Setup

### 1. Clone Repository
```bash
git clone https://github.com/your-username/aws-eks-k8s-terraform.git
cd aws-eks-k8s-terraform
```

### 2. Make Scripts Executable
```bash
chmod +x scripts/*.sh
```

## Environment Configuration

### 1. Choose Environment

The project supports three environments:
- **dev**: Development environment with minimal resources
- **staging**: Staging environment with moderate resources
- **prod**: Production environment with full features

### 2. Customize Configuration

Edit the appropriate environment file:

#### Development Environment
```bash
vim terraform/environments/dev/terraform.tfvars
```

#### Production Environment
```bash
vim terraform/environments/prod/terraform.tfvars
```

### 3. Key Configuration Parameters

```hcl
# Basic Settings
aws_region   = "eu-central-1"
environment  = "dev"
cluster_name = "eks-dev-cluster"

# VPC Configuration
vpc_cidr               = "10.0.0.0/16"
private_subnet_cidrs   = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
public_subnet_cidrs    = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

# EKS Configuration
kubernetes_version = "1.29"

# Node Groups
node_groups = {
  main = {
    instance_types = ["t3.medium"]
    capacity_type  = "ON_DEMAND"
    min_size      = 1
    max_size      = 5
    desired_size  = 3
    disk_size     = 20
    labels = {
      role = "worker"
    }
    taints = []
  }
}

# Features
enable_monitoring                    = false
enable_cluster_autoscaler           = true
enable_aws_load_balancer_controller = true
enable_ebs_csi_driver               = true
```

## Deployment Process

### Method 1: Using Deployment Script (Recommended)

#### Deploy Development Environment
```bash
./scripts/deploy.sh -e dev
```

#### Deploy with Auto-Approval
```bash
./scripts/deploy.sh -e dev -a
```

#### Plan Only (No Deployment)
```bash
./scripts/deploy.sh -e dev -p
```

### Method 2: Manual Terraform Commands

#### Initialize Terraform
```bash
cd terraform
terraform init
```

#### Create and Select Workspace
```bash
terraform workspace new dev
terraform workspace select dev
```

#### Plan Deployment
```bash
terraform plan -var-file="environments/dev/terraform.tfvars"
```

#### Apply Configuration
```bash
terraform apply -var-file="environments/dev/terraform.tfvars"
```

## Post-Deployment

### 1. Update kubeconfig
```bash
aws eks update-kubeconfig --region eu-central-1 --name eks-dev-cluster
```

### 2. Verify Cluster
```bash
# Check nodes
kubectl get nodes

# Check system pods
kubectl get pods -n kube-system

# Check all namespaces
kubectl get pods --all-namespaces
```

### 3. Deploy Sample Application
```bash
kubectl apply -f examples/nginx-deployment.yaml
```

### 4. Check Application
```bash
# Check deployment
kubectl get deployments

# Check services
kubectl get services

# Get LoadBalancer URL
kubectl get svc nginx-service
```

## Advanced Deployment Options

### 1. Multi-Node Group Configuration

```hcl
node_groups = {
  # General purpose nodes
  main = {
    instance_types = ["t3.large"]
    capacity_type  = "ON_DEMAND"
    min_size      = 2
    max_size      = 10
    desired_size  = 4
    disk_size     = 50
    labels = {
      role = "general"
    }
    taints = []
  }

  # Spot instances for cost optimization
  spot = {
    instance_types = ["t3.medium", "t3.large"]
    capacity_type  = "SPOT"
    min_size      = 0
    max_size      = 5
    desired_size  = 2
    disk_size     = 30
    labels = {
      role = "spot"
    }
    taints = [
      {
        key    = "spot"
        value  = "true"
        effect = "NO_SCHEDULE"
      }
    ]
  }

  # GPU nodes for ML workloads
  gpu = {
    instance_types = ["g4dn.xlarge"]
    capacity_type  = "ON_DEMAND"
    min_size      = 0
    max_size      = 2
    desired_size  = 0
    disk_size     = 100
    labels = {
      role = "gpu"
      "nvidia.com/gpu" = "true"
    }
    taints = [
      {
        key    = "nvidia.com/gpu"
        value  = "true"
        effect = "NO_SCHEDULE"
      }
    ]
  }
}
```

### 2. Enable Monitoring Stack

```hcl
enable_monitoring = true
```

This will deploy:
- Prometheus for metrics collection
- Grafana for visualization
- AlertManager for alerting
- Metrics Server for resource metrics

### 3. Custom VPC Configuration

```hcl
# Custom CIDR blocks
vpc_cidr               = "172.16.0.0/16"
private_subnet_cidrs   = ["172.16.1.0/24", "172.16.2.0/24", "172.16.3.0/24"]
public_subnet_cidrs    = ["172.16.101.0/24", "172.16.102.0/24", "172.16.103.0/24"]

# Custom availability zones
availability_zones = ["eu-central-1a", "eu-central-1b", "eu-central-1c"]
```

## Deployment Validation

### 1. Infrastructure Validation
```bash
# Check Terraform state
terraform show

# Validate resources in AWS Console
aws eks describe-cluster --name eks-dev-cluster --region eu-central-1
```

### 2. Kubernetes Validation
```bash
# Check cluster info
kubectl cluster-info

# Check node status
kubectl get nodes -o wide

# Check system components
kubectl get componentstatuses
```

### 3. Networking Validation
```bash
# Check VPC
aws ec2 describe-vpcs --filters "Name=tag:Name,Values=eks-dev-cluster-vpc"

# Check subnets
aws ec2 describe-subnets --filters "Name=tag:kubernetes.io/cluster/eks-dev-cluster,Values=owned"

# Check security groups
aws ec2 describe-security-groups --filters "Name=tag:kubernetes.io/cluster/eks-dev-cluster,Values=owned"
```

## Troubleshooting

### Common Issues

#### 1. Terraform Init Fails
```bash
# Clear Terraform cache
rm -rf .terraform
rm .terraform.lock.hcl

# Re-initialize
terraform init
```

#### 2. AWS Permissions Success
```bash
# Check current identity
aws sts get-caller-identity

# Verify permissions
aws iam get-user
aws iam list-attached-user-policies --user-name YOUR_USERNAME
```

#### 3. Cluster Creation Timeout
```bash
# Check CloudFormation events
aws cloudformation describe-stack-events --stack-name eksctl-CLUSTER_NAME-cluster

# Check EKS cluster status
aws eks describe-cluster --name CLUSTER_NAME --region REGION
```

#### 4. Node Group Issues
```bash
# Check node group status
aws eks describe-nodegroup --cluster-name CLUSTER_NAME --nodegroup-name NODEGROUP_NAME

# Check Auto Scaling Group
aws autoscaling describe-auto-scaling-groups
```

#### 5. kubectl Access Issues
```bash
# Update kubeconfig
aws eks update-kubeconfig --region REGION --name CLUSTER_NAME

# Check kubeconfig
kubectl config current-context
kubectl config view
```

### Logs and Debugging

#### Terraform Debug
```bash
export TF_LOG=DEBUG
terraform apply -var-file="environments/dev/terraform.tfvars"
```

#### EKS Cluster Logs
```bash
# Enable cluster logging
aws eks update-cluster-config \
  --region REGION \
  --name CLUSTER_NAME \
  --logging '{"enable":[{"types":["api","audit","authenticator","controllerManager","scheduler"]}]}'

# View logs in CloudWatch
aws logs describe-log-groups --log-group-name-prefix /aws/eks/CLUSTER_NAME
```

#### Node Debugging
```bash
# SSH to nodes (if enabled)
kubectl get nodes -o wide

# Check node logs
kubectl describe node NODE_NAME

# Check system pods
kubectl get pods -n kube-system
kubectl describe pod POD_NAME -n kube-system
```

## Best Practices

### 1. State Management
- Use remote state backend (S3 + DynamoDB)
- Enable state locking
- Use separate state files per environment

### 2. Security
- Use least privilege IAM policies
- Enable encryption at rest
- Use private subnets for worker nodes
- Regularly update Kubernetes version

### 3. Cost Optimization
- Use Spot instances for non-critical workloads
- Right-size your instances
- Enable cluster autoscaler
- Monitor resource usage

### 4. Monitoring
- Enable CloudWatch logging
- Deploy monitoring stack
- Set up alerting
- Monitor costs

## Next Steps

After successful deployment:

1. [Configure monitoring and alerting](MONITORING.md)
2. [Set up CI/CD pipelines](CICD.md)
3. [Deploy applications](APPLICATIONS.md)
4. [Configure backup and disaster recovery](BACKUP.md)