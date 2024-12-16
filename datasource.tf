# data "terraform_remote_state" "eks" {
#   backend = "s3"
#   config = {
#     bucket = "lroquec-tf"
#     key    = "eks/eks-terraform.tfstate"
#     region = "us-east-1"
#   }
# }