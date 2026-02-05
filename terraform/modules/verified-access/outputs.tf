output "instance_id" {
  description = "ID of the Verified Access Instance"
  value       = aws_verifiedaccess_instance.instance.id
}

output "trust_provider_id" {
  description = "ID of the Verified Access Trust Provider"
  value       = aws_verifiedaccess_trust_provider.trust_provider.id
}

output "group_id" {
  description = "ID of the Verified Access Group"
  value       = aws_verifiedaccess_group.group.id
}

output "endpoint_id" {
  description = "ID of the Verified Access Endpoint"
  value       = aws_verifiedaccess_endpoint.endpoint.id
}

output "endpoint_domain" {
  description = "Domain of the Verified Access Endpoint"
  value       = aws_verifiedaccess_endpoint.endpoint.endpoint_domain
}