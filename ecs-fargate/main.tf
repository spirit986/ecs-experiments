data "terraform_remote_state" "vpc" {
  backend = "s3"
  config = {
    bucket = "ecs-experiments-tfstate-cc635-s3"
    key = "vpc.tfstate"
    region = "eu-north-1"
  }
}

locals {
    aws_account_id = data.terraform_remote_state.vpc.outputs.aws_account_id
    aws_region = data.terraform_remote_state.vpc.outputs.aws_region
    service_port = 80
    ssh_port = 22
    task_def_name = "ecs-fargate"
    ecs_service_name_1 = "fargate-ecs-nginx"

    common_tags = {
      Project = "TerraformECS"
      InfrastructureType = "EC2"
    }
}

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


