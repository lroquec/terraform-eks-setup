terraform {
  backend "s3" {
    bucket = "lroquec-tf"
    key    = "eks-terraform.tfstate"
    region = "us-east-1"
  }
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}
