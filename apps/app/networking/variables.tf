variable "base_name" { type = string }
variable "vpc_cidr" { type = string }
variable "kriolu_kloud_vpn" { type = string }

variable "port_api_app" { type = number }
variable "port_front_app" { type = number }

variable "data_vpc" {}

variable "data_acm_certificate" {}
variable "data_acm_certificate_private" {}

variable "data_public_subnets" {}
variable "data_private_subnets" {}
variable "data_sg_alb_public" {}
variable "data_sg_alb_private" {}

variable "listener_rules" {
  type = map(object({
    priority         = number
    target_group_arn = string
    host_header      = string
  }))
  default = {}

}

variable "listener_rules_private" {
  type = map(object({
    priority         = number
    target_group_arn = string
    host_header      = string
  }))
  default = {}
}