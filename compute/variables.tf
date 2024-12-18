variable "instance_type_spot" {
  default = "t3.medium"
  type    = string
}
variable "instance_type_free" {
  default = "t3.micro"
  type    = string
}
variable "spot_bid_price" {
  default     = "0.0147"
  description = "How much you are willing to pay as an hourly rate for an EC2 instance, in USD"
}
variable "cluster_name" {
  default     = "ecs_terraform_ec2"
  type        = string
  description = "the name of an ECS cluster"
}
variable "asg_min_ec2" {
  default     = "2"
  description = "The minimum EC2 spot instances to be available"
}
variable "asg_max_ec2" {
  default     = "5"
  description = "The maximum EC2 spot instances that can be launched at peak time"
}
variable "asg_desired_ec2" {
  default     = "2"
  description = "The maximum EC2 spot instances that can be launched at peak time"
}
