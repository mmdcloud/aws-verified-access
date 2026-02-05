variable "zone_id" {
  description = "Route53 zone ID"
  type        = string
}

variable "name" {
  description = "DNS record name"
  type        = string
}

variable "type" {
  description = "DNS record type (A, CNAME, etc.)"
  type        = string
}

variable "ttl" {
  description = "Time to live for the DNS record"
  type        = number
  default     = 300
}

variable "records" {
  description = "DNS record values"
  type        = list(string)
}