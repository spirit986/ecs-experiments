variable "aws_region" {
  type        = string
  description = "AWS Region"
  default     = "eu-north-1"
}

variable "vpc_cidr" {
  default = "10.100.0.0/16"
}

variable "prefix" {
  default = "Terraform-ECS-Demo"
}

variable "azs" {
  type = list(string)
  description = "Availability zones to use subnets"
  default = [ "eu-north-1a", "eu-north-1b" ]
}

variable "public_subnets" {
  type = list(string)
  description = "CIDR blocks to create public subnets"
  default = [ "10.100.10.0/24", "10.100.11.0/24" ]
}

variable "private_subnets" {
  type = list(string)
  description = "CIDR blocks to create private subnets"
  default = [ "10.100.20.0/24", "10.100.21.0/24" ]
}

variable "ecr_repo_name" {
  type = string
  default = "nginx"
}