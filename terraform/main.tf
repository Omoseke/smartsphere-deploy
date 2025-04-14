# Enterprise SmartSphere Terraform Configuration
# Main configuration file

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.4"
    }
  }
  required_version = ">= 1.0.0"
}

provider "aws" {
  region = var.aws_region
  default_tags {
    tags = local.common_tags
  }
}

# Data source to get the current AWS account ID
data "aws_caller_identity" "current" {}

# Data source to get the available AWS availability zones
data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  project     = var.project
  environment = var.environment
  
  # Common tags to be assigned to all resources
  common_tags = {
    Project     = local.project
    Environment = local.environment
    ManagedBy   = "Terraform"
    Owner       = "DevOps"
  }
  
  # Domain name configuration
  domain_name = var.domain_name
  
  # Production flag
  is_production = local.environment == "prod"
}