############################
# Core
############################
variable "name" {
  description = "ASG name. Conflicts with name_prefix."
  type        = string
  default     = null
}

variable "name_prefix" {
  description = "ASG name prefix. Conflicts with name."
  type        = string
  default     = null
}

variable "min_size" {
  description = "Minimum number of instances."
  type        = number

  validation {
    condition     = var.min_size >= 0
    error_message = "min_size must be >= 0."
  }
}

variable "max_size" {
  description = "Maximum number of instances."
  type        = number

  validation {
    condition     = var.max_size >= var.min_size
    error_message = "max_size must be >= min_size."
  }
}

variable "desired_capacity" {
  description = "Desired number of instances. Null lets AWS default to min_size on create."
  type        = number
  default     = null
}

variable "desired_capacity_type" {
  description = "Unit for desired_capacity: units, vcpu, or memory-mib. Only for attribute-based instance selection."
  type        = string
  default     = null
}

variable "region" {
  description = "Region override for this resource (requires AWS provider >= 6.0). Null uses the provider region."
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags applied to the ASG (and optionally propagated to instances)."
  type        = map(string)
  default     = {}
}

variable "tag_propagate_at_launch" {
  description = "Propagate ASG tags to launched instances."
  type        = bool
  default     = true
}

############################
# Placement / networking
############################
variable "vpc_zone_identifier" {
  description = "Subnet IDs to launch into. Conflicts with availability_zones."
  type        = list(string)
  default     = null
}

variable "availability_zones" {
  description = "AZs to launch into (default VPC only). Conflicts with vpc_zone_identifier."
  type        = list(string)
  default     = null
}

variable "placement_group" {
  description = "Placement group name for instances."
  type        = string
  default     = null
}

############################
# Launch source (exactly one)
############################
variable "launch_template_id" {
  description = "Launch template ID. Ignored when mixed_instances_policy is set."
  type        = string
  default     = null
}

variable "launch_template_version" {
  description = "Launch template version: number, $Latest, or $Default."
  type        = string
  default     = "$Latest"
}

variable "launch_configuration" {
  description = "Legacy launch configuration name. Deprecated by AWS; prefer launch templates."
  type        = string
  default     = null
}

variable "mixed_instances_policy" {
  description = "Mixed instances / spot policy. Mutually exclusive with launch_template_id."
  type = object({
    instances_distribution = optional(object({
      on_demand_allocation_strategy            = optional(string)
      on_demand_base_capacity                  = optional(number)
      on_demand_percentage_above_base_capacity = optional(number)
      spot_allocation_strategy                 = optional(string)
      spot_instance_pools                      = optional(number)
      spot_max_price                           = optional(string)
    }))
    launch_template = object({
      launch_template_id = string
      version            = optional(string, "$Latest")
      overrides = optional(list(object({
        instance_type     = optional(string)
        weighted_capacity = optional(string)
        launch_template_specification = optional(object({
          launch_template_id = string
          version            = optional(string, "$Latest")
        }))
        instance_requirements = optional(object({
          vcpu_count = object({
            min = number
            max = optional(number)
          })
          memory_mib = object({
            min = number
            max = optional(number)
          })
          allowed_instance_types                                  = optional(list(string))
          excluded_instance_types                                 = optional(list(string))
          cpu_manufacturers                                       = optional(list(string))
          instance_generations                                    = optional(list(string))
          burstable_performance                                   = optional(string)
          bare_metal                                              = optional(string)
          local_storage                                           = optional(string)
          local_storage_types                                     = optional(list(string))
          require_hibernate_support                               = optional(bool)
          spot_max_price_percentage_over_lowest_price             = optional(number)
          on_demand_max_price_percentage_over_lowest_price        = optional(number)
          max_spot_price_as_percentage_of_optimal_on_demand_price = optional(number)
        }))
      })), [])
    })
  })
  default = null
}

############################
# Health / scaling behavior
############################
variable "health_check_type" {
  description = "EC2 or ELB. Null uses the provider default (EC2)."
  type        = string
  default     = null

  validation {
    condition     = var.health_check_type == null || contains(["EC2", "ELB", "VPC_LATTICE"], coalesce(var.health_check_type, "EC2"))
    error_message = "health_check_type must be EC2, ELB, or VPC_LATTICE."
  }
}

variable "health_check_grace_period" {
  description = "Seconds before health checks start after an instance enters service."
  type        = number
  default     = 300
}

variable "default_cooldown" {
  description = "Seconds between scaling activities."
  type        = number
  default     = null
}

variable "default_instance_warmup" {
  description = "Seconds until a new instance contributes to CloudWatch metrics."
  type        = number
  default     = null
}

variable "capacity_rebalance" {
  description = "Enable capacity rebalancing for Spot instances."
  type        = bool
  default     = null
}

