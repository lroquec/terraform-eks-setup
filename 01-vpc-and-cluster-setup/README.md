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

### EKS Module

- **`source`**  
  - **Value:** `terraform-aws-modules/eks/aws`  
  - **Version:** `~> 20.0`  

### Cluster Configuration

- **`cluster_name`**  
  - **Value:** Derived from the variable `var.EKSClusterName`.  

- **`cluster_version`**  
  - **Value:** `1.31`.  

- **`cluster_endpoint_public_access`**  
  - **Value:** `true` (enables public access to the API server).  

- **`vpc_id`**  
  - **Value:** Referenced from `module.vpc.vpc_id`.  

- **`subnet_ids`**  
  - **Value:** Referenced from `module.vpc.private_subnets`.  

- **`cluster_enabled_log_types`**  
  - **Description:** Enabled logs for the cluster.  
  - **Values:**  
    - `audit`  
    - `api`  
    - `authenticator`  
    - `controllerManager`  
    - `scheduler`  

### Cluster Add-ons

Add-ons deployed with the cluster:

- `coredns`
- `kube-proxy`
- `vpc-cni` (most recent version enabled)  
- `aws-ebs-csi-driver` (most recent version enabled)  
- `amazon-cloudwatch-observability` (most recent version enabled)  

### Cluster Access

- **`enable_cluster_creator_admin_permissions`**  
  - **Description:** Grants administrative permissions to the identity creating the cluster.  
  - **Value:** `true`.

### Managed Node Group Defaults

- **`ami_type`**  
  - **Value:** `AL2023_x86_64_STANDARD`.  

- **`instance_types`**  
  - **Value:** Referenced from `var.instanceType`.  

- **`iam_role_additional_policies`**  
  - **Policies:**  
    - `AmazonEBSCSIDriverPolicy`  
    - `AutoScalingFullAccess`  
    - `CloudWatchAgentServerPolicy`  
    - `AWSXrayWriteOnlyAccess`  

### Managed Node Groups

- **Node Group Name:** `node_group`  
- **`min_size`**  
  - **Value:** `2`.  
- **`max_size`**  
  - **Value:** `3`.  
- **`desired_size`**  
  - **Value:** Referenced from `var.desired_size`.

### Security Group Rules

- **Rule Name:** `http_traffic_node_to_node`  
  - **Description:** Allow HTTP traffic between nodes.  
  - **Type:** `ingress`.  
  - **Port Range:** `80`.  
  - **Protocol:** `tcp`.  

### Fargate Profile Defaults

- **`iam_role_additional_policies`**  
  - **Policies:**  
    - `AmazonEBSCSIDriverPolicy`  
    - `AutoScalingFullAccess`  
    - `CloudWatchAgentServerPolicy`  
    - `AWSXrayWriteOnlyAccess`  

### Fargate Profiles

- **Profile Name:** `deployment`  
  - **Namespace:** `fargate-test`.  
  - **Tags:**  
    - `Owner: secondary`.

### Tags

- Tags applied to the cluster are referenced from `local.common_tags`.

---

## Resource: Update Desired Size

A `null_resource` is used to trigger updates to the desired size of the node group when the `var.desired_size` changes.

### Provisioner

- **Command:** Updates the node group scaling configuration using the AWS CLI.  

```bash
aws eks update-nodegroup-config \
  --cluster-name ${module.eks.cluster_name} \
  --nodegroup-name ${element(split(":", module.eks.eks_managed_node_groups["node_group"].node_group_id), 1)} \
  --scaling-config desiredSize=${var.desired_size} \
  --region us-east-1 \
  --profile default
```

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
terraform apply
```