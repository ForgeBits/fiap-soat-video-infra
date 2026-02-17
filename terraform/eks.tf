module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = "fiapx-cluster-${random_id.id.hex}"
  cluster_version = "1.31"

  # Aqui o EKS "enxerga" a VPC que você criou no outro arquivo
  vpc_id     = aws_vpc.fiapx_vpc.id
  subnet_ids = [aws_subnet.pub_a.id, aws_subnet.pub_b.id]

  # Acesso público para podermos usar o Lens/Kubectl
  cluster_endpoint_public_access = true
  enable_cluster_creator_admin_permissions = true

  eks_managed_node_groups = {
    # Suas instâncias EC2 onde os Pods vão morar
    node_group_api = {
      min_size     = 1
      max_size     = 3
      desired_size = 2
      instance_types = ["t3.small"]

      # Garante que os nodes usem suas subnets públicas
      subnet_ids = [aws_subnet.pub_a.id, aws_subnet.pub_b.id]
    }
  }

  tags = {
    Project = "fiapx"
  }
}