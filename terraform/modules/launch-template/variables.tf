############################
# Core
############################
variable "name" {
  description = "Launch template name. Conflicts with name_prefix."
  type        = string
  default     = null
}

variable "name_prefix" {
  description = "Launch template name prefix. Conflicts with name."
  type        = string
  default     = null
}

variable "description" {
  description = "Launch template description."
  type        = string
  default     = null
}

variable "region" {
  description = "Region override for this resource (requires AWS provider >= 6.0). Null uses the provider region."
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags on the launch template itself. Use tag_specifications to tag launched resources."
  type        = map(string)
  default     = {}
}

variable "default_version" {
  description = "Default version number. Conflicts with update_default_version."
  type        = number
  default     = null
}

variable "update_default_version" {
  description = "Set the new version as default on every update. Conflicts with default_version."
  type        = bool
  default     = null
}

############################
# Instance
############################
variable "image_id" {
  description = "AMI ID."
  type        = string
  default     = null
}

variable "instance_type" {
  description = "Instance type. Conflicts with instance_requirements."
  type        = string
  default     = null
}

variable "key_name" {
  description = "EC2 key pair name."
  type        = string
  default     = null
}

variable "ebs_optimized" {
  description = "Launch EBS-optimized instances."
  type        = bool
  default     = null
}

variable "instance_initiated_shutdown_behavior" {
  description = "Behavior on OS-level shutdown: stop or terminate."
  type        = string
  default     = null

  validation {
    condition     = var.instance_initiated_shutdown_behavior == null ? true : contains(["stop", "terminate"], var.instance_initiated_shutdown_behavior)
    error_message = "instance_initiated_shutdown_behavior must be stop or terminate."
  }
}

variable "disable_api_stop" {
  description = "Enable stop protection."
  type        = bool
  default     = null
}

variable "disable_api_termination" {
  description = "Enable termination protection."
  type        = bool
  default     = null
}

variable "kernel_id" {
  description = "Kernel ID (paravirtual AMIs only)."
  type        = string
  default     = null
}

variable "ram_disk_id" {
  description = "RAM disk ID (paravirtual AMIs only)."
  type        = string
  default     = null
}

variable "user_data" {
  description = "Plain-text user data. The module base64-encodes it; do not pass pre-encoded data."
  type        = string
  default     = null
}

############################
# IAM
############################
variable "instance_profile_name" {
  description = "IAM instance profile name. Conflicts with instance_profile_arn."
  type        = string
  default     = null
}

variable "instance_profile_arn" {
  description = "IAM instance profile ARN. Conflicts with instance_profile_name."
  type        = string
  default     = null
}

############################
# Security groups
############################
variable "vpc_security_group_ids" {
  description = "Security group IDs. Cannot be combined with network_interfaces or security_group_names."
  type        = list(string)
  default     = null
}

variable "security_group_names" {
  description = "Security group names (default VPC / EC2-Classic only)."
  type        = list(string)
  default     = null
}

############################
# Blocks
############################
variable "block_device_mappings" {
  description = "Block device mappings."
  type = list(object({
    device_name  = optional(string)
    no_device    = optional(string)
    virtual_name = optional(string)
    ebs = optional(object({
      delete_on_termination      = optional(bool)
      encrypted                  = optional(bool)
      iops                       = optional(number)
      kms_key_id                 = optional(string)
      snapshot_id                = optional(string)
      throughput                 = optional(number)
      volume_initialization_rate = optional(number)
      volume_size                = optional(number)
      volume_type                = optional(string)
    }))
  }))
  default = []
}

variable "capacity_reservation_specification" {
  description = "Capacity reservation targeting."
  type = object({
    capacity_reservation_preference = optional(string)
    capacity_reservation_target = optional(object({
      capacity_reservation_id                 = optional(string)
      capacity_reservation_resource_group_arn = optional(string)
    }))
  })
  default = null
}

variable "cpu_options" {
  description = "CPU options."
  type = object({
    amd_sev_snp      = optional(string)
    core_count       = optional(number)
    threads_per_core = optional(number)
  })
  default = null
}

variable "credit_specification" {
  description = "Burstable credit option: standard or unlimited."
  type = object({
    cpu_credits = optional(string)
  })
  default = null
}

variable "enclave_options" {
  description = "Nitro Enclaves."
  type = object({
    enabled = bool
  })
  default = null
}

variable "hibernation_options" {
  description = "Hibernation."
  type = object({
    configured = bool
  })
  default = null
}

variable "instance_market_options" {
  description = "Spot / market options."
  type = object({
    market_type = optional(string)
    spot_options = optional(object({
      block_duration_minutes         = optional(number)
      instance_interruption_behavior = optional(string)
      max_price                      = optional(string)
      spot_instance_type             = optional(string)
      valid_until                    = optional(string)
    }))
  })
  default = null
}

