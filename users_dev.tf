# Resource: k8s namespace
resource "kubernetes_namespace_v1" "k8s_dev" {
  metadata {
    name = "dev"
  }
}

# Resource: AWS IAM Role - EKS Developer User
resource "aws_iam_role" "eks_developer_role" {
  name = "${local.project_name}-eks-developer-role"

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
      },
    ]
  })

  tags = {
    tag-key = "${local.project_name}-eks-developer-role"
  }
}

resource "aws_iam_role_policy" "eks-developer-access-policy" {
  name = "eks-developer-access-policy"
  role = aws_iam_role.eks_developer_role.id

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "iam:ListRoles",
          "ssm:GetParameter",
          "eks:DescribeNodegroup",
          "eks:ListNodegroups",
          "eks:DescribeCluster",
          "eks:ListClusters",
          "eks:AccessKubernetesApi",
          "eks:ListUpdates",
          "eks:ListFargateProfiles",
          "eks:ListIdentityProviderConfigs",
          "eks:ListAddons",
          "eks:DescribeAddonVersions"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}

# Associate IAM Policy to IAM Role
resource "aws_iam_role_policy_attachment" "eks-developrole-s3fullaccess" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
  role       = aws_iam_role.eks_developer_role.name
}

# Associate IAM Policy to IAM Role
resource "aws_iam_role_policy_attachment" "eks-developrole-dynamodbfullaccess" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess"
  role       = aws_iam_role.eks_developer_role.name
}

# Resource: AWS IAM Group 
resource "aws_iam_group" "eksdeveloper_iam_group" {
  name = "${local.project_name}-eksdeveloper"
  path = "/"
}

# Resource: AWS IAM Group Policy
resource "aws_iam_group_policy" "eksdeveloper_iam_group_assumerole_policy" {
  name  = "${local.project_name}-eksdeveloper-group-policy"
  group = aws_iam_group.eksdeveloper_iam_group.name

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "sts:AssumeRole",
        ]
        Effect   = "Allow"
        Sid      = "AllowAssumeOrganizationAccountRole"
        Resource = "${aws_iam_role.eks_developer_role.arn}"
      },
    ]
  })
}

# Resource: AWS IAM User 
resource "aws_iam_user" "eksdeveloper_user" {
  name          = var.developer_user_name
  path          = "/"
  force_destroy = true
  tags          = local.common_tags
}


# Resource: AWS IAM Group Membership
resource "aws_iam_group_membership" "eksdeveloper" {
  name = "${local.project_name}-eksdeveloper-group-membership"
  users = [
    aws_iam_user.eksdeveloper_user.name
  ]
  group = aws_iam_group.eksdeveloper_iam_group.name
}

# Resource: k8s Cluster Role
resource "kubernetes_cluster_role_v1" "eksdeveloper_clusterrole" {
  metadata {
    name = "${local.project_name}-eksdeveloper-clusterrole"
  }

  rule {
    api_groups = [""]
    resources  = ["nodes", "namespaces", "pods", "events", "services", "configmaps", "serviceaccounts"]
    verbs      = ["get", "list"]
  }
  rule {
    api_groups = ["apps"]
    resources  = ["deployments", "daemonsets", "statefulsets", "replicasets"]
    verbs      = ["get", "list"]
  }
  rule {
    api_groups = ["batch"]
    resources  = ["jobs"]
    verbs      = ["get", "list"]
  }
}

# Resource: k8s Cluster Role Binding
resource "kubernetes_cluster_role_binding_v1" "eksdeveloper_clusterrolebinding" {
  metadata {
    name = "${local.project_name}-eksdeveloper-clusterrolebinding"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role_v1.eksdeveloper_clusterrole.metadata.0.name
  }
  subject {
    kind      = "Group"
    name      = "eks-developer-group"
    api_group = "rbac.authorization.k8s.io"
  }
}

# Resource: k8s Role
resource "kubernetes_role_v1" "eksdeveloper_role" {
  metadata {
    name      = "${local.project_name}-eksdeveloper-role"
    namespace = kubernetes_namespace_v1.k8s_dev.metadata[0].name
  }

  rule {
    api_groups = ["", "extensions", "apps"]
    resources  = ["*"]
    verbs      = ["*"]
  }
  rule {
    api_groups = ["batch"]
    resources  = ["jobs", "cronjobs"]
    verbs      = ["*"]
  }
}

# Resource: k8s Role Binding
resource "kubernetes_role_binding_v1" "eksdeveloper_rolebinding" {
  metadata {
    name      = "${local.project_name}-eksdeveloper-rolebinding"
    namespace = kubernetes_namespace_v1.k8s_dev.metadata[0].name
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Role"
    name      = kubernetes_role_v1.eksdeveloper_role.metadata.0.name
  }
  subject {
    kind      = "Group"
    name      = "eks-developer-group"
    api_group = "rbac.authorization.k8s.io"
  }
}