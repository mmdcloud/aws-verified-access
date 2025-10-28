# -----------------------------------------------------------------------------------------
# VPC Configuration
# -----------------------------------------------------------------------------------------
module "vpc" {
  source                  = "./modules/vpc"
  vpc_name                = "vpc"
  vpc_cidr                = "10.0.0.0/16"
  azs                     = var.azs
  public_subnets          = var.public_subnets
  private_subnets         = var.private_subnets
  enable_dns_hostnames    = true
  enable_dns_support      = true
  create_igw              = true
  map_public_ip_on_launch = true
  enable_nat_gateway      = true
  single_nat_gateway      = false
  one_nat_gateway_per_az  = true
  tags = {
    Project = "nodeapp"
  }
}

resource "aws_security_group" "lb_sg" {
  name   = "lb-sg"
  vpc_id = module.vpc.vpc_id

  ingress {
    description = "HTTP traffic"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS traffic"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "lb-sg"
  }
}

resource "aws_security_group" "asg_sg" {
  name   = "asg-sg"
  vpc_id = module.vpc.vpc_id

  ingress {
    description     = "HTTP traffic"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    cidr_blocks     = []
    security_groups = [aws_security_group.lb_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "asg-sg"
  }
}

# -------------------------------------------------------------------------------
# Auto Scaling Group
# -------------------------------------------------------------------------------
resource "aws_iam_role" "ec2_role" {
  name = "ec2-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_instance_profile" "iam_instance_profile" {
  name = "ec2-instance-profile"
  role = aws_iam_role.ec2_role.name
}

# Instance template
module "launch_template" {
  source                               = "./modules/launch_template"
  name                                 = "launch_template"
  description                          = "launch_template"
  ebs_optimized                        = false
  image_id                             = "ami-005fc0f236362e99f"
  instance_type                        = "t2.micro"
  instance_initiated_shutdown_behavior = "stop"
  instance_profile_name                = aws_iam_instance_profile.iam_instance_profile.name
  key_name                             = "madmaxkeypair"
  network_interfaces = [
    {
      associate_public_ip_address = false
      security_groups             = [module.asg_sg.id]
    }
  ]
  user_data = base64encode(templatefile("${path.module}/scripts/user_data.sh", {}))
}

# Auto Scaling Group for launch template
module "asg" {
  source                    = "./modules/auto_scaling_group"
  name                      = "asg"
  min_size                  = 3
  max_size                  = 50
  desired_capacity          = 3
  health_check_grace_period = 300
  health_check_type         = "ELB"
  force_delete              = true
  target_group_arns         = [module.lb.target_groups[0].arn]
  vpc_zone_identifier       = module.vpc.private_subnets
  launch_template_id        = module.launch_template.id
  launch_template_version   = "$Latest"
}

# -------------------------------------------------------------------------------
# Load Balancer
# -------------------------------------------------------------------------------
module "lb" {
  source                     = "./modules/load-balancer"
  lb_name                    = "lb"
  lb_is_internal             = false
  lb_ip_address_type         = "ipv4"
  load_balancer_type         = "application"
  enable_deletion_protection = false
  security_groups            = [module.lb_sg.id]
  subnets                    = module.vpc.public_subnets
  target_groups = [
    {
      target_group_name                = "tg"
      target_port                      = 80
      target_ip_address_type           = "ipv4"
      target_protocol                  = "HTTP"
      target_type                      = "instance"
      target_vpc_id                    = module.vpc.vpc_id
      health_check_interval            = 30
      health_check_path                = "/"
      health_check_enabled             = true
      health_check_protocol            = "HTTP"
      health_check_timeout             = 5
      health_check_healthy_threshold   = 3
      health_check_unhealthy_threshold = 3
      health_check_port                = 80
    }
  ]
  listeners = [
    {
      listener_port     = 80
      listener_protocol = "HTTP"
      default_actions = [
        {
          type             = "forward"
          target_group_arn = module.lb.target_groups[0].arn
        }
      ]
    }
  ]
}

# -------------------------------------------------------------------------------
# ACM Certificate
# -------------------------------------------------------------------------------
resource "aws_acm_certificate" "acm_certificate" {
  domain_name       = "mohitcloud.xyz"
  validation_method = "DNS"

  subject_alternative_names = ["*.mohitcloud.xyz", "secure.mohitcloud.xyz"]

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name = "mohitcloud-certificate"
  }
}

# -------------------------------------------------------------------------------
# AWS Verified Access Instance
# -------------------------------------------------------------------------------
resource "aws_verifiedaccess_instance" "instance" {
  description = var.instance_name
  tags = {
    Name = var.instance_name
  }
}

# -------------------------------------------------------------------------------
# AWS Verified Access Trust Provider
# -------------------------------------------------------------------------------
resource "aws_verifiedaccess_trust_provider" "trust_provider" {
  policy_reference_name    = "trust-provider"
  trust_provider_type      = "user"
  user_trust_provider_type = "iam-identity-center"
}

# -------------------------------------------------------------------------------
# Trust Provider Attachment
# -------------------------------------------------------------------------------
resource "aws_verifiedaccess_instance_trust_provider_attachment" "attachment" {
  verifiedaccess_instance_id       = aws_verifiedaccess_instance.instance.id
  verifiedaccess_trust_provider_id = aws_verifiedaccess_trust_provider.trust_provider.id
}

# -------------------------------------------------------------------------------
# AWS Verified Access Group
# -------------------------------------------------------------------------------
resource "aws_verifiedaccess_group" "group" {
  description                = "verified-access-group"
  verifiedaccess_instance_id = aws_verifiedaccess_instance.instance.id
}

# -------------------------------------------------------------------------------
# AWS Verified Access Endpoint
# -------------------------------------------------------------------------------
resource "aws_verifiedaccess_endpoint" "endpoint" {
  application_domain     = var.domain_name
  attachment_type        = "vpc"
  description            = "Verified Access Endpoint"
  domain_certificate_arn = aws_acm_certificate.acm_certificate.arn
  endpoint_domain_prefix = "secure"
  endpoint_type          = "load-balancer"

  load_balancer_options {
    load_balancer_arn = module.lb.arn
    port              = 80
    protocol          = "http"
    subnet_ids        = module.vpc.public_subnets
  }

  security_group_ids       = [module.lb_sg.id]
  verified_access_group_id = aws_verifiedaccess_group.group.id
}
