# To import the existing key pair into Terraform state (run once on first apply):
# terraform import aws_key_pair.main kriolu-kloud-key

resource "aws_key_pair" "main" {
  key_name   = var.ec2_key_name
  public_key = var.ec2_public_key
}
