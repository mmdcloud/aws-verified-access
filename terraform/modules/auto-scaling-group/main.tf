resource "aws_autoscaling_group" "asg" {
  name                      = var.name
  min_size                  = var.min_size
  max_size                  = var.max_size
  desired_capacity          = var.desired_capacity
  health_check_grace_period = var.health_check_grace_period
  health_check_type         = var.health_check_type
  force_delete              = var.force_delete
  target_group_arns         = var.target_group_arns
  vpc_zone_identifier       = var.vpc_zone_identifier

  launch_template {
    id      = var.launch_template_id
    version = var.launch_template_version
  }

  dynamic "instance_refresh" {
    for_each = var.instance_refresh != null ? [var.instance_refresh] : []
    content {
      strategy = instance_refresh.value.strategy

      dynamic "preferences" {
        for_each = instance_refresh.value.preferences != null ? [instance_refresh.value.preferences] : []
        content {
          min_healthy_percentage = preferences.value.min_healthy_percentage
          instance_warmup        = preferences.value.instance_warmup
        }
      }

      triggers = instance_refresh.value.triggers
    }
  }
}