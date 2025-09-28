# -----------------------------------------------------------------------------------------
# VPC Configuration
# -----------------------------------------------------------------------------------------

module "vpc" {
  source                = "./modules/vpc/vpc"
  vpc_name              = "vpc"
  vpc_cidr_block        = "10.0.0.0/16"
  enable_dns_hostnames  = true
  enable_dns_support    = true
  internet_gateway_name = "vpc-igw"
}

module "lb_sg" {
  source = "./modules/vpc/security_groups"
  vpc_id = module.vpc.vpc_id
  name   = "lb-sg"
  ingress = [
    {
      from_port       = 80
      to_port         = 80
      protocol        = "tcp"
      self            = "false"
      cidr_blocks     = ["0.0.0.0/0"]
      security_groups = []
      description     = "HTTP traffic"
    },
    {
      from_port       = 443
      to_port         = 443
      protocol        = "tcp"
      self            = "false"
      cidr_blocks     = ["0.0.0.0/0"]
      security_groups = []
      description     = "HTTPS traffic"
    }
  ]
  egress = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }
  ]
}

module "asg_sg" {
  source = "./modules/vpc/security_groups"
  vpc_id = module.vpc.vpc_id
  name   = "asg-sg"
  ingress = [
    {
      from_port       = 80
      to_port         = 80
      protocol        = "tcp"
      self            = "false"
      cidr_blocks     = []
      security_groups = [module.lb_sg.id]
      description     = "any"
    }
  ]
  egress = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }
  ]
}

module "public_subnets" {
  source = "./modules/vpc/subnets"
  name   = "public-subnet"
  subnets = [
    {
      subnet = "10.0.1.0/24"
      az     = "${var.region}a"
    },
    {
      subnet = "10.0.2.0/24"
      az     = "${var.region}b"
    },
    {
      subnet = "10.0.3.0/24"
      az     = "${var.region}c"
    }
  ]
  vpc_id                  = module.vpc.vpc_id
  map_public_ip_on_launch = true
}

module "private_subnets" {
  source = "./modules/vpc/subnets"
  name   = "private-subnet"
  subnets = [
    {
      subnet = "10.0.4.0/24"
      az     = "${var.region}a"
    },
    {
      subnet = "10.0.5.0/24"
      az     = "${var.region}b"
    },
    {
      subnet = "10.0.6.0/24"
      az     = "${var.region}c"
    }
  ]
  vpc_id                  = module.vpc.vpc_id
  map_public_ip_on_launch = false
}

module "public_rt" {
  source  = "./modules/vpc/route_tables"
  name    = "public-route-table"
  subnets = module.public_subnets.subnets[*]
  routes = [
    {
      cidr_block     = "0.0.0.0/0"
      gateway_id     = module.vpc.igw_id
      nat_gateway_id = ""
    }
  ]
  vpc_id = module.vpc.vpc_id
}

# -------------------------------------------------------------------------------
# Auto Scaling Group
# -------------------------------------------------------------------------------

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
      associate_public_ip_address = true
      security_groups             = [module.asg_sg.id]
    }
  ]
  user_data = base64encode(templatefile("${path.module}/../../scripts/user_data_frontend.sh"))
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
  target_group_arns         = [module.carshub_frontend_lb.target_groups[0].arn]
  vpc_zone_identifier       = module.carshub_private_subnets.subnets[*].id
  launch_template_id        = module.carshub_frontend_launch_template.id
  launch_template_version   = "$Latest"
}

# -------------------------------------------------------------------------------
# Load Balancer
# -------------------------------------------------------------------------------

# Load Balancer
module "lb" {
  source                     = "./modules/load-balancer"
  lb_name                    = "lb"
  lb_is_internal             = false
  lb_ip_address_type         = "ipv4"
  load_balancer_type         = "application"
  enable_deletion_protection = true
  security_groups            = [module.lb_sg.id]
  subnets                    = module.public_subnets.subnets[*].id
  target_groups = [
    {
      target_group_name      = "tg"
      target_port            = 80
      target_ip_address_type = "ipv4"
      target_protocol        = "HTTP"
      target_type            = "instance"
      target_vpc_id          = module.vpc.vpc_id
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
# AWS Verified Access Group
# -------------------------------------------------------------------------------

resource "aws_verifiedaccess_group" "group" {
  description            = "verified-access-group"
  verifiedaccess_instance_id = aws_verifiedaccess_instance.instance.id
}

# -------------------------------------------------------------------------------
# AWS Verified Access Endpoint
# -------------------------------------------------------------------------------

resource "aws_verifiedaccess_endpoint" "endpoint" {
  application_domain     = "mohitcloud.xyz"
  attachment_type        = "vpc"
  description            = "Verified Access Endpoint"
  domain_certificate_arn = aws_acm_certificate.example.arn
  endpoint_domain_prefix = "secure"
  endpoint_type          = "load-balancer"

  load_balancer_options {
    load_balancer_arn = module.lb.lb_arn
    port              = 80
    protocol          = "http"
    subnet_ids        = [for subnet in aws_subnet.public : subnet.id]
  }

  security_group_ids       = [module.lb_sg.id]
  verified_access_group_id = aws_verifiedaccess_group.group.id
}