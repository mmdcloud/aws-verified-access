variable "instance_name" {
  description = "Name of the Verified Access Instance"
  type        = string
}

variable "instance_description" {
  description = "Description of the Verified Access Instance"
  type        = string
}

variable "trust_provider_policy_reference_name" {
  description = "Policy reference name for trust provider"
  type        = string
  default     = "trustprovider"
}

variable "trust_provider_type" {
  description = "Type of trust provider (user or device)"
  type        = string
  default     = "user"
}

variable "user_trust_provider_type" {
  description = "User trust provider type"
  type        = string
  default     = "iam-identity-center"
}

variable "trust_provider_name" {
  description = "Name for the trust provider"
  type        = string
}

variable "group_description" {
  description = "Description for the Verified Access Group"
  type        = string
}

variable "policy_document" {
  description = "Policy document for the Verified Access Group"
  type        = string
}

variable "application_domain" {
  description = "Application domain for the endpoint"
  type        = string
}

variable "attachment_type" {
  description = "Attachment type for the endpoint"
  type        = string
  default     = "vpc"
}

variable "endpoint_description" {
  description = "Description for the Verified Access Endpoint"
  type        = string
}

variable "domain_certificate_arn" {
  description = "ARN of the ACM certificate"
  type        = string
}

variable "endpoint_domain_prefix" {
  description = "Endpoint domain prefix"
  type        = string
}

variable "endpoint_type" {
  description = "Type of endpoint (load-balancer or network-interface)"
  type        = string
  default     = "load-balancer"
}

variable "load_balancer_arn" {
  description = "ARN of the load balancer"
  type        = string
}

variable "load_balancer_port" {
  description = "Port for the load balancer"
  type        = number
  default     = 80
}

variable "load_balancer_protocol" {
  description = "Protocol for the load balancer"
  type        = string
  default     = "http"
}

variable "subnet_ids" {
  description = "Subnet IDs for the endpoint"
  type        = list(string)
}

variable "security_group_ids" {
  description = "Security group IDs for the endpoint"
  type        = list(string)
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}