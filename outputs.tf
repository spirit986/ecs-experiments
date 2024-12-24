output "aws_account_id" {
    value = data.aws_caller_identity.current.account_id
}

output "aws_region" {
    value = var.aws_region
}

output "vpc_id" {
    value = module.infra.vpc_id
}

output "vpc_private_subnet_ids" {
    value = module.infra.vpc_private_subnet_ids
}

output "vpc_public_subnet_ids" {
    value = module.infra.vpc_public_subnet_ids
}

output "ecr_nginx_repo_name" {
    value = module.infra.nginx_ecr_repo_name
}

output "ecr_repository_info" {
    value = module.infra.nginx_ecr_repo_login_details
}

output "ecr_repository_url" {
    value = module.infra.nginx_ecr_repository_url
}

output "ecs_task_execution_role_arn" {
    value = module.infra.ecs_task_execution_role_arn
}

output "ecs_cluster_ecs1_name" {
    value = module.infra.ecs_cluster_ecs1_name
}

output "ecs_cluster_ecs1_id" {
    value = module.infra.ecs_cluster_ecs1_id
}