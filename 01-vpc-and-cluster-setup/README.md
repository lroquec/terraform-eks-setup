# VPC and EKS Cluster Setup

This project sets up a Virtual Private Cloud (VPC) and an Amazon Elastic Kubernetes Service (EKS) cluster using Terraform. It includes configurations for IAM roles, policies, and Kubernetes resources to manage access and permissions for different user groups.

## Project Structure

```
01-vpc-and-cluster-setup/
├── .gitignore
├── .terraform/
├── 

data.tf


├── 

eks.tf


├── 

networking.tf


├── 

outputs.tf


├── 

providers.tf


├── 

README.md


├── 

shared_locals.tf


├── terraform.tfvars
├── 

users_admins.tf


├── 

users_dev.tf


├── 

users_readonly.tf


├── 

usersmagmt.tf


└── 

variables.tf


```

## Files Description

- **data.tf**: Defines data sources for the EKS cluster and its authentication.
- **eks.tf**: Configures the EKS cluster and its managed node groups.
- **networking.tf**: Sets up the VPC and its subnets.
- **outputs.tf**: Defines the outputs for the VPC and EKS cluster.
- **providers.tf**: Specifies the required providers and their configurations.
- **shared_locals.tf**: Contains local variables used across the project.
- **terraform.tfvars**: Defines variable values for the project.
- **users_admins.tf**: Configures IAM roles, policies, and groups for admin users.
- **users_dev.tf**: Configures IAM roles, policies, and groups for developer users.
- **users_readonly.tf**: Configures IAM roles, policies, and groups for read-only users.
- **usersmagmt.tf**: Manages the AWS Auth ConfigMap for the EKS cluster.
- **variables.tf**: Defines the variables used in the project.

## Setup Instructions

1. **Install Terraform**: Ensure you have Terraform installed on your machine. You can download it from [Terraform's official website](https://www.terraform.io/downloads.html).

2. **Configure AWS CLI**: Make sure you have the AWS CLI configured with the necessary permissions to create resources. You can configure it using:
   ```sh
   aws configure
   ```

3. **Initialize Terraform**: Navigate to the project directory and run:
   ```sh
   terraform init
   ```

4. **Plan the Infrastructure**: Review the changes Terraform will make by running:
   ```sh
   terraform plan
   ```

5. **Apply the Configuration**: Apply the Terraform configuration to create the resources:
   ```sh
   terraform apply
   ```

## Variables

The project uses several variables defined in 

variables.tf

 and `terraform.tfvars`. Here are some key variables:

- `project_name`: The name of the project.
- `vpc_cidr`: The CIDR block for the VPC.
- `subnet_config`: Configuration for the subnets within the VPC.
- `EKSClusterName`: The name of the EKS cluster.
- `instanceType`: The instance types for the EKS managed node groups.
- `admin_user_name`: The name of the admin user.
- `developer_user_name`: The name of the developer user.

## Outputs

The project provides several outputs defined in 

outputs.tf

:

- `vpc_id`: The ID of the VPC.
- `cluster_id`: The name/id of the EKS cluster.
- `cluster_endpoint`: The endpoint for the EKS Kubernetes API.
- `cluster_certificate_authority_data`: The base64 encoded certificate data required to communicate with the cluster.
- `aws_iam_openid_connect_provider_arn`: The ARN of the AWS IAM Open ID Connect Provider.
- `aws_iam_openid_connect_provider_extract_from_arn`: The extracted ARN of the AWS IAM Open ID Connect Provider.

## IAM Roles and Policies

The project sets up IAM roles and policies for different user groups:

- **Admin Users**: Defined in 

users_admins.tf

, includes full access to EKS and related resources.
- **Developer Users**: Defined in 

users_dev.tf

, includes access to EKS and additional AWS services like S3 and DynamoDB.
- **Read-Only Users**: Defined in 

users_readonly.tf

, includes read-only access to EKS resources.

## Kubernetes Resources

The project also sets up Kubernetes resources for managing access within the cluster:

- **Cluster Roles and Role Bindings**: Defined in 

users_admins.tf

, 

users_dev.tf

, and 

users_readonly.tf

.
- **Namespaces**: Defined in 

users_dev.tf

.

## Managing AWS Auth ConfigMap

The 
usersmagmt.tf

 file manages the AWS Auth ConfigMap for the EKS cluster, ensuring that the IAM roles are correctly mapped to Kubernetes RBAC roles.
