### nginx-simple

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
    aws_vpc_id = data.terraform_remote_state.vpc.outputs.vpc_id
    aws_region = data.terraform_remote_state.vpc.outputs.aws_region
    aws_public_subnet_ids = data.terraform_remote_state.vpc.outputs.vpc_public_subnet_ids
    aws_private_subnet_ids = data.terraform_remote_state.vpc.outputs.vpc_private_subnet_ids

    ecs_cluster_name = data.terraform_remote_state.vpc.outputs.ecs_cluster_ecs1_name
    ecs_cluster_id = data.terraform_remote_state.vpc.outputs.ecs_cluster_ecs1_id
    ecs_task_definition_name = var.service_nginx_fargate_simple_params.task_definition_name
    ecs_service_name = var.service_nginx_fargate_simple_params.task_definition_name
    ecs_service_port = var.service_nginx_fargate_simple_params.service_port
    ecs_task_efinition_execution_role_arn = data.terraform_remote_state.vpc.outputs.ecs_task_execution_role_arn
    ecr_nginx_repo_name = data.terraform_remote_state.vpc.outputs.ecr_nginx_repo_name
    ecr_nginx_repo_url = data.terraform_remote_state.vpc.outputs.ecr_repository_url

    common_tags = var.common_tags
}

## ALB - SG
resource "aws_security_group" "lb" {
  name        = "nginx-lb-sg"
  description = "controls access to the ALB"
  vpc_id = local.aws_vpc_id
}
resource "aws_vpc_security_group_ingress_rule" "tcp80_lb" {
  security_group_id = aws_security_group.lb.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}
resource "aws_vpc_security_group_egress_rule" "allow_all_ipv4_lb" {
  security_group_id = aws_security_group.lb.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}

# Security Group for ECS Tasks
resource "aws_security_group" "ecs_tasks" {
  name        = "nginx-tasks-sg"
  description = "Allow inbound access from the ALB only"
  vpc_id = local.aws_vpc_id
}
resource "aws_vpc_security_group_ingress_rule" "tcp80_ecs_tasks" {
  security_group_id = aws_security_group.ecs_tasks.id
  ip_protocol = "tcp"
  from_port = 80
  to_port = 80
  referenced_security_group_id = aws_security_group.lb.id
}
resource "aws_vpc_security_group_egress_rule" "allow_all_ipv4_ecs_tasks" {
  security_group_id = aws_security_group.ecs_tasks.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}

# Task definition 
resource "aws_ecs_task_definition" "nginx" {
  family                   = "nginx-service"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = local.ecs_task_efinition_execution_role_arn

  container_definitions = jsonencode([
    {
      name  = "nginx"
      image = "${local.ecr_nginx_repo_url}:latest"
      portMappings = [
        {
          containerPort = 80
          hostPort      = 80
        }
      ]
    }
  ])
}

## ALB - Target Group
resource "aws_lb_target_group" "nginx" {
  name        = "nginx-tg"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = local.aws_vpc_id
  target_type = "ip"
}

## ALB - Listener
resource "aws_lb_listener" "front_end" {
  load_balancer_arn = aws_lb.nginx.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.nginx.arn
  }
}

## ALB
resource "aws_lb" "nginx" {
  name               = "nginx-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [ aws_security_group.lb.id ]
  subnets = [for subnet in local.aws_public_subnet_ids : subnet]
}

# ECS Service for Nginx
resource "aws_ecs_service" "nginx" {
  name            = "nginx-service"
  cluster         = local.ecs_cluster_id
  task_definition = aws_ecs_task_definition.nginx.arn
  desired_count   = 2
  launch_type     = "FARGATE"

  network_configuration {
    subnets = [for subnet in local.aws_public_subnet_ids : subnet]
    security_groups  = [ aws_security_group.ecs_tasks.id ]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.nginx.arn
    container_name   = "nginx"
    container_port   = 80
  }

  # Allow the service to scale based on demand
  lifecycle {
    ignore_changes = [ desired_count ]
  }
}

