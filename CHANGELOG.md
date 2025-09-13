# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Initial project setup with Terraform modules
- Multi-environment support (dev, staging, prod)
- Automated deployment and destruction scripts
- Comprehensive documentation and examples

### Changed
- Updated to Kubernetes 1.29
- Improved security configurations

### Fixed
- Resource cleanup issues in destroy scripts

## [1.0.0] - 2024-01-15

### Added
- Complete EKS cluster deployment with Terraform
- VPC module with multi-AZ support
- Security module with IAM roles and policies
- Optional monitoring stack with Prometheus and Grafana
- Automated scripts for deployment and cleanup
- Comprehensive documentation