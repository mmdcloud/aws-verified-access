output "id" {
  description = "ASG ID (same as name)."
  value       = aws_autoscaling_group.this.id
}

output "arn" {
  description = "ASG ARN."
  value       = aws_autoscaling_group.this.arn
}

output "name" {
  description = "ASG name."
  value       = aws_autoscaling_group.this.name
}

output "min_size" {
  description = "Configured minimum size."
  value       = aws_autoscaling_group.this.min_size
}

output "max_size" {
  description = "Configured maximum size."
  value       = aws_autoscaling_group.this.max_size
}

output "desired_capacity" {
  description = "Current desired capacity."
  value       = aws_autoscaling_group.this.desired_capacity
}

output "availability_zones" {
  description = "AZs the ASG launches into."
  value       = aws_autoscaling_group.this.availability_zones
}

output "vpc_zone_identifier" {
  description = "Subnet IDs the ASG launches into."
  value       = aws_autoscaling_group.this.vpc_zone_identifier
}

output "health_check_type" {
  description = "Health check type in effect."
  value       = aws_autoscaling_group.this.health_check_type
}

output "target_group_arns" {
  description = "Attached target group ARNs."
  value       = aws_autoscaling_group.this.target_group_arns
}

output "load_balancers" {
  description = "Attached classic load balancer names."
  value       = aws_autoscaling_group.this.load_balancers
}

output "predicted_capacity" {
  description = "Predicted capacity from predictive scaling, if enabled."
  value       = aws_autoscaling_group.this.predicted_capacity
}

output "warm_pool_size" {
  description = "Current warm pool size."
  value       = aws_autoscaling_group.this.warm_pool_size
}
