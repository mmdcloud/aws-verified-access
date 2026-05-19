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
    condition     = can(regex("^[a-z0-9-]+(\\.[a-z]{2,})+$", var.domain_name))
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