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
  default = "backend"
}

variable "tag_costcenter" {
  type    = string
  default = "KrioluKloud"
}

variable "port" {
  type    = number
  default = 8080
}

variable "domain" {
  type    = string
  default = "demo-api-h.kriolu-kloud.cv"
}
