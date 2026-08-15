provider "aws" {
  profile = var.aws_profile
  region  = var.aws_region

  default_tags {
    tags = {
      Environment = var.environment_name
      Service     = var.tag_service
      Owner       = var.tag_owner
      CostCenter  = var.tag_costcenter
      # Name        = "${substr(var.environment_name, 0, 1)}-${var.service_name}-others"
    }
  }
}