module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name                   = var.EKSClusterName
  cluster_version                = "1.31"
  cluster_endpoint_public_access = true

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  cluster_enabled_log_types = [
    "audit",
    "api",
    "authenticator",
    "controllerManager",
    "scheduler"
  ]

  cluster_addons = {
    coredns = {}

    kube-proxy = {}
    vpc-cni = {
      most_recent = true
    }
    aws-ebs-csi-driver = {
      most_recent = true
    }
    # This costs money, so it's commented out by default
    # amazon-cloudwatch-observability = {
    #   most_recent = true
    # }
    # aws-efs-csi-driver = {
    #   most_recent = true
    # }

  }

  # Cluster access entry
  # To add the current caller identity as an administrator
  enable_cluster_creator_admin_permissions = true


  eks_managed_node_group_defaults = {
    ami_type       = "AL2023_x86_64_STANDARD"
    instance_types = var.instanceType

    iam_role_additional_policies = {
      ebs_policy                                 = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy" #IAM rights needed by CSI driver
      auto_scaling_policy                        = "arn:aws:iam::aws:policy/AutoScalingFullAccess"
      cloudwatch_container_insights_agent_policy = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
      xray_policy                                = "arn:aws:iam::aws:policy/AWSXrayWriteOnlyAccess"
      efs_policy                                 = "arn:aws:iam::aws:policy/service-role/AmazonEFSCSIDriverPolicy" #Amazon EFS CSI driver policy
    }
  }

  eks_managed_node_groups = {

    node_group = {
      min_size     = var.min_size
      max_size     = var.max_size
      desired_size = var.desired_size
    }
  }

  node_security_group_additional_rules = {
    http_traffic_node_to_node = {
      description = "Allow inbound HTTP from self"
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      self        = true
      type        = "ingress"
    }
  }

  # Fargate profile. If you needed uncomment it.
  # fargate_profile_defaults = {
  #   iam_role_additional_policies = {
  #     ebs_policy                                 = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy" #IAM rights needed by CSI driver
  #     auto_scaling_policy                        = "arn:aws:iam::aws:policy/AutoScalingFullAccess"
  #     cloudwatch_container_insights_agent_policy = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
  #     xray_policy                                = "arn:aws:iam::aws:policy/AWSXrayWriteOnlyAccess"
  #   }
  # }

  # fargate_profiles = {
  #   deployment = {
  #     name = "demo"
  #     selectors = [
  #       {
  #         namespace = "fargate-test"
  #       }
  #     ]

  #     # # Using specific subnets instead of the subnets supplied for the cluster itself
  #     # subnet_ids = [module.vpc.private_subnets[1]]

  #     tags = {
  #       Owner = "secondary"
  #     }
  #   }
  # }
}

resource "null_resource" "wait_for_cluster" {
  depends_on = [module.eks]
}

resource "null_resource" "update_desired_size" {
  triggers = {
    desired_size = var.desired_size
  }

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]

    command = <<-EOT
      aws eks update-nodegroup-config \
        --cluster-name ${module.eks.cluster_name} \
        --nodegroup-name ${element(split(":", module.eks.eks_managed_node_groups["node_group"].node_group_id), 1)} \
        --scaling-config desiredSize=${var.desired_size} \
        --region ${var.region} \
        --profile default
    EOT
  }
}