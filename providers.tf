terraform {
   required_version = ">= 1.7.0"
  backend "s3" {
    bucket = "lroquec-tf"
    key    = "eks-terraform.tfstate"
    region = "us-east-1"
  }
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "~> 5.76.0"
    }
        random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
  default_tags {
    tags = {
      CreatedBy = "lroquec"
      Owner     = "DevOps Team"
    }
  }
}