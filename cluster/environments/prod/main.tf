terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket         = "kriolu-kloud-terraform-tfstates"
    region         = "us-east-1"
    key            = "cluster-terraform/prod/kriolu-kloud-cluster-us-east-1.tfstate"
    dynamodb_table = "kriolu-kloud-cluster-terraform-lock"
  }
}

module "prod_ecs_cluster_main" {
  source = "../../ecs_cluster_main"

  aws_region = var.aws_region

  environment_name = var.environment_name

  vpc_id   = var.vpc_id
  vpc_cidr = var.vpc_cidr

  subnet_public_filter  = var.subnet_public_filter
  subnet_private_filter = var.subnet_private_filter
}
