output "id" {
  description = "Launch template ID. Feed this to the ASG module's launch_template_id."
  value       = aws_launch_template.this.id
}

output "arn" {
  description = "Launch template ARN."
  value       = aws_launch_template.this.arn
}

output "name" {
  description = "Launch template name."
  value       = aws_launch_template.this.name
}

output "latest_version" {
  description = "Latest version number."
  value       = aws_launch_template.this.latest_version
}

output "default_version" {
  description = "Default version number."
  value       = aws_launch_template.this.default_version
}

output "tags_all" {
  description = "All tags, including provider default_tags."
  value       = aws_launch_template.this.tags_all
}