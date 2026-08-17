# ------- Terraform + Backend -------
terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket         = "kriolu-kloud-terraform-tfstates"
    region         = "us-east-1"
    key            = "apps-terraform/prod/kriolu-kloud-app-us-east-1.tfstate"
    dynamodb_table = "kriolu-kloud-apps-terraform-lock"
  }
}

# ------- ALB + Security/Target Groups -------
module "networking" {
  source    = "./networking"
  base_name = local.base_name

  providers = {
    aws         = aws
  }

  vpc_cidr = data.aws_vpc.crawler_vpc.cidr_block

  kriolu_kloud_vpn = var.kriolu_kloud_vpn

  port_api_app   = var.port_api_app
  port_front_app = var.port_front_app

  data_vpc             = data.aws_vpc.crawler_vpc
  data_public_subnets  = data.aws_subnets.public_subnets
  data_private_subnets = data.aws_subnets.private_subnets
  data_sg_alb_public   = data.aws_security_group.sg_alb_public
  data_sg_alb_private  = data.aws_security_group.sg_alb_private

  data_acm_certificate               = data.aws_acm_certificate.acm_kriolu_kloud
  data_acm_certificate_private       = data.aws_acm_certificate.acm_kriolu_kloud_private

  # Public load balancer host path rules 
  # listener_rules = {
  #   "rule1" = {
  #     priority         = 112
  #     target_group_arn = module.networking.target_group_panhador_admin_pub.arn_tg
  #     host_header      = "panhador-admin.kriolu-kloud.cv"
  #   }
  #   "rule2" = {
  #     priority         = 113
  #     target_group_arn = module.networking.target_group_panhador_client_pub.arn_tg
  #     host_header      = "panhador-client.kriolu-kloud.cv"
  #   }
  #   "rule3" = {
  #     priority         = 114
  #     target_group_arn = module.networking.target_group_panhador_home_pub.arn_tg
  #     host_header      = "panhador-home.kriolu-kloud.cv"
  #   }
  # }

  # Private load balancer host path rules 
 listener_rules_private = {
    "rule1" = {
      priority         = 184
      target_group_arn = module.networking.target_group_app_api_pvt.arn_tg
      host_header      = "app-api.kriolu-kloud.cv"
    }
    "rule2" = {
      priority         = 185
      target_group_arn = module.networking.target_group_app_front_pvt.arn_tg
      host_header      = "app.kriolu-kloud.cv"
    }
  }
}

# -------
# ------- ECR Containers -------
module "ecr_repositories" {
  source    = "./ecr"
  base_name = local.base_name
}

# -------
# ------- ECS Clusters -------
module "ecs_clusters" {
  source           = "./ecs"
  service_name     = var.service_name
  base_name        = local.base_name
  environment_name = var.environment_name

  aws_region = var.aws_region

  networking           = module.networking
  data_private_subnets = data.aws_subnets.private_subnets

  sg_ssh = data.aws_security_group.sg_ssh_private

  ecs_role        = module.ecs_role
  ecs_role_policy = module.ecs_role_policy

  container_name = var.container_name

  ecr_repositories = module.ecr_repositories

  port_api_app   = var.port_api_app
  port_front_app = var.port_front_app

  ec2_key_name = var.ec2_key_name
  tags         = local.common_tags
}

module "rds_pg_cluster_app" {
  source = "../../modules/postgres"
  identifier                 = "${local.base_name}-pg"
  instance_identifier_suffix = "db"
  promotion_tier             = 1
  monitoring_interval        = 0
  database                   = "app"
  username                   = "app_user"
  engine                     = "aurora-postgresql"
  engine_version             = "17.7"
  aws_zones                  = slice(data.aws_availability_zones.awz_zones.names, 0, 3)
  instance_class             = "db.t4g.large"
  password                   = var.rds_db_password
  publicly_accessible        = false
  vpc_id                     = data.aws_vpc.crawler_vpc.id
  subnets_id                 = data.aws_subnets.private_subnets.ids
  security_group_ids         = [data.aws_security_group.sg_data_private.id]
}


