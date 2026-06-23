terraform {
  required_version = ">= 1.9.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
  # backend "s3" {
  #   bucket       = "verifiedaccesstfstate"
  #   key          = "terraform.tfstate"
  #   region       = "us-east-1"
  #   use_lockfile = true
  #   encrypt      = true
  # }
}

# Configure the AWS Provider
provider "aws" {
  region = "us-east-1"
}

provider "random" {}