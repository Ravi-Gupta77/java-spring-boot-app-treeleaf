################################################################################
# VPC Module
################################################################################
module "vpc" {
  source = "terraform-aws-modules/vpc/aws"
  version = "~> 3.0"
  name = "k8s-vpc"
  cidr = "10.0.0.0/16"
  azs = ["${var.region}a", "${var.region}b"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets = ["10.0.101.0/24", "10.0.102.0/24"]
  enable_nat_gateway = true
}

# EKS Cluster
module "eks" {
  source = "terraform-aws-modules/eks/aws"
  version = "~> 18.0"
  cluster_name = "my-eks-cluster"
  cluster_version = "1.24"
  vpc_id = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  eks_managed_node_groups = {
    main = {
      min_size = 2
      max_size = 4
      desired_size = 2
      instance_types = ["t3.medium"]
    }
  }
}

# Variables
variable "region" {
  default = "us-east-1"
}