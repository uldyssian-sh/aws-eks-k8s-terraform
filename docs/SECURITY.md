# Security Guide

This document outlines the security best practices and configurations implemented in this AWS EKS Terraform project.

## Table of Contents

- [Security Architecture](#security-architecture)
- [Network Security](#network-security)
- [Identity and Access Management](#identity-and-access-management)
- [Encryption](#encryption)
- [Monitoring and Logging](#monitoring-and-logging)
- [Compliance](#compliance)
- [Security Checklist](#security-checklist)
- [Incident Response](#incident-response)

## Security Architecture

### Defense in Depth

This project implements multiple layers of security:

```
┌─────────────────────────────────────────────────────────────┐
│                    Internet Gateway                         │
├─────────────────────────────────────────────────────────────┤
│                    Public Subnets                          │
│  ┌─────────────────────────────────────────────────────┐    │
│  │              Load Balancers                         │    │
│  │              NAT Gateways                           │    │
│  └─────────────────────────────────────────────────────┘    │
├─────────────────────────────────────────────────────────────┤
│                    Private Subnets                         │
│  ┌─────────────────────────────────────────────────────┐    │
│  │              EKS Worker Nodes                       │    │
│  │              • No public IPs                       │    │
│  │              • Security Groups                      │    │
│  │              • Network ACLs                         │    │
│  └─────────────────────────────────────────────────────┘    │
├─────────────────────────────────────────────────────────────┤
│                    EKS Control Plane                       │
│  ┌─────────────────────────────────────────────────────┐    │
│  │              • Managed by AWS                       │    │
│  │              • Encrypted etcd                       │    │
│  │              • API Server Logging                   │    │
│  └─────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────┘
```

### Security Principles

1. **Least Privilege Access**: IAM roles and policies follow the principle of least privilege
2. **Network Isolation**: Worker nodes in private subnets with no direct internet access
3. **Encryption**: Data encrypted at rest and in transit
4. **Monitoring**: Comprehensive logging and monitoring enabled
5. **Compliance**: Follows AWS security best practices and industry standards

## Network Security

### VPC Configuration

#### Private Subnets
- **Worker nodes** deployed in private subnets only
- **No public IP addresses** assigned to worker nodes
- **Outbound internet access** through NAT Gateways only

```hcl
resource "aws_subnet" "private" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.private_subnet_cidrs[count.index]
  availability_zone       = local.azs[count.index]
  map_public_ip_on_launch = false  # Security: No public IPs
}
```

#### Security Groups

##### EKS Cluster Security Group
```hcl
resource "aws_security_group" "cluster" {
  name_prefix = "${var.cluster_name}-cluster-"
  vpc_id      = var.vpc_id

  # HTTPS access for API server
  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Restrict this in production
  }

  # All outbound traffic allowed
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
```

##### Worker Node Security Group
```hcl
resource "aws_security_group" "node" {
  name_prefix = "${var.cluster_name}-node-"
  vpc_id      = var.vpc_id

  # Allow all traffic from cluster security group
  ingress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    security_groups = [aws_security_group.cluster.id]
  }

  # Allow all traffic between worker nodes
  ingress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    self      = true
  }

  # All outbound traffic allowed
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
```

### Network Hardening Recommendations

#### Production Environment
```hcl
# Restrict API server access to specific IP ranges
resource "aws_security_group_rule" "cluster_ingress_workstation" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["203.0.113.0/24"]  # Your office IP range
  security_group_id = aws_security_group.cluster.id
}

# Enable VPC Flow Logs
resource "aws_flow_log" "vpc" {
  iam_role_arn    = aws_iam_role.flow_log.arn
  log_destination = aws_cloudwatch_log_group.vpc.arn
  traffic_type    = "ALL"
  vpc_id          = aws_vpc.main.id
}
```

## Identity and Access Management

### IAM Roles and Policies

#### EKS Cluster Service Role
```hcl
resource "aws_iam_role" "cluster" {
  name = "${var.cluster_name}-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "cluster_AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.cluster.name
}
```

#### Worker Node IAM Role
```hcl
resource "aws_iam_role" "node" {
  name = "${var.cluster_name}-node-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

# Required policies for worker nodes
resource "aws_iam_role_policy_attachment" "node_AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.node.name
}

resource "aws_iam_role_policy_attachment" "node_AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.node.name
}

resource "aws_iam_role_policy_attachment" "node_AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.node.name
}
```

### Service Account IAM Roles (IRSA)

#### AWS Load Balancer Controller
```hcl
data "aws_iam_policy_document" "aws_load_balancer_controller_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    condition {
      test     = "StringEquals"
      variable = "${local.oidc_provider_arn}:sub"
      values   = ["system:serviceaccount:kube-system:aws-load-balancer-controller"]
    }

    condition {
      test     = "StringEquals"
      variable = "${local.oidc_provider_arn}:aud"
      values   = ["sts.amazonaws.com"]
    }

    principals {
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/${local.oidc_provider_arn}"]
      type        = "Federated"
    }
  }
}
```

### RBAC Configuration

#### Kubernetes RBAC
```yaml
# Example: Restrict namespace access
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  namespace: production
  name: pod-reader
rules:
- apiGroups: [""]
  resources: ["pods"]
  verbs: ["get", "watch", "list"]

---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: read-pods
  namespace: production
subjects:
- kind: User
  name: developer
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: Role
  name: pod-reader
  apiGroup: rbac.authorization.k8s.io
```

## Encryption

### Encryption at Rest

#### EKS Secrets Encryption
```hcl
resource "aws_kms_key" "eks" {
  description             = "EKS Secret Encryption Key"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  tags = {
    Name = "${var.cluster_name}-eks-key"
  }
}

resource "aws_eks_cluster" "main" {
  # ... other configuration

  encryption_config {
    provider {
      key_arn = aws_kms_key.eks.arn
    }
    resources = ["secrets"]
  }
}
```

#### EBS Volume Encryption
```hcl
resource "aws_eks_node_group" "main" {
  # ... other configuration

  launch_template {
    name    = aws_launch_template.node.name
    version = aws_launch_template.node.latest_version
  }
}

resource "aws_launch_template" "node" {
  name_prefix = "${var.cluster_name}-node-"

  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_size           = var.disk_size
      volume_type          = "gp3"
      encrypted            = true  # Encrypt EBS volumes
      delete_on_termination = true
    }
  }
}
```

### Encryption in Transit

#### TLS Configuration
- **API Server**: TLS 1.2+ for all communications
- **etcd**: Encrypted communication between nodes
- **Kubelet**: TLS certificates for node authentication

## Monitoring and Logging

### CloudWatch Logging

#### EKS Control Plane Logs
```hcl
resource "aws_eks_cluster" "main" {
  # ... other configuration

  enabled_cluster_log_types = [
    "api",
    "audit",
    "authenticator",
    "controllerManager",
    "scheduler"
  ]
}

resource "aws_cloudwatch_log_group" "cluster" {
  name              = "/aws/eks/${var.cluster_name}/cluster"
  retention_in_days = 7
}
```

#### VPC Flow Logs
```hcl
resource "aws_flow_log" "vpc" {
  iam_role_arn    = aws_iam_role.flow_log.arn
  log_destination = aws_cloudwatch_log_group.vpc.arn
  traffic_type    = "ALL"
  vpc_id          = aws_vpc.main.id
}
```

### Security Monitoring

#### CloudTrail Integration
```hcl
resource "aws_cloudtrail" "security" {
  name           = "${var.cluster_name}-security-trail"
  s3_bucket_name = aws_s3_bucket.cloudtrail.bucket

  event_selector {
    read_write_type                 = "All"
    include_management_events       = true
    exclude_management_event_sources = []

    data_resource {
      type   = "AWS::EKS::Cluster"
      values = ["arn:aws:eks:*:*:cluster/*"]
    }
  }
}
```

## Compliance

### Security Standards

#### CIS Kubernetes Benchmark
- Regular security scans with tools like `kube-bench`
- Automated compliance checking in CI/CD pipeline

#### SOC 2 Compliance
- Audit logging enabled
- Access controls documented
- Regular security assessments

### Compliance Automation

#### Terraform Compliance
```bash
# Run compliance checks
terraform-compliance -f compliance/ -p terraform/

# Security scanning
checkov -d terraform/ --framework terraform
```

#### Kubernetes Compliance
```bash
# CIS Kubernetes Benchmark
kube-bench run --targets node,policies,managedservices

# Pod Security Standards
kubectl apply -f - <<EOF
apiVersion: v1
kind: Namespace
metadata:
  name: secure-namespace
  labels:
    pod-security.kubernetes.io/enforce: restricted
    pod-security.kubernetes.io/audit: restricted
    pod-security.kubernetes.io/warn: restricted
EOF
```

## Security Checklist

### Pre-Deployment

- [ ] Review IAM policies for least privilege
- [ ] Validate network security groups
- [ ] Ensure encryption is enabled
- [ ] Configure logging and monitoring
- [ ] Run security scans (Checkov, etc.)

### Post-Deployment

- [ ] Verify cluster access controls
- [ ] Test network connectivity
- [ ] Validate encryption status
- [ ] Check logging configuration
- [ ] Run compliance scans

### Ongoing Security

- [ ] Regular security updates
- [ ] Monitor security alerts
- [ ] Review access logs
- [ ] Update IAM policies as needed
- [ ] Rotate credentials regularly

## Incident Response

### Security Incident Procedures

#### 1. Detection
- Monitor CloudWatch alerts
- Review security logs
- Automated threat detection

#### 2. Response
```bash
# Isolate compromised nodes
kubectl cordon <node-name>
kubectl drain <node-name> --ignore-daemonsets

# Review audit logs
kubectl logs -n kube-system <pod-name>

# Check for unauthorized access
aws cloudtrail lookup-events --lookup-attributes AttributeKey=EventName,AttributeValue=AssumeRole
```

#### 3. Recovery
- Patch vulnerabilities
- Rotate compromised credentials
- Update security policies
- Document lessons learned

### Emergency Contacts

- **Security Team**: security@company.com
- **On-Call Engineer**: +1-555-0123
- **AWS Support**: Enterprise Support Case

## Security Tools and Resources

### Recommended Tools

#### Static Analysis
- **Checkov**: Terraform security scanning
- **tfsec**: Terraform security scanner
- **Terrascan**: Infrastructure as Code security

#### Runtime Security
- **Falco**: Runtime security monitoring
- **Twistlock/Prisma**: Container security
- **Aqua Security**: Cloud native security

#### Compliance
- **kube-bench**: CIS Kubernetes Benchmark
- **kube-hunter**: Kubernetes penetration testing
- **Polaris**: Kubernetes best practices

### Security Resources

- [AWS EKS Security Best Practices](https://aws.github.io/aws-eks-best-practices/security/docs/)
- [CIS Kubernetes Benchmark](https://www.cisecurity.org/benchmark/kubernetes)
- [NIST Cybersecurity Framework](https://www.nist.gov/cyberframework)
- [Kubernetes Security Documentation](https://kubernetes.io/docs/concepts/security/)

## Regular Security Tasks

### Daily
- Monitor security alerts
- Review access logs
- Check for failed authentication attempts

### Weekly
- Review IAM access patterns
- Update security patches
- Scan for vulnerabilities

### Monthly
- Security policy review
- Compliance assessment
- Incident response drill

### Quarterly
- Full security audit
- Penetration testing
- Security training updates

---

**Remember**: Security is an ongoing process, not a one-time setup. Regularly review and update your security posture as threats evolve.