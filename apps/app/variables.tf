# ------- Service Name -------
variable "service_name" {
  description = "Project Name"
  type        = string
  default     = "app"
}

variable "tag_service" {
  description = "Default_Tag Service"
  type        = string
  default     = "App"
}

variable "tag_owner" {
  description = "Default_Tag Owner"
  type        = string
  default     = "KrioluKloud"
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

variable "iam_role_names" {
  description = "The name of the IAM Role for each service"
  type        = map(string)
  default = {
    devops        = "app-tf-devops-role"
    ecs           = "app-tf-ecs-task-execution-role"
    ecs_task_role = "app-tf-ecs-task-role"
  }
}

variable "kriolu_kloud_vpn" {
  description = "IP da VPN da IN8"
  type        = string
  default     = "189.36.129.142/32"
}


# -------
# ------- Environment + GitLab -------
variable "environment_name" {
  description = "The name of your environment"
  type        = string

  validation {
    condition     = length(var.environment_name) < 23
    error_message = "Due the this variable is used for concatenation of names of other resources, the value must have less than 23 characters."
  }
}
variable "gitlab_token" {
  description = "Personal access token from GitLab"
  type        = string
  sensitive   = true
  default     = "Di6htGZubyL8PLktyYGW"
}
variable "gitlab_url" {
  description = "The URL of the GitLab repository"
  type        = string
  default     = "https://git.kriolu-kloud.cv"
}
variable "gitlab_branch" {
  description = "The name of branch the GitLab repository, which is going to trigger a new CodePipeline excecution"
  type        = string
}

# -------
# ------- Services of Project -------
variable "rds_db_password" {
  description = "Password for the MySQL database"
  type        = string
}
# -------
# ------- Services of Project -------
variable "port_api_app" {
  description = "The port used by service hermes"
  type        = number
  default     = 4004
}

variable "folder_path_crawler" {
  description = "The location of the crawler files"
  type        = string
  default     = "../services/crawler/."
}

variable "container_name" {
  description = "The name of the container of each ECS service"
  type        = map(string)
  default = {
    app_api        = "container-app-api"
    app_worker     = "container-app-worker"
    app_scheduler  = "container-app-scheduler"
    app_manager    = "container-app-manager"
    app_front      = "container-app-front"
  }
}

variable "port_front_app" {
  description = "The port exposed by the nginx serving app-front"
  type        = number
  default     = 80
}

variable "ec2_key_name" {
  description = "EC2 SSH key pair"
  type        = string
  default     = "kriolu-kloud-use1.pem"
}
