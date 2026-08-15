data "terraform_remote_state" "ecs_cluster_crawler" {
  backend = "s3"
   config = {
    bucket = "kriolu-kloud-cluster-tf"
    key    = "cluster-terraform/prod/kriolu-kloud-cluster-us-east-1.tfstate"
    # key    = "cluster-terraform/homolog/kriolu-kloud-cluster-us-east-1.tfstate"
    region = "us-east-1"
  }
}
