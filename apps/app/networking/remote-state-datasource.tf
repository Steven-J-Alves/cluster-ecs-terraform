data "terraform_remote_state" "ecs_cluster_main" {
  backend = "s3"
  config = {
    bucket = "kriolu-kloud-terraform-tfstates"
    key    = "cluster-terraform/prod/kriolu-kloud-cluster-us-east-1.tfstate"
    region = "us-east-1"
  }
}

data "aws_acm_certificate" "acm_kriolu_kloud" {
  domain      = "*.kriolu-kloud.cv"
  statuses    = ["ISSUED", "PENDING_VALIDATION"]
  most_recent = true
}

data "aws_acm_certificate" "acm_kriolu_kloud_private" {
  domain      = "*.kriolu-kloud.cv"
  statuses    = ["ISSUED", "PENDING_VALIDATION"]
  most_recent = true
}
