variable "name" {}
variable "description" {}
variable "image_id" {}
variable "instance_type" {}
variable "key_name" {
  type    = string
  default = ""
}
variable "ebs_optimized" {}
variable "instance_initiated_shutdown_behavior" {}
variable "instance_profile_name" {}
variable "network_interfaces" {
  type = list(object({
    associate_public_ip_address = bool
    security_groups             = list(string)
  }))
}
variable "user_data" {}
variable "metadata_options" {
  type = optional(object({
    http_endpoint               = string
    http_tokens                 = string
    http_put_response_hop_limit = string
    instance_metadata_tags      = string
  }))
  default = {}
}