variable "protect_from_scale_in" {
  description = "Protect instances from scale-in."
  type        = bool
  default     = false
}

variable "max_instance_lifetime" {
  description = "Max instance lifetime in seconds (0 or 86400-31536000)."
  type        = number
  default     = null
}

variable "termination_policies" {
  description = "Termination policies, e.g. OldestInstance, Default."
  type        = list(string)
  default     = null
}

variable "suspended_processes" {
  description = "Processes to suspend, e.g. AZRebalance, Terminate."
  type        = list(string)
  default     = null
}

variable "ignore_failed_scaling_activities" {
  description = "Ignore failed scaling activities while waiting for capacity."
  type        = bool
  default     = null
}

variable "service_linked_role_arn" {
  description = "Service-linked role ARN used by the ASG."
  type        = string
  default     = null
}

variable "context" {
  description = "Reserved for use by AWS services."
  type        = string
  default     = null
}

############################
# Metrics
############################
variable "enabled_metrics" {
  description = "ASG metrics to collect, e.g. GroupInServiceInstances."
  type        = list(string)
  default     = null
}

variable "metrics_granularity" {
  description = "Metrics granularity. Only valid value is 1Minute."
  type        = string
  default     = "1Minute"
}

############################
# Load balancing
############################
variable "target_group_arns" {
  description = "Target group ARNs to register instances with."
  type        = list(string)
  default     = null
}

variable "load_balancers" {
  description = "Classic ELB names. Deprecated; prefer target groups or traffic_sources."
  type        = list(string)
  default     = null
}

variable "traffic_sources" {
  description = "Traffic sources (ELB/ALB/NLB target groups, VPC Lattice). Preferred over target_group_arns."
  type = list(object({
    identifier = string
    type       = optional(string, "elbv2")
  }))
  default = []
}

variable "min_elb_capacity" {
  description = "Min healthy instances in ELB before create is considered successful."
  type        = number
  default     = null
}

variable "wait_for_elb_capacity" {
  description = "Exact healthy ELB instance count to wait for. Overrides min_elb_capacity."
  type        = number
  default     = null
}

variable "wait_for_capacity_timeout" {
  description = "How long to wait for capacity (e.g. 10m). 0 disables waiting."
  type        = string
  default     = "10m"
}

############################
# Deletion
############################
variable "force_delete" {
  description = "Delete the ASG without waiting for instances to terminate."
  type        = bool
  default     = false
}

variable "force_delete_warm_pool" {
  description = "Delete the warm pool when the ASG is deleted."
  type        = bool
  default     = null
}

############################
# Optional blocks
############################
variable "instance_refresh" {
  description = "Rolling instance refresh settings."
  type = object({
    strategy = string
    triggers = optional(list(string))
    preferences = optional(object({
      min_healthy_percentage       = optional(number)
      max_healthy_percentage       = optional(number)
      instance_warmup              = optional(string)
      auto_rollback                = optional(bool)
      checkpoint_delay             = optional(string)
      checkpoint_percentages       = optional(list(number))
      scale_in_protected_instances = optional(string)
      standby_instances            = optional(string)
      skip_matching                = optional(bool)
    }))
  })
  default = null
}

variable "availability_zone_distribution" {
  description = "How capacity is distributed across AZs."
  type = object({
    capacity_distribution_strategy = optional(string, "balanced-best-effort")
  })
  default = null
}

variable "capacity_reservation_specification" {
  description = "Capacity reservation preferences."
  type = object({
    capacity_reservation_preference = optional(string)
    capacity_reservation_target = optional(object({
      capacity_reservation_ids                 = optional(list(string))
      capacity_reservation_resource_group_arns = optional(list(string))
    }))
  })
  default = null
}

variable "initial_lifecycle_hooks" {
  description = "Lifecycle hooks created with the ASG."
  type = list(object({
    name                    = string
    lifecycle_transition    = string
    default_result          = optional(string)
    heartbeat_timeout       = optional(number)
    notification_metadata   = optional(string)
    notification_target_arn = optional(string)
    role_arn                = optional(string)
  }))
  default = []
}

variable "instance_lifecycle_policy" {
  description = "Instance lifecycle policy (retain on terminate-hook abandon)."
  type = object({
    retention_triggers = object({
      terminate_hook_abandon = string
    })
  })
  default = null
}

variable "instance_maintenance_policy" {
  description = "Healthy percentage bounds during instance replacement."
  type = object({
    min_healthy_percentage = number
    max_healthy_percentage = number
  })
  default = null
}

variable "warm_pool" {
  description = "Warm pool configuration."
  type = object({
    pool_state                  = optional(string, "Stopped")
    min_size                    = optional(number)
    max_group_prepared_capacity = optional(number)
    instance_reuse_policy = optional(object({
      reuse_on_scale_in = optional(bool)
    }))
  })
  default = null
}