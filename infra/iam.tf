# EKS Cluster Service Role
resource "aws_iam_role" "cluster" {
  name = "${var.cluster_name}-cluster-role"
  assume_role_policy = jsonencode({
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "eks.amazonaws.com"
      }
    }]
    Version = "2012-10-17"
  })
}

resource "aws_iam_role_policy_attachment" "cluster_AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.cluster.name
}

# EKS Node Group Role
resource "aws_iam_role" "node" {
  name = "${var.cluster_name}-node-role"
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

resource "aws_iam_role_policy_attachment" "node_AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.node.name
}

resource "aws_iam_role_policy_attachment" "node_AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.node.name
}

resource "aws_iam_role_policy_attachment" "node_AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.node.name
}

# Developer Read-Only IAM User
resource "aws_iam_user" "developer" {
  name = "innovatemart-developer"
  path = "/"
  tags = {
    Environment = var.environment
  }
}

resource "aws_iam_access_key" "developer" {
  user = aws_iam_user.developer.name
}

# Developer Read-Only Policy - EXPANDED PERMISSIONS
resource "aws_iam_policy" "developer_readonly" {
  name = "EKSReadOnlyPolicy"
  path = "/"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          # EC2 permissions (VPC, subnets, instances)
          "ec2:Describe*",
         
          # EKS permissions
          "eks:DescribeCluster",
          "eks:ListClusters",
          "eks:DescribeNodegroup",
          "eks:ListNodegroups",
          "eks:DescribeAddon",
          "eks:ListAddons",

          # RDS permissions
          "rds:Describe*",
          "rds:ListTagsForResource",
          
          # DynamoDB permissions
          "dynamodb:DescribeTable",
          "dynamodb:ListTables",
          "dynamodb:DescribeTimeToLive",
          "dynamodb:DescribeBackup",
          "dynamodb:ListBackups",
          
          # ElastiCache permissions
          "elasticache:Describe*",
         
          # IAM permissions
          "iam:GetRole",
          "iam:GetRolePolicy",
          "iam:GetUser",
          "iam:GetUserPolicy",
          "iam:ListAttachedRolePolicies",
          "iam:ListAttachedUserPolicies",
         
          # Auto Scaling
          "autoscaling:Describe*",
         
          # Load Balancer permissions
          "elasticloadbalancing:Describe*",
         
          # CloudFormation
          "cloudformation:DescribeStacks",
          "cloudformation:DescribeStackResources",
          "cloudformation:ListStacks"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_user_policy_attachment" "developer_readonly" {
  user       = aws_iam_user.developer.name
  policy_arn = aws_iam_policy.developer_readonly.arn
}

# EKS Cluster Access for Developer User
resource "aws_eks_access_entry" "developer" {
  cluster_name      = aws_eks_cluster.main.name
  principal_arn     = aws_iam_user.developer.arn
  kubernetes_groups = ["readonly-users"]
  type              = "STANDARD"
 
  depends_on = [aws_eks_cluster.main]
}

# Developer access policy for EKS
resource "aws_eks_access_policy_association" "developer_readonly" {
  cluster_name  = aws_eks_cluster.main.name
  principal_arn = aws_iam_user.developer.arn
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSViewPolicy"

  access_scope {
    type = "cluster"
  }

  depends_on = [aws_eks_access_entry.developer]
}

# Create RBAC for the custom group
resource "kubernetes_cluster_role_binding" "developer_readonly" {
  metadata {
    name = "developer-readonly-binding"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "view"
  }
  subject {
    kind      = "Group"
    name      = "readonly-users"
    api_group = "rbac.authorization.k8s.io"
  }

  depends_on = [aws_eks_access_entry.developer]
}