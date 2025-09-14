# Discussion Topics for AWS EKS Kubernetes Terraform

## Infrastructure as Code

**Q: Module composition strategies**
How do you structure Terraform modules for complex EKS deployments? Currently using monolithic approach but considering module decomposition.

**Q: State management at scale**
Managing Terraform state for multiple EKS clusters across environments. Remote state with DynamoDB locking vs Terraform Cloud?

## Kubernetes Configuration

**Q: CNI plugin selection**
Comparing AWS VPC CNI vs Calico for network policies. What factors drive your CNI choice in production environments?

**Q: Ingress controller patterns**
Using ALB Ingress Controller vs NGINX. What's your experience with SSL termination and path-based routing performance?

## Security & Compliance

**Q: Pod Security Standards**
Implementing Pod Security Standards with this Terraform setup. How do you enforce security policies across namespaces?

**Q: Secrets management**
Best practices for managing Kubernetes secrets with Terraform? External Secrets Operator vs AWS Secrets Manager integration?

## Monitoring & Observability

**Q: Prometheus setup**
Anyone deploying Prometheus stack via Terraform alongside EKS? Looking for examples of persistent storage configuration.

**Q: Log aggregation**
Fluentd vs Fluent Bit for log collection. What's your experience with CloudWatch vs external log aggregation?

## Cost Optimization

**Q: Cluster autoscaling tuning**
Fine-tuning cluster autoscaler parameters for cost optimization. What metrics do you monitor for scaling decisions?

**Q: Spot instance strategies**
Running production workloads on spot instances. How do you handle interruptions and maintain SLA requirements?

## CI/CD Integration

**Q: GitOps workflows**
Integrating this Terraform setup with ArgoCD or Flux. What's your approach for managing infrastructure and application deployments?

**Q: Multi-environment promotion**
How do you promote Terraform configurations from dev to staging to production? Looking for pipeline examples.

## Networking & Connectivity

**Q: VPC design patterns**
Multi-AZ networking design for EKS. How do you handle cross-AZ traffic costs and availability zone failures?

**Q: Service mesh integration**
Anyone using Istio or Linkerd with this setup? Performance impact and configuration complexity considerations?

## Troubleshooting

**Q: Node group scaling issues**
Experiencing delays in node provisioning during high load. Any Terraform configuration optimizations for faster scaling?

**Q: DNS resolution problems**
Intermittent DNS issues with CoreDNS. What monitoring and troubleshooting approaches have worked for you?