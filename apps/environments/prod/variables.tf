# Variáveis para o projeto geral

variable "aws_profile" {
  type    = string
  default = "kriolu-kloud-cluster"
}

variable "aws_region" {
  type    = string
  default = "us-east-1"
}

# variable "tag_service" {
#   description = "Default_Tag Service"
#   type        = string
#   default     = "CrawlerBusa"
# }
# 
# variable "tag_owner" {
#   description = "Default_Tag Owner"
#   type        = string
#   default     = "KrioluKloud"
# }
# 
# variable "tag_costcenter" {
#   description = "Default_Tag CostCenter"
#   type        = string
#   default     = "KrioluKloud"
# }

variable "environment_name" {
  type    = string
  default = "prod"
}

variable "gitlab_branch" {
  type    = string
  default = "main"
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

# Variáveis para o Banco MySQL
variable "rds_db_password" { type = string }
