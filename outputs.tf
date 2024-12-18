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

output "ecr_repository_info" {
    value = module.infra.nginx_ecr_repo_login_details
}