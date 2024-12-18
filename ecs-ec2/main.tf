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
    task_def_name = "ec2-ecs"
    ecs_service_name_1 = "ec2-ecs-nginx"

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

# ECS Cluster
resource "aws_ecs_cluster" "ecs_cluster" {
    name  = var.cluster_name
}

resource "aws_ecs_task_definition" "nginx_task_definition" {
  family             = local.task_def_name
  execution_role_arn = aws_iam_role.ecs_task_execution_role.arn
  memory             = 512
  # cpu                = 512
  container_definitions = jsonencode([
    {
      name      = local.task_def_name
      image     = "${local.aws_account_id}.dkr.ecr.${local.aws_region}.amazonaws.com/nginx:latest"
      # cpu       = 512
      #memory    = 512
      essential = true
      portMappings = [
        {
          containerPort = 80
          hostPort      = 80
        }
      ]
    }
  ])
  tags = merge(
    local.common_tags,
    {
      Name = local.task_def_name
    }
  )
}

resource "aws_ecs_service" "nginx" {
  name            = local.ecs_service_name_1
  cluster         = aws_ecs_cluster.ecs_cluster.id
  task_definition = aws_ecs_task_definition.nginx_task_definition.arn
  desired_count   = 2
}
