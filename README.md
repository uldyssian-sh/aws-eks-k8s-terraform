# AWS EKS Kubernetes Terraform

🚀 **Production-ready Terraform modules for deploying Amazon EKS clusters with best practices, security, and monitoring built-in.**

**Author**: LT - [GitHub Profile](https://github.com/uldyssian-sh)

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Terraform](https://img.shields.io/badge/Terraform-1.5+-blue.svg)](https://www.terraform.io/)
[![AWS](https://img.shields.io/badge/AWS-EKS-orange.svg)](https://aws.amazon.com/eks/)
[![Kubernetes](https://img.shields.io/badge/Kubernetes-1.29-blue.svg)](https://kubernetes.io/)

## ✨ Features

- 🏗️ **Modular Architecture** - Reusable Terraform modules for VPC, EKS, Security, and Monitoring
- ⚡ **Multi-Environment Support** - Separate configurations for dev, staging, and production
- 🛡️ **Security Best Practices** - IAM roles with least privilege, encryption at rest, network security
- 🔄 **Auto-Scaling** - Cluster Autoscaler and Horizontal Pod Autoscaler ready
- 🌐 **Load Balancing** - AWS Load Balancer Controller for advanced ingress
- 📊 **Monitoring Stack** - Optional Prometheus, Grafana, and AlertManager
- 🧹 **Easy Cleanup** - Automated scripts for safe resource destruction
- 📋 **Comprehensive Documentation** - Detailed guides and examples

## 🏗️ Architecture

![AWS EKS Architecture](docs/aws_eks_kubernetes_terraform_architecture.png)

### High Availability Multi-AZ Design

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│                              AWS Account (eu-central-1)                        │
├─────────────────────────────────────────────────────────────────────────────────┤
│                                Internet Gateway                                 │
├─────────────────────────────────────────────────────────────────────────────────┤
│  ┌─────────────────┬─────────────────┬─────────────────────────────────────┐    │
│  │   AZ-A          │   AZ-B          │   AZ-C                              │    │
│  │ eu-central-1a   │ eu-central-1b   │ eu-central-1c                       │    │
│  ├─────────────────┼─────────────────┼─────────────────────────────────────┤    │
│  │ Public Subnet   │ Public Subnet   │ Public Subnet                       │    │
│  │ 10.0.101.0/24   │ 10.0.102.0/24   │ 10.0.103.0/24                       │    │
│  │ ┌─────────────┐ │ ┌─────────────┐ │ ┌─────────────┐                     │    │
│  │ │ NAT Gateway │ │ │ NAT Gateway │ │ │ NAT Gateway │                     │    │
│  │ │ + EIP       │ │ │ + EIP       │ │ │ + EIP       │                     │    │
│  │ └─────────────┘ │ └─────────────┘ │ └─────────────┘                     │    │
│  ├─────────────────┼─────────────────┼─────────────────────────────────────┤    │
│  │ Private Subnet  │ Private Subnet  │ Private Subnet                      │    │
│  │ 10.0.1.0/24     │ 10.0.2.0/24     │ 10.0.3.0/24                         │    │
│  │ ┌─────────────┐ │ ┌─────────────┐ │ ┌─────────────┐                     │    │
│  │ │ EKS Nodes   │ │ │ EKS Nodes   │ │ │ EKS Nodes   │                     │    │
│  │ │ Auto Scaling│ │ │ Auto Scaling│ │ │ Auto Scaling│                     │    │
│  │ │ Encrypted   │ │ │ Encrypted   │ │ │ Encrypted   │                     │    │
│  │ └─────────────┘ │ └─────────────┘ │ └─────────────┘                     │    │
│  └─────────────────┴─────────────────┴─────────────────────────────────────┘    │
│                                                                                 │
│  ┌─────────────────────────────────────────────────────────────────────────┐    │
│  │                        EKS Control Plane                               │    │
│  │  • Kubernetes 1.29 • OIDC Provider • Encryption at Rest              │    │
│  │  • Multi-AZ HA     • CloudWatch Logs • Security Groups               │    │
│  └─────────────────────────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────────────────────────┘
```

### Key Architecture Features

- **🌐 Multi-AZ High Availability**: 3 Availability Zones with dedicated NAT Gateways
- **🔒 Security**: Private subnets for worker nodes, encrypted EBS volumes, KMS encryption
- **⚡ Auto Scaling**: Cluster Autoscaler and Horizontal Pod Autoscaler
- **🛡️ Network Security**: Security Groups, NACLs, and VPC Flow Logs
- **📊 Monitoring**: CloudWatch integration with optional Prometheus stack

## 📋 Prerequisites

### Required Tools

| Tool | Version | Installation |
|------|---------|-------------|
| **Terraform** | ≥ 1.5 | [Download](https://www.terraform.io/downloads) |
| **AWS CLI** | ≥ 2.0 | [Install Guide](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html) |
| **kubectl** | ≥ 1.28 | [Install Guide](https://kubernetes.io/docs/tasks/tools/) |
| **Helm** | ≥ 3.12 | [Install Guide](https://helm.sh/docs/intro/install/) |

### AWS Configuration

```bash
# Configure AWS credentials
aws configure
# Enter your AWS Access Key ID, Secret Access Key, and default region

# Verify configuration
aws sts get-caller-identity
```

### Required AWS Permissions

Your AWS user/role needs the following permissions:
- `AmazonEKSClusterPolicy`
- `AmazonEKSWorkerNodePolicy`
- `AmazonEKS_CNI_Policy`
- `AmazonEC2ContainerRegistryReadOnly`
- EC2 Full Access (VPC, subnets, security groups)
- IAM Full Access (create/manage service roles)

## 🚀 Quick Start

### 1. Clone Repository

```bash
git clone https://github.com/uldyssian-sh/aws-eks-k8s-terraform.git
cd aws-eks-k8s-terraform
```

### 2. One-Click Deploy

```bash
# Deploy dev environment (one command)
./scripts/one-click.sh deploy dev

# Deploy production
./scripts/one-click.sh deploy prod

# Destroy environment
./scripts/one-click.sh destroy dev
```

**Alternative commands:**
```bash
# Quick deploy only
./scripts/quick-deploy.sh dev

# Quick destroy only  
./scripts/quick-destroy.sh dev
```

**What gets deployed:**
- VPC with 3 AZs (eu-central-1a, eu-central-1b, eu-central-1c)
- 3 Public subnets with NAT Gateways for high availability
- 3 Private subnets for EKS worker nodes
- EKS cluster with managed node groups across all AZs
- Security roles and policies with least privilege access

**Execution time:** ~15-20 minutes

### 3. Verify Deployment

```bash
# Check cluster status
kubectl get nodes

# Check system pods
kubectl get pods -n kube-system

# Check all namespaces
kubectl get pods --all-namespaces
```

### 4. Deploy Sample Application

```bash
# Deploy nginx example
kubectl apply -f examples/nginx-deployment.yaml

# Check deployment
kubectl get deployments
kubectl get services
```

## 🔧 Configuration

### Environment-Specific Configurations

The project supports multiple environments with separate configurations:

- **Development**: `terraform/environments/dev/terraform.tfvars`
- **Staging**: `terraform/environments/staging/terraform.tfvars`
- **Production**: `terraform/environments/prod/terraform.tfvars`

### Key Configuration Options

```hcl
# Basic Configuration
aws_region         = "eu-central-1"
environment        = "dev"
cluster_name       = "eks-dev-cluster"
kubernetes_version = "1.29"

# VPC Configuration
vpc_cidr             = "10.0.0.0/16"
private_subnet_cidrs = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
public_subnet_cidrs  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

# Node Groups
node_groups = {
  main = {
    instance_types = ["t3.medium"]
    capacity_type  = "ON_DEMAND"
    min_size      = 1
    max_size      = 5
    desired_size  = 3
    disk_size     = 20
  }
}

# Features
enable_monitoring                    = false
enable_cluster_autoscaler           = true
enable_aws_load_balancer_controller = true
enable_ebs_csi_driver               = true
```

## 📁 Project Structure

```
aws-eks-k8s-terraform/
├── terraform/
│   ├── main.tf                     # Main Terraform configuration
│   ├── variables.tf                # Input variables
│   ├── outputs.tf                  # Output values
│   ├── modules/
│   │   ├── vpc/                    # VPC module
│   │   ├── eks/                    # EKS module
│   │   ├── security/               # Security (IAM) module
│   │   └── monitoring/             # Monitoring module
│   └── environments/
│       ├── dev/                    # Development configuration
│       ├── staging/                # Staging configuration
│       └── prod/                   # Production configuration
├── scripts/
│   ├── deploy.sh                   # Deployment script
│   └── destroy.sh                  # Destruction script
├── examples/
│   └── nginx-deployment.yaml       # Sample Kubernetes manifests
├── docs/
│   ├── DEPLOYMENT.md               # Deployment guide
│   ├── SECURITY.md                 # Security best practices
│   └── TROUBLESHOOTING.md          # Troubleshooting guide
└── README.md                       # This file
```

## 🛠️ Advanced Usage

### Custom Node Groups

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
}
```

### Enable Monitoring Stack

```hcl
enable_monitoring = true
```

This deploys:
- **Prometheus** - Metrics collection and storage
- **Grafana** - Visualization dashboards (admin/admin123)
- **AlertManager** - Alert routing and management
- **Metrics Server** - Resource metrics API

### Manual Terraform Commands

```bash
cd terraform

# Initialize
terraform init

# Create workspace
terraform workspace new dev
terraform workspace select dev

# Plan
terraform plan -var-file="environments/dev/terraform.tfvars"

# Apply
terraform apply -var-file="environments/dev/terraform.tfvars"

# Destroy
terraform destroy -var-file="environments/dev/terraform.tfvars"
```

## 🧹 Cleanup

### Destroy Environment

```bash
# Interactive destruction
./scripts/destroy.sh -e dev

# Auto-approved destruction
./scripts/destroy.sh -e dev -a

# Force destruction (no confirmation)
./scripts/destroy.sh -e dev -f
```

### Manual Cleanup

If automated cleanup fails, manually remove:

1. **LoadBalancer Services**: `kubectl delete svc --all --all-namespaces`
2. **PersistentVolumeClaims**: `kubectl delete pvc --all --all-namespaces`
3. **Terraform Resources**: `terraform destroy`

## 📊 Monitoring and Observability

### Access Grafana Dashboard

```bash
# Get Grafana service
kubectl get svc -n monitoring

# Port forward to access locally
kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80

# Access at http://localhost:3000
# Username: admin
# Password: <secure-password>
```

### Useful Monitoring Commands

```bash
# Check cluster metrics
kubectl top nodes
kubectl top pods --all-namespaces

# Check Prometheus targets
kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090

# Check AlertManager
kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-alertmanager 9093:9093
```

## 🔒 Security Best Practices

- **Encryption**: All EKS secrets encrypted at rest using AWS KMS
- **Network Security**: Private subnets for worker nodes, security groups with minimal access
- **IAM**: Least privilege access with service-specific IAM roles
- **RBAC**: Kubernetes RBAC enabled by default
- **Updates**: Regular security updates for EKS add-ons

## 🐛 Troubleshooting

### Common Issues

**1. Insufficient IAM Permissions**
```bash
# Check your AWS identity
aws sts get-caller-identity

# Verify permissions
aws iam get-user
```

**2. Terraform State Issues**
```bash
# List workspaces
terraform workspace list

# Select correct workspace
terraform workspace select dev
```

**3. Cluster Access Issues**
```bash
# Update kubeconfig
aws eks update-kubeconfig --region eu-central-1 --name your-cluster-name

# Verify access
kubectl get nodes
```

**4. Node Group Issues**
```bash
# Check node group status
aws eks describe-nodegroup --cluster-name your-cluster --nodegroup-name main

# Check nodes
kubectl describe nodes
```

## 📚 Documentation

- [Deployment Guide](docs/DEPLOYMENT.md) - Detailed deployment instructions
- [Security Guide](docs/SECURITY.md) - Security best practices and configurations
- [Troubleshooting Guide](docs/TROUBLESHOOTING.md) - Common issues and solutions

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🔗 Useful Links

- [AWS EKS Documentation](https://docs.aws.amazon.com/eks/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [Helm Documentation](https://helm.sh/docs/)

## 📈 Cost Optimization

### Development Environment
- Uses `t3.medium` instances
- Minimal node count (2-3 nodes)
- No monitoring stack by default
- Spot instances available

### Production Environment
- Uses `t3.large` instances for stability
- Higher node count for availability
- Full monitoring stack enabled
- Mixed instance types for cost optimization

---

⚠️ **Important**: This infrastructure creates AWS resources that incur costs. Always run the destroy scripts when done testing to avoid unexpected charges.