# Production Environment Configuration
aws_region   = "eu-central-1"
environment  = "prod"
cluster_name = "eks-prod-cluster"

# VPC Configuration
vpc_cidr               = "10.1.0.0/16"
availability_zones     = ["eu-central-1a", "eu-central-1b", "eu-central-1c"]
private_subnet_cidrs   = ["10.1.1.0/24", "10.1.2.0/24", "10.1.3.0/24"]
public_subnet_cidrs    = ["10.1.101.0/24", "10.1.102.0/24", "10.1.103.0/24"]

# EKS Configuration
kubernetes_version = "1.29"

# Node Groups Configuration
node_groups = {
  main = {
    instance_types = ["t3.large"]
    capacity_type  = "ON_DEMAND"
    min_size      = 3
    max_size      = 10
    desired_size  = 5
    disk_size     = 50
    labels = {
      role        = "worker"
      environment = "prod"
    }
    taints = []
  }
  
  spot = {
    instance_types = ["t3.medium", "t3.large"]
    capacity_type  = "SPOT"
    min_size      = 0
    max_size      = 5
    desired_size  = 2
    disk_size     = 30
    labels = {
      role        = "spot-worker"
      environment = "prod"
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
enable_monitoring                    = true
enable_cluster_autoscaler           = true
enable_aws_load_balancer_controller = true
enable_ebs_csi_driver               = true

# Additional Tags
tags = {
  Owner       = "ProdTeam"
  CostCenter  = "Production"
  Backup      = "Required"
}