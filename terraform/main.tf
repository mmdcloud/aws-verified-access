resource "aws_verifiedaccess_instance" "example" {
  description = "example"

  tags = {
    Name = "example"
  }
}

resource "aws_verifiedaccess_trust_provider" "example" {
  policy_reference_name    = "example"
  trust_provider_type      = "user"
  user_trust_provider_type = "iam-identity-center"
}

resource "aws_verifiedaccess_group" "example" {
  verifiedaccess_instance_id = aws_verifiedaccess_instance.example.id
}

resource "aws_verifiedaccess_endpoint" "example" {
  application_domain     = "example.com"
  attachment_type        = "vpc"
  description            = "example"
  domain_certificate_arn = aws_acm_certificate.example.arn
  endpoint_domain_prefix = "example"
  endpoint_type          = "load-balancer"
  load_balancer_options {
    load_balancer_arn = aws_lb.example.arn
    port              = 443
    protocol          = "https"
    subnet_ids        = [for subnet in aws_subnet.public : subnet.id]
  }
  security_group_ids       = [aws_security_group.example.id]
  verified_access_group_id = aws_verifiedaccess_group.example.id
}