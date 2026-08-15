# ------- Service Name -------
variable "service_name" {
  description = "Project Name"
  type        = string
  default     = "ecs-cluster-main"
}

variable "tag_service" {
  description = "Default_Tag Service"
  type        = string
  default     = "Cluster-Main"
}

variable "tag_owner" {
  description = "Default_Tag Owner"
  type        = string
  default     = "EquipeCloud"
}

variable "tag_costcenter" {
  description = "Default_Tag CostCenter"
  type        = string
  default     = "KrioluKloud"
}

# -------
# ------- AWS Access -------
variable "aws_region" {
  description = "The AWS Region in which you want to deploy the resources"
  type        = string
}

variable "aws_profile" {
  description = "The profile name that you have configured in the file .aws/credentials"
  type        = string
}

# -------
# ------- AWS Resources -------
variable "vpc_id" {
  description = "VPC CIDR"
  type        = string
}

variable "vpc_cidr" {
  description = "VPC CIDR"
  type        = string
}

variable "subnet_public_filter" {
  description = "Filtro para Subnets Publicas (tag:Name)"
  type        = string
}

variable "subnet_private_filter" {
  description = "Filtro para Subnets Privadas (tag:Name)"
  type        = string
}

variable "sg_alb_public_filter" {
  description = "Filtro para Grupo de Segurança ALB Público (tag:Name)"
  type        = string
  default     = "sg-alb-public"
}

variable "sg_alb_private_filter" {
  description = "Filtro para Grupo de Segurança ALB Privado (tag:Name)"
  type        = string
  default     = "sg-alb-private"
}

variable "sg_data_private_filter" {
  description = "Filtro para Grupo de Segurança Dados (tag:Name)"
  type        = string
  default     = "sg-data-private"
}

variable "sg_services_private_filter" {
  description = "Filtro para Grupo de Segurança Serviços Privado (tag:Name)"
  type        = string
  default     = "sg-services-private"
}

variable "sg_ssh_private_filter" {
  description = "Filtro para Grupo de Segurança SSH Privado (tag:Name)"
  type        = string
  default     = "sg-ssh-private"
}

variable "sg_ec2_private_filter" {
  description = "Filtro para Grupo de Segurança EC2 Privado (tag:Name)"
  type        = string
  default     = "sg-ec2-private"
}

variable "kriolu_kloud_vpn" {
  description = "IP da VPN da IN8"
  type        = string
  default     = "189.36.129.142/32"
}

# ------- Environment + GitLab -------
variable "environment_name" {
  description = "The name of your environment"
  type        = string

  validation {
    condition     = length(var.environment_name) < 23
    error_message = "Due the this variable is used for concatenation of names of other resources, the value must have less than 23 characters."
  }
}

variable "ec2_key_name" {
  description = "EC2 SSH key pair"
  type = string
  default = "kriolu-kloud-ssh.pem"
}

variable "namespace_name" {
  description = "The name of the AWS Cloud Map private DNS namespace"
  type        = string
  default     = "busca.local.cloud" 
}
