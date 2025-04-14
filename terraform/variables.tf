# Input variables for the SmartSphere infrastructure

variable "project" {
  description = "Project name"
  type        = string
  default     = "smartsphere"
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
  
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "The environment must be one of: dev, staging, prod."
  }
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "List of availability zones to use"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b", "us-east-1c"]
}

variable "public_subnets" {
  description = "List of public subnet CIDR blocks"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
}

variable "private_subnets" {
  description = "List of private subnet CIDR blocks"
  type        = list(string)
  default     = ["10.0.11.0/24", "10.0.12.0/24", "10.0.13.0/24"]
}

variable "database_subnets" {
  description = "List of database subnet CIDR blocks"
  type        = list(string)
  default     = ["10.0.21.0/24", "10.0.22.0/24", "10.0.23.0/24"]
}

variable "container_port" {
  description = "Port exposed by the container"
  type        = number
  default     = 80
}

variable "container_cpu" {
  description = "CPU units for the container"
  type        = number
  default     = 256  # 0.25 vCPU
}

variable "container_memory" {
  description = "Memory for the container in MiB"
  type        = number
  default     = 512  # 0.5 GB
}

variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.small"
}

variable "db_allocated_storage" {
  description = "Allocated storage for the RDS instance in GB"
  type        = number
  default     = 20
}

variable "db_name" {
  description = "Name of the database"
  type        = string
  default     = "smartsphere"
}

variable "db_username" {
  description = "Username for the database"
  type        = string
  default     = "smartsphere_app"
  sensitive   = true
}

variable "db_password" {
  description = "Password for the database"
  type        = string
  sensitive   = true
}

variable "domain_name" {
  description = "Domain name for the application"
  type        = string
  default     = "smartsphere.example.com"
}

variable "route53_zone_id" {
  description = "Route 53 hosted zone ID"
  type        = string
}

variable "certificate_arn" {
  description = "ARN of the SSL certificate"
  type        = string
}

variable "desired_capacity" {
  description = "Desired number of container instances"
  type        = number
  default     = 2
}

variable "min_capacity" {
  description = "Minimum number of container instances"
  type        = number
  default     = 2
}

variable "max_capacity" {
  description = "Maximum number of container instances"
  type        = number
  default     = 10
}

variable "health_check_path" {
  description = "Path for health checks"
  type        = string
  default     = "/health"
}

variable "enable_deletion_protection" {
  description = "Enable deletion protection for production resources"
  type        = bool
  default     = false
}

variable "allowed_cidr_blocks" {
  description = "CIDR blocks allowed to access the resources"
  type        = list(string)
  default     = ["0.0.0.0/0"]  # Should be restricted in production
}

variable "enable_blue_green_deployment" {
  description = "Whether to enable blue-green deployment strategy"
  type        = bool
  default     = false
}

variable "force_deployment_color" {
  description = "Force deployment to a specific color (blue or green), leave empty for automatic selection"
  type        = string
  default     = ""
}

# Multi-region variables
variable "enable_multi_region" {
  description = "Whether to enable multi-region deployment"
  type        = bool
  default     = false
}

variable "primary_region" {
  description = "Primary AWS region for deployment"
  type        = string
  default     = "us-east-1"
}

variable "secondary_region" {
  description = "Secondary AWS region for disaster recovery and high availability"
  type        = string
  default     = "us-west-2"
}

variable "secondary_alb_dns_name" {
  description = "DNS name of the ALB in the secondary region"
  type        = string
  default     = ""
}

variable "secondary_alb_arn_suffix" {
  description = "ARN suffix of the ALB in the secondary region"
  type        = string
  default     = ""
}

# Note: These variables are already defined above
# variable "route53_zone_id" - already defined
# variable "domain_name" - already defined 
# variable "health_check_path" - already defined
# variable "certificate_arn" - already defined

# AWS Amplify variables
variable "github_repository" {
  description = "GitHub repository URL for the SmartSphere frontend"
  type        = string
  default     = "https://github.com/smartsphere/frontend"
}

variable "github_access_token" {
  description = "GitHub personal access token for Amplify to access the repository"
  type        = string
  sensitive   = true
  default     = ""
}

variable "api_endpoint_url" {
  description = "API endpoint URL for the production environment"
  type        = string
  default     = "https://api.smartsphere.example.com"
}

variable "api_endpoint_url_dev" {
  description = "API endpoint URL for the development environment"
  type        = string
  default     = "https://api-dev.smartsphere.example.com"
}

variable "api_endpoint_url_staging" {
  description = "API endpoint URL for the staging environment"
  type        = string
  default     = "https://api-staging.smartsphere.example.com"
}

variable "app_version" {
  description = "Application version"
  type        = string
  default     = "1.0.0"
}

variable "enable_custom_domain" {
  description = "Whether to enable custom domain for Amplify"
  type        = bool
  default     = false
}

variable "custom_domain" {
  description = "Custom domain for Amplify"
  type        = string
  default     = "app.smartsphere.example.com"
}

variable "create_staging_branch" {
  description = "Whether to create a staging branch"
  type        = bool
  default     = true
}

variable "enable_performance_mode" {
  description = "Whether to enable performance mode for Amplify builds"
  type        = bool
  default     = false
}

variable "basic_auth_username" {
  description = "Username for basic auth (non-production environments)"
  type        = string
  default     = "smartsphere"
}

variable "basic_auth_password" {
  description = "Password for basic auth (non-production environments)"
  type        = string
  sensitive   = true
  default     = ""
}

variable "enable_amplify_backend" {
  description = "Whether to enable Amplify backend environment"
  type        = bool
  default     = false
}

variable "amplify_backend_deployment_artifacts" {
  description = "S3 bucket path for Amplify backend deployment artifacts"
  type        = string
  default     = ""
}

# Advanced monitoring variables
variable "alert_email_addresses" {
  description = "List of email addresses to send monitoring alerts to"
  type        = list(string)
  default     = []
}

variable "slack_webhook_url" {
  description = "Slack webhook URL for monitoring notifications"
  type        = string
  default     = ""
}

variable "pagerduty_integration_key" {
  description = "PagerDuty integration key for monitoring notifications"
  type        = string
  default     = ""
}