variable "service_nginx_fargate_simple_params" {
  type = map(string)
  default = {
    "task_definition_name" = "nginx-fargate1"
    "service_name" = "nginx-fargate1"
    "service_port" = "80"
  }
}
variable "common_tags" {
  type = map(string)
  default = {
    "Project" = "TerrafromECS"
    "InfrastructureType" = "FARGATE"
  }
}
