# Bootstrap stack — apply this stack once before running any other stack.
# Uses local state stored in bootstrap/terraform.tfstate.
# This stack creates the S3 bucket and DynamoDB lock tables that all other
# stacks (network / cluster / apps) depend on for their S3 backend.

terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  # intentionally local — this stack creates the S3 bucket used by all other stacks
}

provider "aws" {
  region = var.aws_region
}

# ---------------------------------------------------------------------------
# S3 bucket for Terraform remote state
# ---------------------------------------------------------------------------

resource "aws_s3_bucket" "tfstate" {
  bucket = "kriolu-kloud-terraform-tfstates"

  tags = {
    Project   = "kriolu-kloud"
    ManagedBy = "terraform-bootstrap"
  }
}

resource "aws_s3_bucket_versioning" "tfstate" {
  bucket = aws_s3_bucket.tfstate.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "tfstate" {
  bucket = aws_s3_bucket.tfstate.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "tfstate" {
  bucket = aws_s3_bucket.tfstate.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# ---------------------------------------------------------------------------
# DynamoDB lock tables — one per stack
# ---------------------------------------------------------------------------

resource "aws_dynamodb_table" "network_lock" {
  name         = "kriolu-kloud-network-terraform-lock"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Project   = "kriolu-kloud"
    Stack     = "network"
    ManagedBy = "terraform-bootstrap"
  }
}

resource "aws_dynamodb_table" "cluster_lock" {
  name         = "kriolu-kloud-cluster-terraform-lock"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Project   = "kriolu-kloud"
    Stack     = "cluster"
    ManagedBy = "terraform-bootstrap"
  }
}

resource "aws_dynamodb_table" "apps_lock" {
  name         = "kriolu-kloud-apps-terraform-lock"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Project   = "kriolu-kloud"
    Stack     = "apps"
    ManagedBy = "terraform-bootstrap"
  }
}

resource "aws_dynamodb_table" "apps2_lock" {
  name         = "kriolu-kloud-apps2-terraform-lock"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Project   = "kriolu-kloud"
    Stack     = "apps2"
    ManagedBy = "terraform-bootstrap"
  }
}
