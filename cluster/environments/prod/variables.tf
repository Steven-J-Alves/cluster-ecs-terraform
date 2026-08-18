# Variables for the prod environment

variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "environment_name" {
  type    = string
  default = "prod"
}

variable "vpc_cidr" {
  type    = string
  default = "10.220.0.0/16"
}

variable "subnet_public_filter" {
  type    = string
  default = "*kriolu-kloud-vpc-public*"
}

variable "subnet_private_filter" {
  type    = string
  default = "*kriolu-kloud-vpc-private*"
}
