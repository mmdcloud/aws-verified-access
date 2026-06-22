output "verified_access_endpoint" {
  description = "The domain users visit to access the application"
  value       = "https://secure.${var.domain_name}"
}

output "alb_dns_name" {
  description = "Internal ALB DNS name" 
  value = module.lb.dns_name
}

output "certificate_arn" {
  description = "ARN of the SSL/TLS Certificate" 
  value = module.acm_certificate.certificate_arn
}