terraform {
  required_version = ">= 0.13"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.25.0"
    }
  }

  backend "s3" {
    key    = "apps-terraform/prod/kriolu-kloud-app-us-east-1.tfstate"
    region = "us-east-1"
    bucket = "kriolu-kloud-apps-tf"
  }
}

provider "aws" {
  profile = var.aws_profile
  region  = var.aws_region
}

# provider "aws" {
#   alias   = "kriolu_kloud_account"
#   region  = var.aws_region

#   default_tags {
#     tags = {
#       Environment = var.environment_name
#       Service     = var.tag_service
#       Owner       = var.tag_owner
#       CostCenter  = var.tag_costcenter
#     }
#   }
# }

module "prod_app" {
  source = "../../app"
  
  aws_profile = var.aws_profile

  aws_region  = var.aws_region

  environment_name = var.environment_name
  gitlab_branch    = var.gitlab_branch

  vpc_id   = var.vpc_id
  vpc_cidr = var.vpc_cidr

  subnet_public_filter  = var.subnet_public_filter
  subnet_private_filter = var.subnet_private_filter
  rds_db_password = var.rds_db_password
}