#!/usr/bin/env python3
"""
Generate AWS EKS Architecture Diagram
"""

from diagrams import Diagram, Cluster, Edge
from diagrams.aws.compute import EKS, EC2
from diagrams.aws.network import VPC, PrivateSubnet, PublicSubnet, InternetGateway, NATGateway, ELB
from diagrams.aws.security import IAM
from diagrams.aws.management import Cloudwatch
from diagrams.aws.storage import EBS
from diagrams.k8s.compute import Pod
from diagrams.k8s.network import Service
from diagrams.onprem.client import Users

with Diagram("AWS EKS Kubernetes Terraform Architecture", show=False, direction="TB"):
    users = Users("Users")
    
    with Cluster("AWS Account"):
        igw = InternetGateway("Internet Gateway")
        
        with Cluster("VPC (10.0.0.0/16)"):
            with Cluster("Availability Zone A"):
                pub_a = PublicSubnet("Public\n10.0.101.0/24")
                prv_a = PrivateSubnet("Private\n10.0.1.0/24")
                nat_a = NATGateway("NAT-A")
                nodes_a = EC2("EKS Nodes")
                
            with Cluster("Availability Zone B"):
                pub_b = PublicSubnet("Public\n10.0.102.0/24")
                prv_b = PrivateSubnet("Private\n10.0.2.0/24")
                nat_b = NATGateway("NAT-B")
                nodes_b = EC2("EKS Nodes")
                
            with Cluster("Availability Zone C"):
                pub_c = PublicSubnet("Public\n10.0.103.0/24")
                prv_c = PrivateSubnet("Private\n10.0.3.0/24")
                nat_c = NATGateway("NAT-C")
                nodes_c = EC2("EKS Nodes")
            
            alb = ELB("Application\nLoad Balancer")
            
            with Cluster("EKS Control Plane"):
                eks = EKS("EKS Cluster")
                
            with Cluster("Kubernetes Workloads"):
                pods = Pod("Application Pods")
                svc = Service("Services")
                
        with Cluster("Security & Monitoring"):
            iam = IAM("IAM Roles\n& Policies")
            cw = Cloudwatch("CloudWatch\nLogs & Metrics")
            ebs = EBS("Encrypted\nEBS Volumes")
    
    # Connections
    users >> igw >> alb
    alb >> [nodes_a, nodes_b, nodes_c]
    
    igw >> [pub_a, pub_b, pub_c]
    pub_a >> nat_a >> prv_a >> nodes_a
    pub_b >> nat_b >> prv_b >> nodes_b
    pub_c >> nat_c >> prv_c >> nodes_c
    
    [nodes_a, nodes_b, nodes_c] >> eks
    eks >> pods >> svc
    
    [nodes_a, nodes_b, nodes_c] >> iam
    [eks, nodes_a, nodes_b, nodes_c] >> cw
    [nodes_a, nodes_b, nodes_c] >> ebs# Updated Sun Nov  9 12:50:31 CET 2025
