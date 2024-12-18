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

    common_tags = {
      Project = "TerraformECS"
      InfrastructureType = "EC2"
    }
}

resource "aws_key_pair" "ecs" {
  key_name   = "terraform-deployer-key"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC+7y2N3hAMLj6ppHupd3+3X6r4Tyo9pw9pl+fslhS2ZBvjyjBdGFRYo5IeJO7h9/+Ooz4r3GQ9SNJUEbfCj2W4jW5i1iQuqVUCynupA2XSI438poOneuQMWwGPpmeehgVFy7tzjsQmqKnqc6YuS+aKxOpbYddxkn7OOv1l0A6k45gvSokSFU0sNJ4EHRSIYk6phUx7AD6Wg3R/kBubTAS7oOZRsnU86/KspT6drcYMKhyXuPo5Ht0ojiM8ybz06GvqW+vJf3YBJwOWxXHki+tTZxpCTDsjF46M0C+QJY2IYnExPnqVGgCjwaF7rRtyF4Nss9GO65NLNUl/ED0BcOJ4g/w8SOvVRID7+6Tiz/N8E//07luAWjWgtOb1QYCCnlcmzyB3d7R4WFDluAstOPRY7zlLk5zHdlq3GM4e6frPM2EYCn9qzTzRpgoKooOY7HvVGIuXeaya44DzaHf0nQa0oIr3iCaD3LVloUTln3KYgnXAO5qhrPa3qy41D4e7aP0= tome.petkovski@scalefocus.com"
}

## IAM policy
data "aws_iam_policy_document" "ecs_agent" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ecs_agent" {
  name               = "ecs-agent"
  assume_role_policy = data.aws_iam_policy_document.ecs_agent.json
}

resource "aws_iam_role_policy_attachment" "ecs_agent" {
  role       = aws_iam_role.ecs_agent.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

resource "aws_iam_instance_profile" "ecs_agent" {
  name = "ecs-agent"
  role = aws_iam_role.ecs_agent.name
}

## ECS Optimized AMI
data "aws_ami" "aws_optimized_ecs" {
  most_recent = true
  filter {
    name   = "name"
    values = ["amzn-ami*amazon-ecs-optimized"]
  }
  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  owners = ["591542846629"] # AWS
}

## SG
module "ec2_sg" {
  source = "terraform-aws-modules/security-group/aws"
  name   = "ec2_sg"
  vpc_id = data.terraform_remote_state.vpc.outputs.vpc_id
  ingress_with_cidr_blocks = [
    {
      from_port   = local.service_port #80
      to_port     = local.service_port #80
      protocol    = "tcp"
      description = "http port"
      cidr_blocks = "0.0.0.0/0"
    },
    {
      from_port   = local.ssh_port #22
      to_port     = local.ssh_port #22
      protocol    = "tcp"
      description = "ssh port"
      cidr_blocks = "0.0.0.0/0"
    }
  ]
  egress_with_cidr_blocks = [
    {
      from_port = 0
      to_port   = 0
      protocol  = "-1"
    cidr_blocks = "0.0.0.0/0" }
  ]
}

# ASG Launch Template for sport instances
resource "aws_launch_template" "ecs_cluster_asg_launch_template_spot" {
  name_prefix = "${var.cluster_name}_ecs_cluster_spot"
  image_id = data.aws_ami.aws_optimized_ecs.id
  key_name             = aws_key_pair.ecs.key_name

  iam_instance_profile { 
    arn = aws_iam_instance_profile.ecs_agent.arn
  }
  
  instance_type = var.instance_type_spot

  instance_market_options {
    market_type = "spot"
    spot_options {
      instance_interruption_behavior = "terminate"
      max_price = var.spot_bid_price
      spot_instance_type = "one-time"
    }
  }

  network_interfaces {
    associate_public_ip_address = true
    security_groups = [
      module.ec2_sg.security_group_id
      ]
  }

  user_data = base64encode(templatefile("${path.module}/user_data.sh.tpl", {
    cluster_name = var.cluster_name
    }))

}

# ASG Launch Template with freerier instances
resource "aws_launch_template" "ecs_cluster_asg_launch_template_freetier" {
  name_prefix = "${var.cluster_name}_ecs_cluster"
  image_id = data.aws_ami.aws_optimized_ecs.id
  key_name             = aws_key_pair.ecs.key_name

  iam_instance_profile { 
    arn = aws_iam_instance_profile.ecs_agent.arn
  }
  
  instance_type = var.instance_type_free

  network_interfaces {
    associate_public_ip_address = true
    security_groups = [
      module.ec2_sg.security_group_id
      ]
  }

  user_data = base64encode(templatefile("${path.module}/user_data.sh.tpl", {
    cluster_name = var.cluster_name
    }))

}

## ASG
resource "aws_autoscaling_group" "ecs_cluster_ec2" {
  name_prefix = "${var.cluster_name}_asg"
  termination_policies = [
     "OldestInstance" 
  ]

  default_cooldown          = 30
  health_check_grace_period = 300
  health_check_type = "EC2"
  max_size                  = var.asg_max_ec2
  min_size                  = var.asg_min_ec2
  desired_capacity          = var.asg_desired_ec2

  launch_template {
    id = aws_launch_template.ecs_cluster_asg_launch_template_freetier.id
    version = "$Latest"
  }
  
  lifecycle {
    create_before_destroy = true
  }

  vpc_zone_identifier = data.terraform_remote_state.vpc.outputs.vpc_private_subnet_ids

  tag {
      key                 = "Name"
      value               = var.cluster_name
      propagate_at_launch = true
    }
}

