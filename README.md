# EKS Terraform Infrastructure Project

This repository contains Terraform configurations to deploy an Amazon EKS (Elastic Kubernetes Service) cluster with associated networking and compute resources.

## Prerequisites

- Terraform >= 1.7.0
- AWS CLI configured
- S3 bucket for Terraform state (`lroquec-tf`)

## Infrastructure Components

### VPC and Networking
- Custom VPC with public and private subnets
- NAT Gateway for private subnet connectivity
- Database subnets
- Proper tagging for EKS integration

### EKS Cluster
- EKS cluster with version 1.30
- Private and public endpoint access
- Enabled cluster logging
- EBS CSI driver addon
- OIDC provider configuration

### Node Groups
- Managed node group using t4g.medium instances
- Autoscaling configuration:
  - Min size: 1
  - Desired size: 2
  - Max size: 3
- Nodes deployed in private subnets

### IAM Configuration
- EKS cluster role with necessary policies
- Worker node IAM role with required permissions
- Integration with various AWS services through IAM policies:
  - EBS CSI Driver
  - Load Balancer Controller
  - VPC Resource Controller

## Variables

Key variables that can be customized:

```hcl
project_name         = "your-project-name"
vpc_cidr            = "10.0.0.0/16"
EKSClusterName      = "devEKS"
k8sVersion          = "1.30"
```

## Usage

1. Initialize Terraform:
```bash
terraform init
```

2. Review planned changes:
```bash
terraform plan
```

3. Apply the configuration:
```bash
terraform get
terraform apply
```

## Outputs

- `vpc_id`: The ID of the created VPC
- `cluster_id`: The name/id of the EKS cluster
- `cluster_endpoint`: The endpoint for your EKS Kubernetes API

## Tags

Resources are tagged with:
- Environment: dev
- Managed by: Terraform
- CreatedBy: lroquec
- Owner: DevOps Team

## Notes

- The project uses S3 backend for state management
- Node group scaling is ignored in Terraform to allow external management
- The cluster supports both private and public endpoint access
- Database subnets are provisioned for potential RDS integration