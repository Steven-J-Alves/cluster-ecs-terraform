data "aws_route53_zone" "public" {
  name = "kriolu-kloud.cv."
}

locals {
  alb_zone_id     = "Z35SXDOTRQ7X7K"
  public_alb_dns  = data.terraform_remote_state.ecs_cluster_main.outputs.alb_dns_public
  private_alb_dns = data.terraform_remote_state.ecs_cluster_main.outputs.alb_dns_private
}

resource "aws_route53_record" "app_front" {
  zone_id         = data.aws_route53_zone.public.zone_id
  name            = "app.kriolu-kloud.cv"
  type            = "A"
  allow_overwrite = true

  alias {
    name                   = local.public_alb_dns
    zone_id                = local.alb_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "app_api" {
  zone_id         = data.aws_route53_zone.public.zone_id
  name            = "app-api.kriolu-kloud.cv"
  type            = "A"
  allow_overwrite = true

  alias {
    name                   = local.private_alb_dns
    zone_id                = local.alb_zone_id
    evaluate_target_health = false
  }
}
