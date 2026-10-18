resource "aws_autoscaling_group" "this" {
  name        = var.name
  name_prefix = var.name_prefix

  min_size                  = var.min_size
  max_size                  = var.max_size
  desired_capacity          = var.desired_capacity
  desired_capacity_type     = var.desired_capacity_type
  health_check_grace_period = var.health_check_grace_period
  health_check_type         = var.health_check_type
  force_delete              = var.force_delete
  force_delete_warm_pool    = var.force_delete_warm_pool
  target_group_arns         = var.target_group_arns
  load_balancers            = var.load_balancers
  vpc_zone_identifier       = var.vpc_zone_identifier
  availability_zones        = var.availability_zones

  capacity_rebalance               = var.capacity_rebalance
  context                          = var.context
  default_cooldown                 = var.default_cooldown
  default_instance_warmup          = var.default_instance_warmup
  enabled_metrics                  = var.enabled_metrics
  metrics_granularity              = var.metrics_granularity
  ignore_failed_scaling_activities = var.ignore_failed_scaling_activities
  launch_configuration             = var.launch_configuration
  max_instance_lifetime            = var.max_instance_lifetime
  min_elb_capacity                 = var.min_elb_capacity
  placement_group                  = var.placement_group
  protect_from_scale_in            = var.protect_from_scale_in
  region                           = var.region
  service_linked_role_arn          = var.service_linked_role_arn
  suspended_processes              = var.suspended_processes
  termination_policies             = var.termination_policies
  wait_for_capacity_timeout        = var.wait_for_capacity_timeout
  wait_for_elb_capacity            = var.wait_for_elb_capacity

  # Plain launch template (mutually exclusive with mixed_instances_policy / launch_configuration)
  dynamic "launch_template" {
    for_each = var.launch_template_id != null && var.mixed_instances_policy == null ? [1] : []
    content {
      id      = var.launch_template_id
      version = var.launch_template_version
    }
  }

  dynamic "mixed_instances_policy" {
    for_each = var.mixed_instances_policy != null ? [var.mixed_instances_policy] : []
    content {
      dynamic "instances_distribution" {
        for_each = mixed_instances_policy.value.instances_distribution != null ? [mixed_instances_policy.value.instances_distribution] : []
        content {
          on_demand_allocation_strategy            = instances_distribution.value.on_demand_allocation_strategy
          on_demand_base_capacity                  = instances_distribution.value.on_demand_base_capacity
          on_demand_percentage_above_base_capacity = instances_distribution.value.on_demand_percentage_above_base_capacity
          spot_allocation_strategy                 = instances_distribution.value.spot_allocation_strategy
          spot_instance_pools                      = instances_distribution.value.spot_instance_pools
          spot_max_price                           = instances_distribution.value.spot_max_price
        }
      }

      launch_template {
        launch_template_specification {
          launch_template_id = mixed_instances_policy.value.launch_template.launch_template_id
          version            = mixed_instances_policy.value.launch_template.version
        }

        dynamic "override" {
          for_each = mixed_instances_policy.value.launch_template.overrides
          content {
            instance_type     = override.value.instance_type
            weighted_capacity = override.value.weighted_capacity

            dynamic "launch_template_specification" {
              for_each = override.value.launch_template_specification != null ? [override.value.launch_template_specification] : []
              content {
                launch_template_id = launch_template_specification.value.launch_template_id
                version            = launch_template_specification.value.version
              }
            }

            dynamic "instance_requirements" {
              for_each = override.value.instance_requirements != null ? [override.value.instance_requirements] : []
              content {
                vcpu_count {
                  min = instance_requirements.value.vcpu_count.min
                  max = instance_requirements.value.vcpu_count.max
                }
                memory_mib {
                  min = instance_requirements.value.memory_mib.min
                  max = instance_requirements.value.memory_mib.max
                }

                allowed_instance_types                                  = instance_requirements.value.allowed_instance_types
                excluded_instance_types                                 = instance_requirements.value.excluded_instance_types
                cpu_manufacturers                                       = instance_requirements.value.cpu_manufacturers
                instance_generations                                    = instance_requirements.value.instance_generations
                burstable_performance                                   = instance_requirements.value.burstable_performance
                bare_metal                                              = instance_requirements.value.bare_metal
                local_storage                                           = instance_requirements.value.local_storage
                local_storage_types                                     = instance_requirements.value.local_storage_types
                require_hibernate_support                               = instance_requirements.value.require_hibernate_support
                spot_max_price_percentage_over_lowest_price             = instance_requirements.value.spot_max_price_percentage_over_lowest_price
                on_demand_max_price_percentage_over_lowest_price        = instance_requirements.value.on_demand_max_price_percentage_over_lowest_price
                max_spot_price_as_percentage_of_optimal_on_demand_price = instance_requirements.value.max_spot_price_as_percentage_of_optimal_on_demand_price
              }
            }
          }
        }
      }
    }
  }

  dynamic "instance_refresh" {
    for_each = var.instance_refresh != null ? [var.instance_refresh] : []
    content {
      strategy = instance_refresh.value.strategy
      triggers = instance_refresh.value.triggers

      dynamic "preferences" {
        for_each = instance_refresh.value.preferences != null ? [instance_refresh.value.preferences] : []
        content {
          min_healthy_percentage       = preferences.value.min_healthy_percentage
          max_healthy_percentage       = preferences.value.max_healthy_percentage
          instance_warmup              = preferences.value.instance_warmup
          auto_rollback                = preferences.value.auto_rollback
          checkpoint_delay             = preferences.value.checkpoint_delay
          checkpoint_percentages       = preferences.value.checkpoint_percentages
          scale_in_protected_instances = preferences.value.scale_in_protected_instances
          standby_instances            = preferences.value.standby_instances
          skip_matching                = preferences.value.skip_matching
        }
      }
    }
  }

  dynamic "availability_zone_distribution" {
    for_each = var.availability_zone_distribution != null ? [var.availability_zone_distribution] : []
    content {
      capacity_distribution_strategy = availability_zone_distribution.value.capacity_distribution_strategy
    }
  }

  dynamic "capacity_reservation_specification" {
    for_each = var.capacity_reservation_specification != null ? [var.capacity_reservation_specification] : []
    content {
      capacity_reservation_preference = capacity_reservation_specification.value.capacity_reservation_preference

      dynamic "capacity_reservation_target" {
        for_each = capacity_reservation_specification.value.capacity_reservation_target != null ? [capacity_reservation_specification.value.capacity_reservation_target] : []
        content {
          capacity_reservation_ids                 = capacity_reservation_target.value.capacity_reservation_ids
          capacity_reservation_resource_group_arns = capacity_reservation_target.value.capacity_reservation_resource_group_arns
        }
      }
    }
  }

  dynamic "initial_lifecycle_hook" {
    for_each = var.initial_lifecycle_hooks
    content {
      name                    = initial_lifecycle_hook.value.name
      lifecycle_transition    = initial_lifecycle_hook.value.lifecycle_transition
      default_result          = initial_lifecycle_hook.value.default_result
      heartbeat_timeout       = initial_lifecycle_hook.value.heartbeat_timeout
      notification_metadata   = initial_lifecycle_hook.value.notification_metadata
      notification_target_arn = initial_lifecycle_hook.value.notification_target_arn
      role_arn                = initial_lifecycle_hook.value.role_arn
    }
  }

  dynamic "instance_lifecycle_policy" {
    for_each = var.instance_lifecycle_policy != null ? [var.instance_lifecycle_policy] : []
    content {
      retention_triggers {
        terminate_hook_abandon = instance_lifecycle_policy.value.retention_triggers.terminate_hook_abandon
      }
    }
  }

  dynamic "instance_maintenance_policy" {
    for_each = var.instance_maintenance_policy != null ? [var.instance_maintenance_policy] : []
    content {
      min_healthy_percentage = instance_maintenance_policy.value.min_healthy_percentage
      max_healthy_percentage = instance_maintenance_policy.value.max_healthy_percentage
    }
  }

  dynamic "warm_pool" {
    for_each = var.warm_pool != null ? [var.warm_pool] : []
    content {
      pool_state                  = warm_pool.value.pool_state
      min_size                    = warm_pool.value.min_size
      max_group_prepared_capacity = warm_pool.value.max_group_prepared_capacity

      dynamic "instance_reuse_policy" {
        for_each = warm_pool.value.instance_reuse_policy != null ? [warm_pool.value.instance_reuse_policy] : []
        content {
          reuse_on_scale_in = instance_reuse_policy.value.reuse_on_scale_in
        }
      }
    }
  }

  dynamic "traffic_source" {
    for_each = var.traffic_sources
    content {
      identifier = traffic_source.value.identifier
      type       = traffic_source.value.type
    }
  }

  dynamic "tag" {
    for_each = var.tags
    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = var.tag_propagate_at_launch
    }
  }

  lifecycle {
    precondition {
      condition     = !(var.name != null && var.name_prefix != null)
      error_message = "Set only one of name or name_prefix."
    }

    precondition {
      condition = length([
        for v in [var.launch_configuration, var.launch_template_id, var.mixed_instances_policy] : v if v != null
      ]) == 1
      error_message = "Set exactly one of launch_template_id, mixed_instances_policy, or launch_configuration."
    }

    precondition {
      condition     = (var.vpc_zone_identifier != null) != (var.availability_zones != null)
      error_message = "Set exactly one of vpc_zone_identifier or availability_zones."
    }
  }
}