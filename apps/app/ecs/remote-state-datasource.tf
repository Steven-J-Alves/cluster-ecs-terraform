data "terraform_remote_state" "ecs_cluster_main" {
  backend = "s3"
  config = {
    bucket = "kriolu-kloud-terraform-tfstates"
    key    = "cluster-terraform/prod/kriolu-kloud-cluster-us-east-1.tfstate"
    region = "us-east-1"
  }
}
