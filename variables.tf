variable "aws_region" {
  type        = string
  description = "AWS Region"
  default     = "eu-north-1"
}

variable "module_compute_enable" {
  type = bool
  default = true
}

variable "module_ecs_ec2_enable" {
  type = bool
  default = true
}