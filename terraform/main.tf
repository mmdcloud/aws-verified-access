data "aws_elb_service_account" "elb_service_account" {}

resource "random_id" "id" {
  byte_length = 8
}

data "aws_route53_zone" "main" {
  name         = var.domain_name
  private_zone = false
}

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

module "lb_sg" {
  source = "./modules/security-groups"
  name   = "lb-sg"
  vpc_id = module.vpc.vpc_id
  ingress_rules = [
    {
      description     = "HTTP Traffic"
      from_port       = 80
      to_port         = 80
      protocol        = "tcp"
      security_groups = []
      cidr_blocks     = ["0.0.0.0/0"]
    },
    {
      description     = "HTTPS Traffic"
      from_port       = 443
      to_port         = 443
      protocol        = "tcp"
      security_groups = []
      cidr_blocks     = ["0.0.0.0/0"]
    }
  ]
  egress_rules = [
    {
      description = "Allow all outbound traffic"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }
  ]
  tags = {
    Name = "lb-sg"
  }
}

module "asg_sg" {
  source = "./modules/security-groups"
  name   = "asg-sg"
  vpc_id = module.vpc.vpc_id
  ingress_rules = [
    {
      description     = "HTTP Traffic"
      from_port       = 80
      to_port         = 80
      protocol        = "tcp"
      security_groups = [module.lb_sg.id]
      cidr_blocks     = []
    }
  ]
  egress_rules = [
    {
      description = "Allow all outbound traffic"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }
  ]
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
  target_group_arns         = [module.lb.target_groups.lb_target_group.arn]
  vpc_zone_identifier       = module.vpc.private_subnets
  launch_template_id        = module.launch_template.id
  launch_template_version   = "$Latest"
}

# -------------------------------------------------------------------------------
# Load Balancer
# -------------------------------------------------------------------------------
module "lb_logs" {
  source      = "./modules/s3"
  bucket_name = "lb-logs-${random_id.id.hex}"
  region      = var.region
  objects     = []
  bucket_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AWSLogDeliveryWrite"
        Effect = "Allow"
        Principal = {
          Service = "logging.s3.amazonaws.com"
        }
        Action   = "s3:PutObject"
        Resource = "arn:aws:s3:::lb-logs-${random_id.id.hex}/*"
      },
      {
        Sid    = "AWSLogDeliveryAclCheck"
        Effect = "Allow"
        Principal = {
          Service = "logging.s3.amazonaws.com"
        }
        Action   = "s3:GetBucketAcl"
        Resource = "arn:aws:s3:::lb-logs-${random_id.id.hex}"
      },
      {
        Sid    = "AWSELBAccountWrite"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_elb_service_account.elb_service_account.id}:root"
        }
        Action   = "s3:PutObject"
        Resource = "arn:aws:s3:::lb-logs-${random_id.id.hex}/*"
      }
    ]
  })
  cors = [
    {
      allowed_headers = ["*"]
      allowed_methods = ["GET"]
      allowed_origins = ["*"]
      max_age_seconds = 3000
    },
    {
      allowed_headers = ["*"]
      allowed_methods = ["PUT"]
      allowed_origins = ["*"]
      max_age_seconds = 3000
    }
  ]
  versioning_enabled = "Enabled"
  force_destroy      = true
}

module "lb" {
  source                     = "terraform-aws-modules/alb/aws"
  name                       = "lb"
  load_balancer_type         = "application"
  vpc_id                     = module.vpc.vpc_id
  subnets                    = module.vpc.private_subnets
  enable_deletion_protection = false
  drop_invalid_header_fields = true
  ip_address_type            = "ipv4"
  internal                   = true
  security_groups = [
    module.lb_sg.id
  ]
  access_logs = {
    bucket = "${module.lb_logs.bucket}"
  }
  listeners = {
    lb_http_listener = {
      port     = 80
      protocol = "HTTP"
      forward = {
        target_group_key = "lb_target_group"
      }
    }
  }
  target_groups = {
    lb_target_group = {
      backend_protocol = "HTTP"
      backend_port     = 80
      target_type      = "instance"
      health_check = {
        enabled             = true
        healthy_threshold   = 3
        interval            = 30
        path                = "/"
        port                = 80
        protocol            = "HTTP"
        unhealthy_threshold = 3
      }
      create_attachment = false
    }
  }
  tags = {
    Project = "verified-access"
  }
}

# -------------------------------------------------------------------------------
# ACM Certificate
# -------------------------------------------------------------------------------
module "acm_certificate" {
  source                    = "./modules/acm"
  domain_name               = "secure.${var.domain_name}"
  validation_method         = "DNS"
  subject_alternative_names = ["*.${var.domain_name}"]
  route53_zone_id           = data.aws_route53_zone.main.zone_id
  create_validation_records = true
  wait_for_validation       = true
  validation_record_ttl     = 60
  tags = {
    Name = "${var.domain_name}-certificate"
  }
}

# -------------------------------------------------------------------------------
# AWS Verified Access
# -------------------------------------------------------------------------------
module "verified_access" {
  source                               = "./modules/verified-access"
  instance_name                        = var.instance_name
  instance_description                 = var.instance_name
  trust_provider_policy_reference_name = "trustprovider"
  trust_provider_type                  = "user"
  user_trust_provider_type             = "iam-identity-center"
  trust_provider_name                  = "iam-identity-center-trust-provider"
  group_description                    = "verified-access-group"
  policy_document                      = <<-EOT
    permit(principal, action, resource)
    when {
      context.trustprovider.user.email.verified == true &&
      context.trustprovider.user.email.address like "*@*"
    };
  EOT
  application_domain                   = "secure.${var.domain_name}"
  attachment_type                      = "vpc"
  endpoint_description                 = "Verified Access Endpoint"
  domain_certificate_arn               = module.acm_certificate.certificate_arn
  endpoint_domain_prefix               = "secure"
  endpoint_type                        = "load-balancer"
  load_balancer_arn                    = module.lb.arn
  load_balancer_port                   = 80
  load_balancer_protocol               = "http"
  subnet_ids                           = module.vpc.private_subnets
  security_group_ids                   = [module.lb_sg.id]
  tags = {
    Project = "verified-access"
  }
}

# -------------------------------------------------------------------------------
# Route53 DNS Record for Verified Access
# -------------------------------------------------------------------------------
module "verified_access_dns" {
  source  = "./modules/route53"
  zone_id = data.aws_route53_zone.main.zone_id
  name    = "secure.${var.domain_name}"
  type    = "CNAME"
  ttl     = 300
  records = [module.verified_access.endpoint_domain]
}