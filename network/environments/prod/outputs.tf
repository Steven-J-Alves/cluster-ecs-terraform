output "acm_certificate_arn" {
  description = "ARN of the wildcard ACM certificate for kriolu-kloud.cv"
  value       = module.vpc_main.acm_certificate_arn
}
