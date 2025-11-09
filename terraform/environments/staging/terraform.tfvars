# Staging Environment Configuration
aws_region   = "eu-central-1"
environment  = "staging"
cluster_name = "eks-staging-cluster"

# VPC Configuration
vpc_cidr             = "10.2.0.0/16"
availability_zones   = ["eu-central-1a", "eu-central-1b", "eu-central-1c"]
private_subnet_cidrs = ["10.2.1.0/24", "10.2.2.0/24", "10.2.3.0/24"]
public_subnet_cidrs  = ["10.2.101.0/24", "10.2.102.0/24", "10.2.103.0/24"]

# EKS Configuration
kubernetes_version = "1.29"

# Node Groups Configuration
node_groups = {
  main = {
    instance_types = ["t3.medium"]
    capacity_type  = "ON_DEMAND"
    min_size       = 2
    max_size       = 6
    desired_size   = 3
    disk_size      = 30
    labels = {
      role        = "worker"
      environment = "staging"
    }
    taints = []
  }

  spot = {
    instance_types = ["t3.medium"]
    capacity_type  = "SPOT"
    min_size       = 0
    max_size       = 3
    desired_size   = 1
    disk_size      = 20
    labels = {
      role        = "spot-worker"
      environment = "staging"
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

# Features
enable_monitoring                   = true
enable_cluster_autoscaler           = true
enable_aws_load_balancer_controller = true
enable_ebs_csi_driver               = true

# Additional Tags
tags = {
  Owner      = "StagingTeam"
  CostCenter = "Staging"
  Purpose    = "Testing"
}# Updated Sun Nov  9 12:52:07 CET 2025
# Updated Sun Nov  9 12:56:57 CET 2025
