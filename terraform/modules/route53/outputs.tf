output "fqdn" {
  description = "Fully qualified domain name"
  value       = aws_route53_record.record.fqdn
}

output "name" {
  description = "DNS record name"
  value       = aws_route53_record.record.name
}