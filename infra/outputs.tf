output "vpc_id" {
  value = module.ecs_vpc.vpc_id
}

output "vpc_private_subnet_ids" {
  value = module.ecs_vpc.private_subnets
}

output "vpc_public_subnet_ids" {
  value = module.ecs_vpc.public_subnets
}

output "nginx_ecr_repo_name" {
    value = aws_ecr_repository.nginx_ecr_repo.name
}

output "nginx_ecr_repo_url" {
    value = aws_ecr_repository.nginx_ecr_repo.repository_url
}

output "nginx_ecr_repo_arn" {
    value = aws_ecr_repository.nginx_ecr_repo.arn
}

output "nginx_ecr_repo_login_details" {
    value = <<EOT
> export MY_AWS_ACCOUNT=$(aws --output=json sts get-caller-identity | jq -r .Account) && echo $MY_AWS_ACCOUNT
> export MY_AWS_REGION=$(aws configure get default.region) && echo $MY_AWS_REGION
> docker pull nginx
> docker tag nginx:latest $MY_AWS_ACCOUNT.dkr.ecr.$MY_AWS_REGION.amazonaws.com/${local.ecr_repo_name}:latest
> aws ecr get-login-password --region $MY_AWS_REGION | docker login --username AWS --password-stdin $MY_AWS_ACCOUNT.dkr.ecr.$MY_AWS_REGION.amazonaws.com
> docker push $MY_AWS_ACCOUNT.dkr.ecr.$MY_AWS_REGION.amazonaws.com/${local.ecr_repo_name}:latest
EOT
}



