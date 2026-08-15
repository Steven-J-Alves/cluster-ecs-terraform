variable "service_name" { type = string }
variable "base_name" { type = string }
variable "environment_name" { type = string }

variable "aws_region" { type = string }

variable "networking" {}
variable "data_private_subnets" {}

variable "sg_ssh" {}

variable "ecs_role" {}
variable "ecs_role_policy" {}

variable "container_name" { type = map(string) }
variable "ecr_repositories" {}

variable "port_api_app" { type = number }
variable "port_front_app" { type = number }


variable "ec2_key_name" {}

variable "tags" {
  description = "A map of tags to assign to the resources."
  type        = map(string)
  default     = {}
}
