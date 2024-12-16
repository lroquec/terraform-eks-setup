# Datasource: AWS Partition
# Use this data source to lookup information about the current AWS partition in which Terraform is working
data "aws_partition" "current" {}

resource "aws_iam_openid_connect_provider" "eks_oidc_provider" {
  client_id_list  = ["sts.${data.aws_partition.current.dns_suffix}"]
  thumbprint_list = [
    "9e99a48a9960a6e3c123f6cf3f97cd3a17da5c85"
  ]
  url = aws_eks_cluster.eks.identity[0].oidc[0].issuer

  tags = merge(
    {
      Name = "${var.EKSClusterName}-irsa"
    },
    local.common_tags
  )
}