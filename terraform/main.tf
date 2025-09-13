terraform {
  required_version = ">= 1.5"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.23"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.11"
    }
  }
}

provider "aws" {
  region = var.aws_region
  
  default_tags {
    tags = {
      Project     = "aws-eks-k8s-terraform"
      Environment = var.environment
      ManagedBy   = "terraform"
    }
  }
}

data "aws_eks_cluster" "cluster" {
  name = module.eks.cluster_name
  depends_on = [module.eks]
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.eks.cluster_name
  depends_on = [module.eks]
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.cluster.token
}

provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.cluster.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.cluster.token
  }
}

# VPC Module
module "vpc" {
  source = "./modules/vpc"
  
  cluster_name = var.cluster_name
  vpc_cidr     = var.vpc_cidr
  environment  = var.environment
  
  availability_zones    = var.availability_zones
  private_subnet_cidrs  = var.private_subnet_cidrs
  public_subnet_cidrs   = var.public_subnet_cidrs
}

# EKS Module
module "eks" {
  source = "./modules/eks"
  
  cluster_name       = var.cluster_name
  kubernetes_version = var.kubernetes_version
  environment        = var.environment
  
  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids
  public_subnet_ids  = module.vpc.public_subnet_ids
  
  node_groups = var.node_groups
  
  depends_on = [module.vpc]
}

# Security Module
module "security" {
  source = "./modules/security"
  
  cluster_name = var.cluster_name
  environment  = var.environment
  
  cluster_oidc_issuer_url = module.eks.cluster_oidc_issuer_url
  
  depends_on = [module.eks]
}

# Monitoring Module (Optional)
module "monitoring" {
  source = "./modules/monitoring"
  count  = var.enable_monitoring ? 1 : 0
  
  cluster_name = var.cluster_name
  environment  = var.environment
  
  depends_on = [module.eks, module.security]
}