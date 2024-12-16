# Datasource: AWS Partition
# Use this data source to lookup information about the current AWS partition in which Terraform is working
data "aws_partition" "current" {}

resource "aws_iam_openid_connect_provider" "eks_oidc_provider" {
  client_id_list = ["sts.${data.aws_partition.current.dns_suffix}"]
  thumbprint_list = [
    "9e99a48a9960a6e3c123f6cf3f97cd3a17da5c85"
  ]
  url = module.eks.cluster_oidc_issuer_url

  tags = merge(
    {
      Name = "${var.EKSClusterName}-irsa"
    },
    local.common_tags
  )
}

# Extract OIDC Provider from OIDC Provider ARN
locals {
  aws_iam_oidc_connect_provider_extract_from_arn = element(split("oidc-provider/", "${aws_iam_openid_connect_provider.eks_oidc_provider.arn}"), 1)
}