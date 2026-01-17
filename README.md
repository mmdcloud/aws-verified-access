# AWS Verified Access with IAM Identity Center

[![Terraform](https://img.shields.io/badge/Terraform-1.5+-623CE4?logo=terraform)](https://www.terraform.io/)
[![AWS](https://img.shields.io/badge/AWS-Verified_Access-FF9900?logo=amazon-aws)](https://aws.amazon.com/verified-access/)
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Maintained](https://img.shields.io/badge/Maintained-Yes-green.svg)](https://github.com/yourusername/aws-verified-access)

> **Secure, Zero Trust Network Access (ZTNA) solution using AWS Verified Access, IAM Identity Center, and Application Load Balancer with automatic SSL/TLS certificate management.**

## 📋 Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Features](#features)
- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Configuration](#configuration)
- [Deployment](#deployment)
- [Security](#security)
- [Monitoring](#monitoring)
- [Troubleshooting](#troubleshooting)
- [Cost Estimation](#cost-estimation)
- [Contributing](#contributing)
- [License](#license)

## 🎯 Overview

This Terraform configuration deploys a production-ready AWS Verified Access solution that provides secure, clientless access to internal applications without requiring a VPN. Users authenticate via AWS IAM Identity Center (SSO) and access is granted based on Cedar policy language rules.

### What is AWS Verified Access?

AWS Verified Access enables secure access to corporate applications without a traditional VPN by:
- Validating each request against identity and device context
- Providing fine-grained, application-level access controls
- Offering clientless access through standard web browsers
- Integrating with AWS IAM Identity Center for centralized identity management

## 🏗️ Architecture

```
┌─────────────────┐
│   End Users     │
│  (Browsers)     │
└────────┬────────┘
         │ HTTPS
         │
┌────────▼────────────────────────────────────────────┐
│  AWS Verified Access Endpoint                      │
│  • Domain: secure.yourdomain.com                   │
│  • SSL/TLS Certificate (ACM)                       │
│  • IAM Identity Center Integration                 │
└────────┬───────────────────────────────────────────┘
         │
         │ Policy Evaluation
         │ (Cedar Language)
         │
┌────────▼───────────────────────────────────────────┐
│  Application Load Balancer (Internal)              │
│  • Access Logs Enabled                             │
│  • Health Checks                                   │
└────────┬───────────────────────────────────────────┘
         │
         │
┌────────▼───────────────────────────────────────────┐
│  Auto Scaling Group (Private Subnets)              │
│  • Min: 3 instances                                │
│  • Max: 50 instances                               │
│  • Health Check Type: ELB                          │
└────────────────────────────────────────────────────┘
```

### Network Architecture

```
VPC (10.0.0.0/16)
│
├── Public Subnets (3 AZs)
│   ├── NAT Gateways
│   ├── Internet Gateway
│   └── Load Balancer Endpoints
│
└── Private Subnets (3 AZs)
    └── EC2 Auto Scaling Group
```

## ✨ Features

### Security
- ✅ **Zero Trust Network Access (ZTNA)** - No VPN required
- ✅ **IAM Identity Center Integration** - Centralized SSO authentication
- ✅ **Fine-grained Access Policies** - Cedar policy language
- ✅ **Email Domain Verification** - Restrict access by email domain
- ✅ **SSL/TLS Encryption** - Automated certificate management via ACM
- ✅ **Security Groups** - Network-level access controls
- ✅ **Private Subnets** - Application instances isolated from internet

### High Availability
- ✅ **Multi-AZ Deployment** - 3 Availability Zones
- ✅ **Auto Scaling** - Automatic capacity adjustment (3-50 instances)
- ✅ **Health Checks** - ELB health monitoring
- ✅ **NAT Gateway per AZ** - High availability for outbound traffic

### Monitoring & Compliance
- ✅ **ALB Access Logs** - Stored in S3 with versioning
- ✅ **DNS Management** - Route53 with automated validation
- ✅ **Infrastructure as Code** - Fully automated with Terraform

## 📦 Prerequisites

### Required Tools
- [Terraform](https://www.terraform.io/downloads.html) >= 1.5.0
- [AWS CLI](https://aws.amazon.com/cli/) >= 2.x
- [Git](https://git-scm.com/)
- Valid AWS Account with appropriate permissions

### AWS Services Configuration

#### 1. IAM Identity Center Setup
```bash
# Enable IAM Identity Center in your AWS Organization
aws sso-admin list-instances

# Note down the Instance ARN and Identity Store ID
```

#### 2. Route53 Hosted Zone
You must have a registered domain with a Route53 hosted zone:
```bash
aws route53 list-hosted-zones --query "HostedZones[?Name=='yourdomain.com.']"
```

#### 3. Required AWS Permissions
Your Terraform execution role needs:
- `AWSVerifiedAccessFullAccess`
- `IAMIdentityCenterFullAccess`
- `AmazonVPCFullAccess`
- `ElasticLoadBalancingFullAccess`
- `AmazonEC2FullAccess`
- `AWSCertificateManagerFullAccess`
- `AmazonRoute53FullAccess`
- `AmazonS3FullAccess`

## 🚀 Quick Start

### 1. Clone the Repository
```bash
git clone https://github.com/yourusername/aws-verified-access.git
cd aws-verified-access
```

### 2. Configure Variables
Create a `terraform.tfvars` file:
```hcl
# terraform.tfvars
region          = "us-east-1"
domain_name     = "example.com"  # Your registered domain
instance_name   = "production-verified-access"

azs = [
  "us-east-1a",
  "us-east-1b",
  "us-east-1c"
]

public_subnets = [
  "10.0.1.0/24",
  "10.0.2.0/24",
  "10.0.3.0/24"
]

private_subnets = [
  "10.0.101.0/24",
  "10.0.102.0/24",
  "10.0.103.0/24"
]
```

### 3. Initialize Terraform
```bash
terraform init
```

### 4. Review Plan
```bash
terraform plan -out=tfplan
```

### 5. Deploy Infrastructure
```bash
terraform apply tfplan
```

**⏱️ Deployment Time**: Approximately 15-20 minutes

### 6. Configure IAM Identity Center Users

After deployment, configure users in IAM Identity Center:

```bash
# Option 1: AWS Console
# Navigate to IAM Identity Center > Users > Add user

# Option 2: Terraform (uncomment in main.tf)
# See the commented section for aws_identitystore_user
```

## ⚙️ Configuration

### variables.tf
```hcl
variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "domain_name" {
  description = "Domain name for the verified access endpoint"
  type        = string
}

variable "instance_name" {
  description = "Name for the Verified Access instance"
  type        = string
  default     = "verified-access-instance"
}

variable "azs" {
  description = "Availability zones"
  type        = list(string)
}

variable "public_subnets" {
  description = "Public subnet CIDR blocks"
  type        = list(string)
}

variable "private_subnets" {
  description = "Private subnet CIDR blocks"
  type        = list(string)
}
```

### Access Policy Customization

The Cedar policy in `aws_verifiedaccess_group` controls access:

```hcl
policy_document = <<-EOT
  permit(principal, action, resource)
  when {
    context.trustprovider.user.email.verified == true &&
    context.trustprovider.user.email.address like "*@${var.domain_name}"
  };
EOT
```

**Policy Examples**:

#### Restrict by Email Domain and Group
```cedar
permit(principal, action, resource)
when {
  context.trustprovider.user.email.verified == true &&
  context.trustprovider.user.email.address like "*@example.com" &&
  context.trustprovider.user.groups has "Developers"
};
```

#### Allow Specific Users Only
```cedar
permit(principal, action, resource)
when {
  context.trustprovider.user.email.address in [
    "admin@example.com",
    "developer@example.com"
  ]
};
```

#### Time-based Access
```cedar
permit(principal, action, resource)
when {
  context.trustprovider.user.email.verified == true &&
  context.time.hour >= 9 &&
  context.time.hour <= 17
};
```

## 📊 Outputs

After successful deployment:

```bash
terraform output
```

```hcl
Outputs:

verified_access_endpoint_url = "https://secure.example.com"
verified_access_endpoint_domain = "xxxxxxxxxxxx.edge.verified-access.aws.dev"
load_balancer_dns = "lb-xxxxxxxxxxxx.us-east-1.elb.amazonaws.com"
vpc_id = "vpc-xxxxxxxxxxxxx"
auto_scaling_group_name = "asg"
```

## 🔒 Security

### Security Best Practices Implemented

1. **Network Isolation**
   - Application instances in private subnets
   - Internal-only load balancer
   - Security groups with least-privilege access

2. **Encryption**
   - TLS 1.2+ for all connections
   - AWS Certificate Manager for SSL/TLS
   - S3 versioning enabled for logs

3. **Access Control**
   - IAM Identity Center authentication
   - Cedar policy-based authorization
   - Email verification required

4. **Monitoring**
   - ALB access logs to S3
   - CloudWatch integration (via AWS Console)
   - DNS query logging available

### Security Group Rules

#### Load Balancer Security Group
```hcl
Ingress:
  - Port 80 (HTTP) from 0.0.0.0/0
  - Port 443 (HTTPS) from 0.0.0.0/0

Egress:
  - All traffic allowed
```

#### Auto Scaling Group Security Group
```hcl
Ingress:
  - Port 80 (HTTP) from Load Balancer Security Group only

Egress:
  - All traffic allowed
```

### Secrets Management

**Important**: This configuration uses a hardcoded key name. For production:

```hcl
# Store SSH key name in AWS Systems Manager Parameter Store
data "aws_ssm_parameter" "ssh_key" {
  name = "/production/ssh/key-name"
}

# Reference in launch template
key_name = data.aws_ssm_parameter.ssh_key.value
```

## 📈 Monitoring

### CloudWatch Metrics

Key metrics to monitor:

1. **Verified Access**
   - AuthenticationAttempts
   - AuthenticationSuccesses
   - AuthenticationFailures
   - ConnectionAttempts

2. **Application Load Balancer**
   - TargetResponseTime
   - HealthyHostCount
   - UnHealthyHostCount
   - RequestCount
   - HTTPCode_Target_4XX_Count
   - HTTPCode_Target_5XX_Count

3. **Auto Scaling Group**
   - GroupDesiredCapacity
   - GroupInServiceInstances
   - GroupMinSize
   - GroupMaxSize

### CloudWatch Alarms (Recommended)

```hcl
resource "aws_cloudwatch_metric_alarm" "target_unhealthy" {
  alarm_name          = "alb-unhealthy-targets"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "UnHealthyHostCount"
  namespace           = "AWS/ApplicationELB"
  period              = "60"
  statistic           = "Average"
  threshold           = "0"
  alarm_description   = "Alert when unhealthy targets detected"
  alarm_actions       = [aws_sns_topic.alerts.arn]
}
```

### Access Logs

ALB access logs are stored in S3:
```
s3://lb-logs-{random-id}/AWSLogs/{account-id}/elasticloadbalancing/{region}/
```

**Log Analysis with Athena**:
```sql
CREATE EXTERNAL TABLE alb_logs (
  type string,
  time string,
  elb string,
  client_ip string,
  target string,
  request_processing_time double,
  target_processing_time double,
  response_processing_time double,
  elb_status_code string,
  target_status_code string,
  received_bytes bigint,
  sent_bytes bigint,
  request_verb string,
  request_url string,
  request_proto string,
  user_agent string,
  ssl_cipher string,
  ssl_protocol string
)
ROW FORMAT SERDE 'org.apache.hadoop.hive.serde2.RegexSerDe'
WITH SERDEPROPERTIES (
  'serialization.format' = '1',
  'input.regex' = '([^ ]*) ([^ ]*) ([^ ]*) ([^ ]*):([0-9]*) ([^ ]*)[:-]([0-9]*) ([-.0-9]*) ([-.0-9]*) ([-.0-9]*) (|[-0-9]*) (-|[-0-9]*) ([-0-9]*) ([-0-9]*) \"([^ ]*) ([^ ]*) (- |[^ ]*)\" \"([^\"]*)\" ([A-Z0-9-]+) ([A-Za-z0-9.-]*)'
)
LOCATION 's3://lb-logs-{random-id}/AWSLogs/{account-id}/elasticloadbalancing/{region}/';
```

## 🐛 Troubleshooting

### Common Issues

#### 1. Certificate Validation Stuck
**Problem**: ACM certificate validation doesn't complete
```bash
# Check DNS records
aws route53 list-resource-record-sets --hosted-zone-id ZXXXXXXXXXXXXX

# Verify CNAME records exist for certificate validation
```

**Solution**: Ensure Route53 is authoritative for your domain

#### 2. Cannot Access Application
**Problem**: `403 Forbidden` or `Unable to connect`

**Checklist**:
- [ ] Is user created in IAM Identity Center?
- [ ] Is user's email verified?
- [ ] Does user's email match the domain in the policy?
- [ ] Is the certificate validated?
- [ ] Are DNS records propagated?

```bash
# Check DNS propagation
dig secure.example.com

# Verify endpoint status
aws ec2 describe-verified-access-endpoints \
  --verified-access-endpoint-ids vae-xxxxxxxxxxxxx
```

#### 3. Auto Scaling Group Not Healthy
**Problem**: Instances fail health checks

```bash
# Check instance health
aws autoscaling describe-auto-scaling-groups \
  --auto-scaling-group-names asg \
  --query 'AutoScalingGroups[0].Instances[*].[InstanceId,HealthStatus,LifecycleState]'

# Check ALB target health
aws elbv2 describe-target-health \
  --target-group-arn arn:aws:elasticloadbalancing:...
```

**Common Causes**:
- Application not listening on port 80
- Security group blocking traffic
- Health check path returns non-200 status

#### 4. Internal Load Balancer Issue
**Problem**: Load balancer is internal but needs to be accessible

**Current Configuration**: Load balancer is set to `internal = true`

**If you need external access**: Change to `internal = false` in main.tf:
```hcl
module "lb" {
  # ...
  internal = false  # Change from true
  # ...
}
```

### Debug Mode

Enable detailed Terraform logging:
```bash
export TF_LOG=DEBUG
export TF_LOG_PATH=./terraform-debug.log
terraform apply
```

## 💰 Cost Estimation

### Monthly Cost Breakdown (us-east-1)

| Service | Configuration | Estimated Cost |
|---------|--------------|----------------|
| **Verified Access** | 1 endpoint | $36.00 |
| **EC2 Instances** | 3x t2.micro (on-demand) | $10.51 |
| **Application Load Balancer** | 1 ALB + LCU | $22.50 |
| **NAT Gateway** | 3 NAT Gateways | $97.92 |
| **Route53** | 1 hosted zone + queries | $0.50 |
| **S3** | 100GB logs/month | $2.30 |
| **Data Transfer** | 100GB outbound | $9.00 |
| **ACM Certificate** | 1 certificate | $0.00 |
| **Total** | | **~$178.73/month** |

**Cost Optimization Tips**:
1. Use `single_nat_gateway = true` to reduce NAT costs to ~$32.64/month
2. Enable S3 lifecycle policies to archive old logs
3. Use Reserved Instances for predictable EC2 workloads
4. Right-size EC2 instances based on actual usage

### Pay-as-you-go Pricing
```bash
# Estimate with AWS Pricing Calculator
https://calculator.aws/
```

## 📚 Additional Resources

### Documentation
- [AWS Verified Access Documentation](https://docs.aws.amazon.com/verified-access/)
- [IAM Identity Center Guide](https://docs.aws.amazon.com/singlesignon/)
- [Cedar Policy Language](https://docs.cedarpolicy.com/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)

### Tutorials
- [Getting Started with Verified Access](https://aws.amazon.com/verified-access/getting-started/)
- [Zero Trust Architecture on AWS](https://aws.amazon.com/architecture/security-identity-compliance/)

### Support
- 🐛 [Report Issues](https://github.com/yourusername/aws-verified-access/issues)
- 💬 [Discussions](https://github.com/yourusername/aws-verified-access/discussions)
- 📧 Email: support@yourcompany.com

## 🧹 Cleanup

To destroy all resources:

```bash
# Review what will be destroyed
terraform plan -destroy

# Destroy infrastructure
terraform destroy
```

**⚠️ Warning**: This will permanently delete all resources including:
- VPC and all networking components
- EC2 instances and Auto Scaling Groups
- Load Balancers
- Verified Access configuration
- S3 buckets (if `force_destroy = true`)

**Data Retention**: S3 access logs will be deleted if `force_destroy = true`. Set to `false` to preserve logs.

## 🤝 Contributing

Contributions are welcome! Please follow these steps:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Development Guidelines
- Follow Terraform best practices
- Add tests for new features
- Update documentation
- Ensure all security checks pass

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- AWS Verified Access Team
- Terraform AWS Provider Maintainers
- Open Source Community

## 📞 Contact

**Project Maintainer**: Your Name
- GitHub: [@yourusername](https://github.com/yourusername)
- LinkedIn: [Your Profile](https://linkedin.com/in/yourprofile)
- Email: your.email@example.com

---

**⭐ If you find this project helpful, please give it a star!**

**Last Updated**: January 2026
