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
- EKS cluster with version 1.31
- Public endpoint access
- Enabled cluster logging
- EBS CSI driver addon
- OIDC provider configuration

### Node Groups
- Managed node group using t3.medium instances
- Autoscaling configuration:
  - Min size: 1
  - Desired size: 2
  - Max size: 3
- Nodes deployed in private subnets

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

### VPC Outputs

- **`vpc_id`**  
  - **Description:** The ID of the VPC.  
  - **Value:** Sourced from `module.vpc.vpc_id`.

### EKS Cluster Outputs

- **`cluster_id`**  
  - **Description:** The name or ID of the EKS cluster.  
  - **Value:** Sourced from `module.eks.cluster_id`.

- **`cluster_endpoint`**  
  - **Description:** The endpoint for the EKS Kubernetes API.  
  - **Value:** Sourced from `module.eks.cluster_endpoint`.

- **`cluster_certificate_authority_data`**  
  - **Description:** Certificate-authority-data for the EKS cluster, base64 encoded. This is required for secure communication with the cluster.  
  - **Value:** Sourced from `module.eks.cluster_certificate_authority_data`.

### AWS IAM Open ID Connect Provider Outputs

- **`aws_iam_openid_connect_provider_arn`**  
  - **Description:** The Amazon Resource Name (ARN) for the AWS IAM Open ID Connect (OIDC) provider associated with the EKS cluster.  
  - **Value:** Sourced from `module.eks.oidc_provider_arn`.

- **`aws_iam_openid_connect_provider_extract_from_arn`**  
  - **Description:** The OIDC provider extracted from the ARN.  
  - **Value:** Sourced from `module.eks.oidc_provider`.

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