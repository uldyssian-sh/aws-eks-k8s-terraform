# Development Environment Configuration
aws_region   = "eu-central-1"
environment  = "dev"
cluster_name = "eks-dev-cluster"

# VPC Configuration
vpc_cidr             = "10.0.0.0/16"
availability_zones   = ["eu-central-1a", "eu-central-1b", "eu-central-1c"]
private_subnet_cidrs = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
public_subnet_cidrs  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

# EKS Configuration
kubernetes_version = "1.29"

# Node Groups Configuration
node_groups = {
  main = {
    instance_types = ["t3.medium"]
    capacity_type  = "ON_DEMAND"
    min_size       = 3
    max_size       = 6
    desired_size   = 3
    disk_size      = 20
    labels = {
      role        = "worker"
      environment = "dev"
    }
    taints = []
  }
}

# Features
enable_monitoring                   = false
enable_cluster_autoscaler           = true
enable_aws_load_balancer_controller = true
enable_ebs_csi_driver               = true

# Additional Tags
tags = {
  Owner      = "DevTeam"
  CostCenter = "Development"
