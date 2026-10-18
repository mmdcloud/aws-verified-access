resource "aws_launch_template" "template" {
  name                                 = var.name
  description                          = var.description
  image_id                             = var.image_id
  instance_type                        = var.instance_type
  key_name                             = var.key_name
  ebs_optimized                        = var.ebs_optimized
  instance_initiated_shutdown_behavior = var.instance_initiated_shutdown_behavior

  iam_instance_profile {
    name = var.instance_profile_name
  }

  dynamic "network_interfaces" {
    for_each = var.network_interfaces
    content {
      associate_public_ip_address = network_interfaces.value["associate_public_ip_address"]
      security_groups             = network_interfaces.value["security_groups"]
    }
  }

  dynamic "metadata_options" {
    for_each = var.metadata_options != null ? [var.metadata_options] : []
    content {
      http_endpoint               = metadata_options.value.http_endpoint
      http_tokens                 = metadata_options.value.http_tokens
      http_put_response_hop_limit = metadata_options.value.http_put_response_hop_limit
      instance_metadata_tags      = metadata_options.value.instance_metadata_tags
    }
  }

  user_data = var.user_data
}