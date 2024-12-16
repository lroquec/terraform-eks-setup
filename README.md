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

### Project Configuration

- **`project_name`**  
  - **Description:** The name of the project.  
  - **Type:** `string`  

### VPC Configuration

- **`vpc_cidr`**  
  - **Description:** The CIDR block for the VPC.  
  - **Type:** `string`  
  - **Default:** `10.0.0.0/16`  
  - **Validation:** Ensures the provided value is a valid CIDR block.

- **`subnet_config`**  
  - **Description:** Configuration for the VPC subnets, defining CIDR blocks and public/private settings.  
  - **Type:** `map(object)`  
  - **Default:**  
    ```hcl
    {
      subnet1 = {
        cidr_block = "10.0.1.0/24"
        public     = true
      }
      subnet2 = {
        cidr_block = "10.0.2.0/24"
        public     = true
      }
      subnet3 = {
        cidr_block = "10.0.3.0/24"
        public     = false
      }
      subnet4 = {
        cidr_block = "10.0.4.0/24"
        public     = false
      }
    }
    ```  
  - **Validation:** Ensures all `cidr_block` values are valid CIDR blocks.

### EKS Cluster Configuration

- **`eksIAMRole`**  
  - **Description:** IAM Role for the EKS cluster.  
  - **Type:** `string`  
  - **Default:** `devEKSCluster`

- **`EKSClusterName`**  
  - **Description:** Name of the EKS cluster.  
  - **Type:** `string`  
  - **Default:** `devEKS`

- **`k8sVersion`**  
  - **Description:** Kubernetes version for the EKS cluster.  
  - **Type:** `string`  
  - **Default:** `1.30`

- **`workerNodeIAM`**  
  - **Description:** IAM Role for EKS worker nodes.  
  - **Type:** `string`  
  - **Default:** `devWorkerNodes`

### EKS Cluster Scaling

- **`max_size`**  
  - **Description:** Maximum size of the worker node group.  
  - **Type:** `string`  
  - **Default:** `3`

- **`desired_size`**  
  - **Description:** Desired size of the worker node group.  
  - **Type:** `string`  
  - **Default:** `2`

- **`min_size`**  
  - **Description:** Minimum size of the worker node group.  
  - **Type:** `string`  
  - **Default:** `1`

- **`instanceType`**  
  - **Description:** List of instance types for the worker nodes.  
  - **Type:** `list(any)`  
  - **Default:** `["t3.medium"]`

### API Endpoint Access

- **`cluster_endpoint_public_access_cidrs`**  
  - **Description:** List of CIDR blocks allowed to access the Amazon EKS public API server endpoint.  
  - **Type:** `list(string)`  
  - **Default:** `["0.0.0.0/0"]`

### Database Subnet Configuration

- **`vpc_database_subnets`**  
  - **Description:** CIDR blocks for database subnets.  
  - **Type:** `list(string)`  
  - **Default:** `["10.0.151.0/24", "10.0.152.0/24"]`

- **`vpc_create_database_subnet_group`**  
  - **Description:** Whether to create a database subnet group.  
  - **Type:** `bool`  
  - **Default:** `true`

- **`vpc_create_database_subnet_route_table`**  
  - **Description:** Whether to create a route table for the database subnet.  
  - **Type:** `bool`  
  - **Default:** `true`

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