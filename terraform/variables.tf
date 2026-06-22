variable "region" {
  type        = string
  description = "AWS region to deploy into"
}

variable "instance_name" {
  type        = string
  description = "Name for the Verified Access instance"
}

variable "domain_name" {
  type        = string
  description = "Root domain name — must be a hosted zone in Route53"
  validation {
    condition     = can(regex("^[a-z0-9-]+(\\.[a-z]{2,})+$", lower(var.domain_name)))
    error_message = "domain_name must be a valid domain (e.g. example.com)"
  }
}

variable "public_subnets" {
  type        = list(string)
  description = "CIDR blocks for public subnets"
}

variable "private_subnets" {
  type        = list(string)
  description = "CIDR blocks for private subnets"
}

variable "azs" {
  type        = list(string)
  description = "Availability zones to deploy into"
}

variable "is_production" {
  type        = bool
  description = "Set to true for production — enables deletion protection and disables force_delete"
  default     = false
}

variable "instance_type" {
  type        = string
  default     = "t3.small"
  description = "EC2 instance type for the ASG launch template"
}

variable "min_size" {
  type        = number
  default     = 1
  description = "Min instance size of the Auto Scaling Group Template"
}

variable "max_size" {
  type        = number
  description = "Max instance size of the Auto Scaling Group Template"
  validation {
    condition     = var.max_size >= var.min_size
    error_message = "max_size must be >= min_size"
  }
}

variable "desired_capacity" {
  type        = number
  default     = 1
  description = "Desired capacity for the ASG launch template"
}

variable "retention_in_days" {
  type        = number
  default     = 0
  description = "Retention days for verified access log group"
}

variable "ec2_role" {
  type        = string
  description = "IAM role for the Auto Scaling Group"
}
