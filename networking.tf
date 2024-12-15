locals {
  public_subnets_cidr  = [for k, v in var.subnet_config : v.cidr_block if v.public]
  private_subnets_cidr = [for k, v in var.subnet_config : v.cidr_block if !v.public]
}
data "aws_availability_zones" "azs" {
  state = "available"
}
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.5.3"

  name                    = "${local.project_name}-vpc"
  cidr                    = var.vpc_cidr
  azs                     = data.aws_availability_zones.azs.names
  private_subnets         = local.private_subnets_cidr
  public_subnets          = local.public_subnets_cidr
  map_public_ip_on_launch = true
  enable_nat_gateway      = true
  single_nat_gateway      = true

    # VPC DNS Parameters
  enable_dns_hostnames = true
  enable_dns_support   = true

  # Database Subnets
  database_subnets = var.vpc_database_subnets
  create_database_subnet_group = var.vpc_create_database_subnet_group
  create_database_subnet_route_table = var.vpc_create_database_subnet_route_table

  tags = merge(local.common_tags, {
    Name = "${local.project_name}-vpc"
  })

  # Additional Tags to Subnets
  public_subnet_tags = {
    Type = "public-subnets"
    "kubernetes.io/role/elb" = 1    
    "kubernetes.io/cluster/${local.eks_cluster_name}" = "shared"        
  }
  private_subnet_tags = {
    Type = "private-subnets"
    "kubernetes.io/role/internal-elb" = 1    
    "kubernetes.io/cluster/${local.eks_cluster_name}" = "shared"    
  }

  database_subnet_tags = {
    Type = "database-subnets"
  }

}