variable "domain_name" {
  description = "Primary domain name for the certificate"
  type        = string
}

variable "validation_method" {
  description = "Certificate validation method (DNS or EMAIL)"
  type        = string
  default     = "DNS"
}

variable "subject_alternative_names" {
  description = "Subject Alternative Names for the certificate"
  type        = list(string)
  default     = []
}

variable "route53_zone_id" {
  description = "Route53 zone ID for DNS validation records"
  type        = string
  default     = ""
}

variable "create_validation_records" {
  description = "Whether to create Route53 validation records"
  type        = bool
  default     = true
}

variable "wait_for_validation" {
  description = "Whether to wait for certificate validation"
  type        = bool
  default     = true
}

variable "validation_record_ttl" {
  description = "TTL for validation records"
  type        = number
  default     = 60
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}