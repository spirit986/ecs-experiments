locals {
  aws_region = var.aws_region
  prefix     = "Terraform-ECS-Demo"
  ecr_repo_name = "nginx"

  common_tags = {
    Project   = local.prefix
    ManagedBy = "Terraform"
  }
  
  vpc_cidr = var.vpc_cidr
  vpc_name = "${local.prefix}-vpc"
}

module "ecs_vpc" {
  source = "terraform-aws-modules/vpc/aws"
  name = local.vpc_name
  cidr = local.vpc_cidr
  azs             = var.azs
  private_subnets = var.private_subnets
  public_subnets  = var.public_subnets
  enable_nat_gateway     = false
  enable_dns_hostnames   = true
  one_nat_gateway_per_az = true
  tags = local.common_tags
}

resource "aws_ecr_repository" "nginx_ecr_repo" {
  name                 = local.ecr_repo_name
  image_tag_mutability = "MUTABLE"
  image_scanning_configuration {
    scan_on_push = true
  }
  force_delete = true
}
