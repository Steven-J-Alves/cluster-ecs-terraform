data "terraform_remote_state" "ecs_cluster_main" {
  backend = "s3"
  config = {
    bucket = "kriolu-kloud-cluster-tf"
    key    = "cluster-terraform/prod/kriolu-kloud-cluster-us-east-1.tfstate"
    # key    = "cluster-terraform/homolog/kriolu-kloud-cluster-us-east-1.tfstate"
    region = "us-east-1"
  }
}

data "aws_acm_certificate" "acm_kriolu_kloud" {
  domain      = "*.kriolu-kloud.cv"
  statuses    = ["ISSUED"]
  most_recent = true
}

data "aws_acm_certificate" "acm_kriolu_kloud_private" {
  domain      = "*.kriolu-kloud.cv"
  statuses    = ["ISSUED"]
  most_recent = true
}

# data "aws_route53_zone" "zone" {
#   provider = aws.kriolu_kloud_account

#   name = "kriolu-kloud.cv."
# }

# data "aws_route53_zone" "private_zone" {
#   name = "crawler.com.br."
# }
