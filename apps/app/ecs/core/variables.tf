variable "service_name" { type = string }
variable "base_name" { type = string }
variable "environment_name" { type = string }

variable "aws_region" { type = string }

variable "cluster" {}
variable "networking" {}
variable "data_private_subnets" {}

variable "ecs_role" {}
variable "ecs_role_policy" {}

variable "container_name" { type = map(string) }
variable "ecr_repositories" {}

variable "port_api_app" { type = number }
variable "port_front_app" { type = number }

