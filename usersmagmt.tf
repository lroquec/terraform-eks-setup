module "eks-auth" {
  source  = "terraform-aws-modules/eks/aws//modules/aws-auth"
  version = "~> 20.0"

  manage_aws_auth_configmap = false
}

# Get AWS Account ID
data "aws_caller_identity" "current" {}
output "account_id" {
  value = data.aws_caller_identity.current.account_id
}

# Locals Block
locals {
  
  first_node_group_key = keys(module.eks.eks_managed_node_groups)[0]
  aws_auth_configmap_data = {
    mapRoles = yamlencode([
      {
        rolearn  = module.eks.eks_managed_node_groups[local.first_node_group_key].iam_role_arn
        username = "system:node:{{EC2PrivateDNSName}}"
        groups   = ["system:bootstrappers", "system:nodes"]
      },
    {
      rolearn  = "${aws_iam_role.eks_admin_role.arn}"
      username = "eks-admin" # Just a place holder name
      groups   = ["system:masters"]
    },
    {
      rolearn  = "${aws_iam_role.eks_readonly_role.arn}"
      username = "eks-readonly" # Just a place holder name
      #groups   = [ "eks-readonly-group" ]
      # Important Note: The group name specified in clusterrolebinding and in aws-auth configmap groups should be same. 
      groups = ["${kubernetes_cluster_role_binding_v1.eksreadonly_clusterrolebinding.subject[0].name}"]
    },
    {
      rolearn  = "${aws_iam_role.eks_developer_role.arn}"
      username = "eks-developer" # Just a place holder name
      #groups   = [ "eks-developer-group" ]
      # Important Note: The group name specified in clusterrolebinding and in aws-auth configmap groups should be same.       
      groups = ["${kubernetes_role_binding_v1.eksdeveloper_rolebinding.subject[0].name}"]
    }
    ] )
    
    mapUsers = yamlencode([
      {
      userarn  = "${aws_iam_user.eksadmin_user.arn}"
      username = "${aws_iam_user.eksadmin_user.name}"
      groups   = ["system:masters"]
      }
    ] )
  }
    patch_data = jsonencode({
    data = {
      mapRoles = local.aws_auth_configmap_data.mapRoles
      mapUsers = local.aws_auth_configmap_data.mapUsers
    }
  })
}

# Resource to update: Kubernetes Config Map
resource "null_resource" "update_aws_auth" {
  depends_on = [module.eks]

  triggers = {
    auth_map = local.patch_data
  }

  provisioner "local-exec" {
    command = <<-EOT
      aws eks update-kubeconfig --name ${module.eks.cluster_name} --region ${var.region}
      kubectl patch configmap/aws-auth -n kube-system --patch '${local.patch_data}'
    EOT
  }
}
