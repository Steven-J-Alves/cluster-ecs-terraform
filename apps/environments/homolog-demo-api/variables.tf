variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "environment_name" {
  type    = string
  default = "homolog"
}

variable "cluster_environment" {
  type    = string
  default = "homolog"
}

variable "app_name" {
  type    = string
  default = "demo-api"
}

variable "tag_service" {
  type    = string
  default = "DemoApi"
}

variable "tag_owner" {
  type    = string
  default = "platform"
}

variable "tag_costcenter" {
  type    = string
  default = "KrioluKloud"
}

variable "port" {
  type    = number
  default = 3000
}

variable "domain" {
  type    = string
  default = "demo-api.homolog.kriolu-kloud.cv"
}
