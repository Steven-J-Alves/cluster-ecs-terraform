# Variáveis para o projeto geral

variable "aws_profile" {
  type    = string
  default = "prod-ecs-cluster-main"
}

variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "environment_name" {
  type    = string
  default = "prod"
}

variable "vpc_id" {
  type    = string
  default = "vpc-001fc689ea32d1009"
}

variable "vpc_cidr" {
  type    = string
  default = "10.211.0.0/16"
}

variable "subnet_public_filter" {
  type    = string
  default = "kriolu-kloud-vpc-public*"
}

variable "subnet_private_filter" {
  type    = string
  default = "kriolu-kloud-vpc-private*"
}
