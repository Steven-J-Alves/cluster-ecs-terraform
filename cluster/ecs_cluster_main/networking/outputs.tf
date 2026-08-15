# Public
output "alb_public" {
  value = module.alb_public
}

output "alb_arn_public" {
  value = module.alb_public.alb_arn
}

output "https_listener_arn_public" {
  value = module.alb_public.https_listener_arn
}

output "alb_dns_public" {
  value = module.alb_public.dns_alb
}

# Private
output "alb_private" {
  value = module.alb_private
}

output "alb_arn_private" {
  value = module.alb_private.alb_arn
}

output "https_listener_arn_private" {
  value = module.alb_private.https_listener_arn
}

output "alb_dns_private" {
  value = module.alb_private.dns_alb
}
