# PUBLIC DNS ---------------------------
# resource "aws_route53_record" "pub_hermes_dns" {
#   zone_id = data.aws_route53_zone.private_zone.zone_id
#   name    = "hermes.${data.aws_route53_zone.private_zone.name}"
#   type    = "CNAME"
#   ttl     = "300"
#   records = [data.terraform_remote_state.ecs_cluster_crawler.outputs["alb_dns_public"]]
# }

# PRIVATE DNS ---------------------------
# resource "aws_route53_record" "hermes_dns" {
#   zone_id = data.aws_route53_zone.private_zone.zone_id
#   name    = "pvt-hermes.${data.aws_route53_zone.private_zone.name}"
#   type    = "CNAME"
#   ttl     = "300"
#   records = [data.terraform_remote_state.ecs_cluster_crawler.outputs["alb_dns_private"]]
# }