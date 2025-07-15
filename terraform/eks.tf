module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = local.cluster_name
  cluster_version = "1.28"

  vpc_id                         = aws_vpc.main.id
  subnet_ids                     = [aws_subnet.subnet_1.id, aws_subnet.subnet_2.id, aws_subnet.subnet_3.id]
  cluster_endpoint_public_access = true  

  # EKS Managed Node Groups
  eks_managed_node_groups = {
    main = {
      name = "${var.env}-eks-nodes"

      instance_types = [var.node_instance_type]

      min_size     = var.min_nodes
      max_size     = var.max_nodes
      desired_size = var.desired_nodes

      disk_size     = var.disk_size
      capacity_type = var.capacity_type

      tags = {
        Environment = var.env
      }
    }
  }

  authentication_mode = "API"
  access_entries = {
    lab_user = {
      kubernetes_groups = []
      principal_arn     = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/lab-user"
      policy_associations = {
        admin = {
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
          access_scope = {
            type = "cluster"
          }
        }
      }
    }
  }
  
  tags = {
    Environment = var.env
    Terraform   = "true"
  }
}
