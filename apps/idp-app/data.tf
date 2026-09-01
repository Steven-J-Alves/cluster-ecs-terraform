data "aws_caller_identity" "current" {}

data "terraform_remote_state" "ecs_cluster_main" {
  backend = "s3"
  config = {
    bucket = "kriolu-kloud-terraform-tfstates"
    key    = "cluster-terraform/${var.cluster_environment}/kriolu-kloud-cluster-us-east-1.tfstate"
    region = "us-east-1"
  }
}

data "aws_vpc" "main" {
  tags = {
    Owner = "KrioluKloud"
  }
}

data "aws_subnets" "private" {
  filter {
    name   = "tag:Name"
    values = [var.subnet_private_filter]
  }
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.main.id]
  }
}
