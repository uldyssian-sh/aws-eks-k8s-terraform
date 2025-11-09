# Contributing to AWS EKS Kubernetes Terraform

Thank you for your interest in contributing to this project! This document provides guidelines and information for contributors.

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [Development Process](#development-process)
- [Coding Standards](#coding-standards)
- [Testing](#testing)
- [Documentation](#documentation)
- [Pull Request Process](#pull-request-process)

## Code of Conduct

This project adheres to a code of conduct. By participating, you are expected to uphold this code. Please report unacceptable behavior to the project maintainers.

### Our Standards

- Use welcoming and inclusive language
- Be respectful of differing viewpoints and experiences
- Gracefully accept constructive criticism
- Focus on what is best for the community
- Show empathy towards other community members

## Getting Started

### Prerequisites

1. **Fork the repository** on GitHub
2. **Clone your fork** locally:
   ```bash
   git clone https://github.com/your-username/aws-eks-k8s-terraform.git
   cd aws-eks-k8s-terraform
   ```
3. **Add upstream remote**:
   ```bash
   git remote add upstream https://github.com/original-owner/aws-eks-k8s-terraform.git
   ```

### Development Environment Setup

1. **Install required tools**:
   ```bash
   make check-tools
   make install-tools  # macOS only
   ```

2. **Configure AWS credentials**:
   ```bash
   aws configure
   ```

3. **Verify setup**:
   ```bash
   make validate
   ```

## Development Process

### Branching Strategy

- `main` - Production-ready code
- `develop` - Integration branch for features
- `feature/*` - Feature branches
- `bugfix/*` - Bug fix branches
- `hotfix/*` - Critical fixes for production

### Workflow

1. **Create a feature branch**:
   ```bash
   git checkout -b feature/your-feature-name
   ```

2. **Make your changes** following the coding standards

3. **Test your changes**:
   ```bash
   make test
   make validate
   make security-scan
   ```

4. **Commit your changes**:
   ```bash
   git add .
   git commit -m "feat: add new feature description"
   ```

5. **Push to your fork**:
   ```bash
   git push origin feature/your-feature-name
   ```

6. **Create a Pull Request** on GitHub

## Coding Standards

### Terraform Standards

#### File Organization
- Use consistent file naming: `main.tf`, `variables.tf`, `outputs.tf`
- Group related resources in the same file
- Use modules for reusable components

#### Naming Conventions
```hcl
# Resources: use descriptive names with underscores
resource "aws_vpc" "main" {
  # ...
}

# Variables: use snake_case
variable "cluster_name" {
  # ...
}

# Outputs: use snake_case
output "cluster_endpoint" {
  # ...
}
```

#### Code Style
```hcl
# Use consistent formatting
resource "aws_eks_cluster" "main" {
  name     = var.cluster_name
  role_arn = aws_iam_role.cluster.arn
  version  = var.kubernetes_version

  vpc_config {
    subnet_ids              = concat(var.private_subnet_ids, var.public_subnet_ids)
    endpoint_private_access = true
    endpoint_public_access  = true
  }

  tags = {
    Name = var.cluster_name
  }
}
```

#### Documentation
- Add descriptions to all variables and outputs
- Include validation rules where appropriate
- Use meaningful default values

```hcl
variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z][a-zA-Z0-9-]*$", var.cluster_name))
    error_message = "Cluster name must start with a letter and contain only alphanumeric characters and hyphens."
  }
}
```

### Shell Script Standards

#### Bash Best Practices
```bash
#!/usr/bin/env bash
set -euo pipefail

# Use meaningful variable names
CLUSTER_NAME="eks-dev-cluster"
AWS_REGION="eu-central-1"

# Function naming: use snake_case
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

# Error handling
if ! command -v aws &> /dev/null; then
    print_error "AWS CLI is not installed"
    exit 1
fi
```

### Documentation Standards

#### README Structure
- Clear project description
- Prerequisites and installation
- Usage examples
- Configuration options
- Troubleshooting guide

#### Code Comments
```hcl
# Create VPC for EKS cluster
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true  # Required for EKS
  enable_dns_support   = true  # Required for EKS
}
```

## Testing

### Terraform Testing

#### Validation
```bash
# Format check
terraform fmt -check -recursive

# Validation
terraform validate

# Security scan
checkov -d terraform --framework terraform
```

#### Plan Testing
```bash
# Test all environments
make plan ENV=dev
make plan ENV=staging
make plan ENV=prod
```

### Integration Testing

#### Test Deployment
```bash
# Deploy to test environment
make apply ENV=dev

# Run integration tests
kubectl get nodes
kubectl get pods --all-namespaces

# Clean up
make destroy ENV=dev
```

### Security Testing

#### Static Analysis
```bash
# Run Checkov security scan
make security-scan

# Check for secrets
git-secrets --scan
```

#### Cost Analysis
```bash
# Estimate costs
make cost-estimate ENV=prod
```

## Documentation

### Module Documentation

Each module should include:

1. **README.md** with:
   - Purpose and description
   - Usage examples
   - Input variables table
   - Output values table

2. **Generated documentation**:
   ```bash
   terraform-docs markdown table --output-file README.md .
   ```

### Examples

Provide working examples for:
- Basic deployment
- Advanced configurations
- Multi-environment setup
- Custom node groups

## Pull Request Process

### Before Submitting

1. **Update documentation** if needed
2. **Add tests** for new functionality
3. **Run all checks**:
   ```bash
   make validate
   make test
   make security-scan
   ```
4. **Update CHANGELOG.md** if applicable

### PR Requirements

#### Title Format
Use conventional commit format:
- `feat: add new feature`
- `fix: resolve bug in module`
- `docs: update README`
- `refactor: improve code structure`
- `test: add integration tests`

#### Description Template
```markdown
## Description
Brief description of changes

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Breaking change
- [ ] Documentation update

## Testing
- [ ] Terraform validate passes
- [ ] Security scan passes
- [ ] Integration tests pass
- [ ] Manual testing completed

## Checklist
- [ ] Code follows style guidelines
- [ ] Self-review completed
- [ ] Documentation updated
- [ ] Tests added/updated
```

### Review Process

1. **Automated checks** must pass
2. **Code review** by maintainers
3. **Testing** in development environment
4. **Approval** from at least one maintainer

### Merge Requirements

- All CI checks pass
- At least one approval from maintainer
- No merge conflicts
- Up-to-date with target branch

## Release Process

### Versioning

We use [Semantic Versioning](https://semver.org/):
- `MAJOR.MINOR.PATCH`
- Major: Breaking changes
- Minor: New features (backward compatible)
- Patch: Bug fixes (backward compatible)

### Release Steps

1. **Update version** in relevant files
2. **Update CHANGELOG.md**
3. **Create release tag**:
   ```bash
   git tag -a v1.0.0 -m "Release version 1.0.0"
   git push origin v1.0.0
   ```
4. **Create GitHub release** with release notes

## Getting Help

### Communication Channels

- **GitHub Issues**: Bug reports and feature requests
- **GitHub Discussions**: Questions and general discussion
- **Pull Requests**: Code contributions

### Issue Templates

Use appropriate issue templates:
- Bug Report
- Feature Request
- Documentation Improvement
- Question

### Response Times

- **Bug reports**: 2-3 business days
- **Feature requests**: 1 week
- **Pull requests**: 3-5 business days

## Recognition

Contributors will be recognized in:
- CONTRIBUTORS.md file
- Release notes
- GitHub contributors section

Thank you for contributing to AWS EKS Kubernetes Terraform!# Updated Sun Nov  9 12:50:31 CET 2025
# Updated Sun Nov  9 12:52:07 CET 2025
