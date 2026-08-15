# Variáveis para o projeto geral

variable "aws_profile" {
  type    = string
  default = "kriolu-kloud-cluster"
}

variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "tag_service" {
  description = "Default_Tag Service"
  type        = string
  default     = "crawler"
}

variable "tag_owner" {
  description = "Default_Tag Owner"
  type        = string
  default     = "KrioluKloud"
}

variable "tag_costcenter" {
  description = "Default_Tag CostCenter"
  type        = string
  default     = "crawler"
}

variable "environment_name" {
  type    = string
  default = "homolog"
}
variable "gitlab_branch" {
  type    = string
  default = "homolog"
}

variable "vpc_id" {
  type    = string
  default = "vpc-0a6e2c716b0847b6b"
}
variable "vpc_cidr" {
  type    = string
  default = "10.222.0.0/16"
}

variable "subnet_public_filter" {
  type    = string
  default = "kriolu-kloud-homolog-subnet-public*"
}
variable "subnet_private_filter" {
  type    = string
  default = "kriolu-kloud-homolog-subnet-private*"
}

# Variáveis para o Banco MySQL
variable "rds_db_password" { type = string }
