output "access_url" {
  description = "The URL to access the deployed application."
  value       = "https://secure.${var.domain_name}"
}