variable "instance_requirements" {
  description = "Attribute-based instance selection. Conflicts with instance_type."
  type = object({
    vcpu_count = object({
      min = number
      max = optional(number)
    })
    memory_mib = object({
      min = number
      max = optional(number)
    })
    accelerator_count = optional(object({
      min = optional(number)
      max = optional(number)
    }))
    accelerator_total_memory_mib = optional(object({
      min = optional(number)
      max = optional(number)
    }))
    baseline_ebs_bandwidth_mbps = optional(object({
      min = optional(number)
      max = optional(number)
    }))
    memory_gib_per_vcpu = optional(object({
      min = optional(number)
      max = optional(number)
    }))
    network_bandwidth_gbps = optional(object({
      min = optional(number)
      max = optional(number)
    }))
    network_interface_count = optional(object({
      min = optional(number)
      max = optional(number)
    }))
    total_local_storage_gb = optional(object({
      min = optional(number)
      max = optional(number)
    }))
    accelerator_manufacturers                               = optional(list(string))
    accelerator_names                                       = optional(list(string))
    accelerator_types                                       = optional(list(string))
    allowed_instance_types                                  = optional(list(string))
    bare_metal                                              = optional(string)
    burstable_performance                                   = optional(string)
    cpu_manufacturers                                       = optional(list(string))
    excluded_instance_types                                 = optional(list(string))
    instance_generations                                    = optional(list(string))
    local_storage                                           = optional(string)
    local_storage_types                                     = optional(list(string))
    max_spot_price_as_percentage_of_optimal_on_demand_price = optional(number)
    on_demand_max_price_percentage_over_lowest_price        = optional(number)
    require_hibernate_support                               = optional(bool)
    spot_max_price_percentage_over_lowest_price             = optional(number)
  })
  default = null
}

variable "license_specifications" {
  description = "License configurations to associate."
  type = list(object({
    license_configuration_arn = string
  }))
  default = []
}

variable "maintenance_options" {
  description = "Auto recovery behavior: default or disabled."
  type = object({
    auto_recovery = optional(string)
  })
  default = null
}

variable "metadata_options" {
  description = "Instance metadata service (IMDS) options."
  type = object({
    http_endpoint               = optional(string)
    http_protocol_ipv6          = optional(string)
    http_tokens                 = optional(string)
    http_put_response_hop_limit = optional(number)
    instance_metadata_tags      = optional(string)
  })
  default = null

  validation {
    condition     = var.metadata_options == null ? true : (var.metadata_options.http_tokens == null ? true : contains(["optional", "required"], var.metadata_options.http_tokens))
    error_message = "metadata_options.http_tokens must be optional or required."
  }
}

variable "monitoring" {
  description = "Detailed CloudWatch monitoring."
  type = object({
    enabled = optional(bool)
  })
  default = null
}

variable "network_interfaces" {
  description = "Network interfaces. Cannot be combined with vpc_security_group_ids."
  type = list(object({
    associate_carrier_ip_address = optional(bool)
    associate_public_ip_address  = optional(bool)
    delete_on_termination        = optional(bool)
    description                  = optional(string)
    device_index                 = optional(number)
    interface_type               = optional(string)
    ipv4_address_count           = optional(number)
    ipv4_addresses               = optional(list(string))
    ipv4_prefix_count            = optional(number)
    ipv4_prefixes                = optional(list(string))
    ipv6_address_count           = optional(number)
    ipv6_addresses               = optional(list(string))
    ipv6_prefix_count            = optional(number)
    ipv6_prefixes                = optional(list(string))
    network_card_index           = optional(number)
    network_interface_id         = optional(string)
    primary_ipv6                 = optional(bool)
    private_ip_address           = optional(string)
    security_groups              = optional(list(string))
    subnet_id                    = optional(string)
    connection_tracking_specification = optional(object({
      tcp_established_timeout = optional(number)
      udp_stream_timeout      = optional(number)
      udp_timeout             = optional(number)
    }))
    ena_srd_specification = optional(object({
      ena_srd_enabled     = optional(bool)
      ena_srd_udp_enabled = optional(bool)
    }))
  }))
  default = []
}

variable "network_performance_options" {
  description = "Bandwidth weighting: default, vpc-1, or ebs-1."
  type = object({
    bandwidth_weighting = optional(string)
  })
  default = null
}

variable "placement" {
  description = "Placement options."
  type = object({
    affinity                = optional(string)
    availability_zone       = optional(string)
    group_id                = optional(string)
    group_name              = optional(string)
    host_id                 = optional(string)
    host_resource_group_arn = optional(string)
    partition_number        = optional(number)
    spread_domain           = optional(string)
    tenancy                 = optional(string)
  })
  default = null
}

variable "private_dns_name_options" {
  description = "Private DNS name options."
  type = object({
    enable_resource_name_dns_a_record    = optional(bool)
    enable_resource_name_dns_aaaa_record = optional(bool)
    hostname_type                        = optional(string)
  })
  default = null
}

variable "secondary_interfaces" {
  description = "Secondary interfaces (newer provider versions only)."
  type = list(object({
    delete_on_termination    = optional(bool)
    device_index             = optional(number)
    interface_type           = optional(string)
    network_card_index       = optional(number)
    private_ip_address_count = optional(number)
    secondary_subnet_id      = optional(string)
  }))
  default = []
}

variable "tag_specifications" {
  description = "Tags applied to resources created at launch (instance, volume, network-interface, spot-instances-request)."
  type = list(object({
    resource_type = string
    tags          = optional(map(string), {})
  }))
  default = []
}