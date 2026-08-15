# Terraform Block
terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.0"
    }
  }

  backend "s3" {
    bucket = "kriolu-kloud-terraform-tfstates"
    region = "us-east-1"
    key    = "network-terraform/homolog/kriolu-kloud-vpc-us-east-1.tfstate"

    # Criar manualmente esta tabela e o LockID antes do primeiro apply
    dynamodb_table = "kriolu-kloud-network-terraform-lock"
  }
}

# Provider Block
provider "aws" {
  region = var.aws_region
}
