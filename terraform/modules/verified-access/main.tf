resource "aws_verifiedaccess_instance" "instance" {
  description = var.instance_description
  tags        = merge(var.tags, { Name = var.instance_name })
}

resource "aws_verifiedaccess_trust_provider" "trust_provider" {
  policy_reference_name    = var.trust_provider_policy_reference_name
  trust_provider_type      = var.trust_provider_type
  user_trust_provider_type = var.user_trust_provider_type

  tags = merge(var.tags, { Name = var.trust_provider_name })
}

resource "aws_verifiedaccess_instance_trust_provider_attachment" "attachment" {
  verifiedaccess_instance_id       = aws_verifiedaccess_instance.instance.id
  verifiedaccess_trust_provider_id = aws_verifiedaccess_trust_provider.trust_provider.id
}

resource "aws_verifiedaccess_group" "group" {
  description                = var.group_description
  verifiedaccess_instance_id = aws_verifiedaccess_instance.instance.id
  policy_document            = var.policy_document

  depends_on = [
    aws_verifiedaccess_instance_trust_provider_attachment.attachment
  ]

  tags = var.tags
}

resource "aws_verifiedaccess_endpoint" "endpoint" {
  application_domain     = var.application_domain
  attachment_type        = var.attachment_type
  description            = var.endpoint_description
  domain_certificate_arn = var.domain_certificate_arn
  endpoint_domain_prefix = var.endpoint_domain_prefix
  endpoint_type          = var.endpoint_type

  load_balancer_options {
    load_balancer_arn = var.load_balancer_arn
    port              = var.load_balancer_port
    protocol          = var.load_balancer_protocol
    subnet_ids        = var.subnet_ids
  }

  security_group_ids       = var.security_group_ids
  verified_access_group_id = aws_verifiedaccess_group.group.id

  tags = var.tags
}