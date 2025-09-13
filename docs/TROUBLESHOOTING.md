# Troubleshooting Guide

This guide covers common issues and their solutions when working with the AWS EKS Terraform project.

## Table of Contents

- [Prerequisites Issues](#prerequisites-issues)
- [Terraform Issues](#terraform-issues)
- [AWS Issues](#aws-issues)
- [Kubernetes Issues](#kubernetes-issues)
- [Networking Issues](#networking-issues)
- [Monitoring Issues](#monitoring-issues)

## Prerequisites Issues

### AWS CLI Not Configured

**Problem**: `aws sts get-caller-identity` fails
```bash
Unable to locate credentials. You can configure credentials by running "aws configure".
```

**Solution**:
```bash
aws configure
# Enter your AWS Access Key ID, Secret Access Key, and default region
```

### Insufficient IAM Permissions

**Problem**: Terraform fails with permission denied errors
```
Error: AccessDenied: User is not authorized to perform: eks:CreateCluster
```

**Solution**: Ensure your AWS user/role has these permissions:
- `AmazonEKSClusterPolicy`
- `AmazonEKSWorkerNodePolicy`
- `AmazonEKS_CNI_Policy`
- `AmazonEC2ContainerRegistryReadOnly`
- EC2 Full Access
- IAM Full Access

## Terraform Issues

### Terraform State Lock

**Problem**: Terraform state is locked
```
Error: Error acquiring the state lock
```

**Solution**:
```bash
# Force unlock (use with caution)
terraform force-unlock LOCK_ID

# Or wait for the lock to expire (usually 15 minutes)
```

### Workspace Issues

**Problem**: Wrong workspace selected
```
Error: Workspace "prod" doesn't exist.
```

**Solution**:
```bash
# List available workspaces
terraform workspace list

# Create new workspace
terraform workspace new dev

# Select existing workspace
terraform workspace select dev
```

### Module Source Issues

**Problem**: Module not found
```
Error: Module not installed
```

**Solution**:
```bash
# Reinitialize Terraform
terraform init -upgrade
```

## AWS Issues

### EKS Cluster Creation Timeout

**Problem**: Cluster creation takes too long or times out
```
Error: timeout while waiting for state to become 'ACTIVE'
```

**Solution**:
1. Check AWS service health dashboard
2. Verify subnet configuration
3. Ensure security groups allow required traffic
4. Increase timeout in Terraform configuration

### Node Group Launch Failures

**Problem**: Worker nodes fail to join cluster
```
Error: NodeCreationFailure: Instances failed to join the kubernetes cluster
```

**Solution**:
1. Check instance types are available in selected AZs
2. Verify AMI compatibility with Kubernetes version
3. Check security group rules
4. Ensure subnets have internet access (via NAT Gateway)

### VPC Resource Limits

**Problem**: Cannot create more VPCs
```
Error: VpcLimitExceeded: The maximum number of VPCs has been reached
```

**Solution**:
1. Delete unused VPCs
2. Request limit increase from AWS Support
3. Use existing VPC instead of creating new one

## Kubernetes Issues

### kubectl Access Denied

**Problem**: Cannot access cluster with kubectl
```
error: You must be logged in to the server (Unauthorized)
```

**Solution**:
```bash
# Update kubeconfig
aws eks update-kubeconfig --region eu-central-1 --name your-cluster-name

# Verify AWS credentials
aws sts get-caller-identity

# Check cluster status
aws eks describe-cluster --name your-cluster-name
```

### Pods Stuck in Pending

**Problem**: Pods remain in Pending state
```
kubectl get pods
NAME                     READY   STATUS    RESTARTS   AGE
nginx-7d8b49557f-xyz     0/1     Pending   0          5m
```

**Solution**:
```bash
# Check node status
kubectl get nodes

# Check pod events
kubectl describe pod nginx-7d8b49557f-xyz

# Check resource requests vs available resources
kubectl top nodes
kubectl top pods
```

### DNS Resolution Issues

**Problem**: Pods cannot resolve DNS names
```
nslookup: can't resolve 'kubernetes.default'
```

**Solution**:
1. Check CoreDNS pods are running:
```bash
kubectl get pods -n kube-system -l k8s-app=kube-dns
```

2. Restart CoreDNS if needed:
```bash
kubectl rollout restart deployment/coredns -n kube-system
```

## Networking Issues

### Load Balancer Not Accessible

**Problem**: LoadBalancer service gets no external IP
```
kubectl get svc
NAME         TYPE           CLUSTER-IP     EXTERNAL-IP   PORT(S)
nginx-svc    LoadBalancer   10.100.1.123   <pending>     80:32000/TCP
```

**Solution**:
1. Check AWS Load Balancer Controller is installed
2. Verify security groups allow traffic
3. Check subnet tags for load balancer discovery

### Inter-Pod Communication Issues

**Problem**: Pods cannot communicate with each other

**Solution**:
1. Check security groups allow pod-to-pod traffic
2. Verify VPC CNI plugin is working:
```bash
kubectl get pods -n kube-system -l k8s-app=aws-node
```

3. Check network policies if using them

## Monitoring Issues

### Prometheus Not Scraping Metrics

**Problem**: Prometheus shows targets as down

**Solution**:
1. Check Prometheus configuration:
```bash
kubectl get configmap prometheus-config -n monitoring -o yaml
```

2. Verify service discovery is working
3. Check network policies and security groups

### Grafana Dashboard Not Loading

**Problem**: Grafana shows "No data" or connection errors

**Solution**:
1. Check Grafana data source configuration
2. Verify Prometheus is accessible from Grafana pod
3. Check Grafana logs:
```bash
kubectl logs -n monitoring deployment/grafana
```

## Performance Issues

### High Resource Usage

**Problem**: Nodes running out of CPU/memory

**Solution**:
1. Check resource requests and limits:
```bash
kubectl describe nodes
kubectl top nodes
kubectl top pods --all-namespaces
```

2. Scale cluster if needed:
```bash
# Update node group desired capacity
aws eks update-nodegroup-config --cluster-name your-cluster --nodegroup-name main --scaling-config desiredSize=5
```

### Slow Pod Startup

**Problem**: Pods take long time to start

**Solution**:
1. Check image pull times
2. Use smaller base images
3. Implement image caching
4. Check resource constraints

## Cleanup Issues

### Resources Not Deleted

**Problem**: Terraform destroy fails to delete all resources

**Solution**:
1. Delete LoadBalancer services first:
```bash
kubectl delete svc --all --all-namespaces --timeout=60s
```

2. Delete PersistentVolumeClaims:
```bash
kubectl delete pvc --all --all-namespaces --timeout=60s
```

3. Run destroy again:
```bash
terraform destroy -var-file="environments/dev/terraform.tfvars"
```

### Stuck Finalizers

**Problem**: Resources stuck in "Terminating" state

**Solution**:
```bash
# Remove finalizers (use with caution)
kubectl patch pvc pvc-name -p '{"metadata":{"finalizers":null}}'
```

## Getting Help

If you're still experiencing issues:

1. Check the [AWS EKS Troubleshooting Guide](https://docs.aws.amazon.com/eks/latest/userguide/troubleshooting.html)
2. Review [Terraform AWS Provider Issues](https://github.com/hashicorp/terraform-provider-aws/issues)
3. Search [Kubernetes Issues](https://github.com/kubernetes/kubernetes/issues)
4. Open an issue in this repository with:
   - Error messages
   - Terraform version
   - AWS CLI version
   - kubectl version
   - Steps to reproduce