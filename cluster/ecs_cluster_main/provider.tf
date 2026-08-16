provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Environment = var.environment_name
      Service     = var.tag_service
      Owner       = var.tag_owner
      CostCenter  = var.tag_costcenter
    }
  }
}