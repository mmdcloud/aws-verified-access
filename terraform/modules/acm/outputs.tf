output "certificate_arn" {
  description = "ARN of the ACM certificate"
  value       = var.wait_for_validation ? aws_acm_certificate_validation.cert[0].certificate_arn : aws_acm_certificate.acm_certificate.arn
}

output "certificate_id" {
  description = "ID of the ACM certificate"
  value       = aws_acm_certificate.acm_certificate.id
}

output "domain_validation_options" {
  description = "Domain validation options"
  value       = aws_acm_certificate.acm_certificate.domain_validation_options
}