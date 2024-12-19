data "aws_caller_identity" "current" {}
locals {
    account_id = data.aws_caller_identity.current.account_id
    enable_compute_module = false # depends on infra
    enable_ecs_ec2_module = false # depends on compute
    enable_ecs_fargate_module = true # depends on infra
}

module "infra" {
    source = "./infra"
}

module "compute" {
    source = "./compute"
    count = local.enable_compute_module ? 1 : 0
    depends_on = [ module.infra ]
}

module "ecs-ec2" {
    source = "./ecs-ec2"
    count = local.enable_ecs_ec2_module ? 1 : 0
    depends_on = [ module.compute ]
}

module "ecs-fargate" {
    source = "./ecs-fargate"
    count = local.enable_ecs_fargate_module ? 1 : 0
    depends_on = [ module.infra ]
}
