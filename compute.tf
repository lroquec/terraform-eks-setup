# IAM Role for EKS to have access to the appropriate resources
resource "aws_iam_role" "eks-iam-role" {
  name = var.eksIAMRole

  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Principal" : {
          "Service" : "eks.amazonaws.com"
        },
        "Action" : "sts:AssumeRole"
      }
    ]
  })
}

## Attach the IAM policy to the IAM role
resource "aws_iam_role_policy_attachment" "AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks-iam-role.name
}
resource "aws_iam_role_policy_attachment" "AmazonEC2ContainerRegistryReadOnly-EKS" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.eks-iam-role.name
}

## Create the EKS cluster
resource "aws_eks_cluster" "eks" {
  name     = var.EKSClusterName
  role_arn = aws_iam_role.eks-iam-role.arn

  enabled_cluster_log_types = ["api", "audit", "scheduler", "controllerManager"]
  version                   = var.k8sVersion
  vpc_config {
    # You can set these as just private subnets if the Control Plane will be private
    subnet_ids = [module.vpc.public_subnets[0], module.vpc.public_subnets[1]]
  }

  depends_on = [
    aws_iam_role.eks-iam-role,
  ]
}

## Worker Nodes
resource "aws_iam_role" "workernodes" {
  name = var.workerNodeIAM

  assume_role_policy = jsonencode({
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
    Version = "2012-10-17"
  })
}

resource "aws_iam_role_policy_attachment" "AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.workernodes.name
}

resource "aws_iam_role_policy_attachment" "AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.workernodes.name
}

resource "aws_iam_role_policy_attachment" "EC2InstanceProfileForImageBuilderECRContainerBuilds" {
  policy_arn = "arn:aws:iam::aws:policy/EC2InstanceProfileForImageBuilderECRContainerBuilds"
  role       = aws_iam_role.workernodes.name
}

resource "aws_iam_role_policy_attachment" "AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.workernodes.name
}

resource "aws_iam_role_policy_attachment" "CloudWatchAgentServerPolicy-eks" {
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
  role       = aws_iam_role.workernodes.name
}

resource "aws_iam_role_policy_attachment" "AmazonEBSCSIDriverPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
  role       = aws_iam_role.workernodes.name
}

resource "aws_iam_role_policy_attachment" "asg_access" {
  role       = aws_iam_role.workernodes.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2AutoScalingRolePolicy"
}

resource "aws_iam_role_policy_attachment" "external_dns" {
  role       = aws_iam_role.workernodes.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonRoute53FullAccess"
}

resource "aws_iam_role_policy_attachment" "appmesh_access" {
  role       = aws_iam_role.workernodes.name
  policy_arn = "arn:aws:iam::aws:policy/AWSAppMeshFullAccess"
}

resource "aws_iam_role_policy_attachment" "alb_ingress_access" {
  role       = aws_iam_role.workernodes.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSLBControllerPolicy"
}


resource "aws_eks_node_group" "worker-node-group" {
  cluster_name    = aws_eks_cluster.eks.name
  node_group_name = "workernodes-${var.project_name}"
  node_role_arn   = aws_iam_role.workernodes.arn
  subnet_ids      = [module.vpc.public_subnets[0], module.vpc.public_subnets[1]]
  instance_types  = var.instanceType
  disk_size       = 20
  scaling_config {
    desired_size = var.desired_size
    max_size     = var.max_size
    min_size     = var.min_size
  }

  remote_access {
    ec2_ssh_key               = var.ec2_ssh_key
    source_security_group_ids = [aws_security_group.eks_nodes_sg.id]
  }

  depends_on = [
    aws_iam_role_policy_attachment.AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.AmazonEKS_CNI_Policy,
  ]
}

resource "aws_eks_addon" "csi" {
  cluster_name = aws_eks_cluster.eks.name
  addon_name   = "aws-ebs-csi-driver"
}

resource "aws_iam_openid_connect_provider" "eks_oidc_provider" {
  client_id_list = ["sts.amazonaws.com"]
  thumbprint_list = [
    "9e99a48a9960a6e3c123f6cf3f97cd3a17da5c85"
  ]
  url = aws_eks_cluster.eks.identity[0].oidc[0].issuer
}

# Security Group for EKS cluster
resource "aws_security_group" "eks_cluster_sg" {
  name        = "eks-cluster-sg"
  description = "EKS Cluster Security Group"
  vpc_id      = module.vpc.vpc_id

  # Allow inbound traffic on port 443
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.tester-ip] # Tester public IP
  }

  # Egress rule for all traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    "Name" = "eks-cluster-sg"
  }
}

# Security Group for EKS nodes
resource "aws_security_group" "eks_nodes_sg" {
  name        = "eks-nodes-sg"
  description = "EKS Nodes Security Group"
  vpc_id      = module.vpc.vpc_id

  # Allow inbound traffic on port 22 from the tester IP
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.tester-ip] # Tester public IP

  }

  # Allow communication between nodes
  ingress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    security_groups = [aws_security_group.eks_nodes_sg.id]
  }

  # Allow connection with the EKS cluster
  ingress {
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.eks_cluster_sg.id]
  }

  # Egress rule for all traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    "Name" = "eks-nodes-sg"
  }
}
