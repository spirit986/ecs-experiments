## INFRA
## Defines the VPC and the ECS Cluster

data "terraform_remote_state" "vpc" {
  backend = "s3"
  config = {
    bucket = "ecs-experiments-tfstate-cc635-s3"
    key = "vpc.tfstate"
    region = "eu-north-1"
  }
}

locals {
  aws_region = var.aws_region

  common_tags = {
    Project   = "${var.prefix}"
    ManagedBy = "Terraform"
  }
  
  vpc_cidr = var.vpc_cidr
  vpc_name = "${var.prefix}-vpc"
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
  name                 = var.ecr_repo_name
  image_tag_mutability = "MUTABLE"
  image_scanning_configuration {
    scan_on_push = true
  }
  force_delete = true
}

## ECS Cluster and IAM Permissions
## IAM Permissions for tasks
resource "aws_iam_role" "ecs_task_execution_role" {
  name = "ecsTaskExecutionRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_role" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# ECS cluster
resource "aws_ecs_cluster" "ecs1" {
  name = "ECS1"
}
