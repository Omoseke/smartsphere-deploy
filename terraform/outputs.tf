# Terraform Outputs

# VPC Outputs
output "vpc_id" {
  description = "The ID of the VPC"
  value       = module.vpc.vpc_id
}

output "vpc_cidr_block" {
  description = "The CIDR block of the VPC"
  value       = module.vpc.vpc_cidr_block
}

output "private_subnets" {
  description = "List of IDs of private subnets"
  value       = module.vpc.private_subnets
}

output "public_subnets" {
  description = "List of IDs of public subnets"
  value       = module.vpc.public_subnets
}

output "database_subnets" {
  description = "List of IDs of database subnets"
  value       = module.vpc.database_subnets
}

# ALB Outputs
output "alb_id" {
  description = "The ID of the ALB"
  value       = aws_lb.main.id
}

output "alb_dns_name" {
  description = "The DNS name of the ALB"
  value       = aws_lb.main.dns_name
}

output "alb_zone_id" {
  description = "The canonical hosted zone ID of the ALB"
  value       = aws_lb.main.zone_id
}

# ECR Outputs
output "ecr_repository_url" {
  description = "The URL of the ECR repository"
  value       = aws_ecr_repository.main.repository_url
}

# ECS Outputs
output "ecs_cluster_id" {
  description = "The ID of the ECS cluster"
  value       = aws_ecs_cluster.main.id
}

output "ecs_service_name" {
  description = "The name of the ECS service"
  value       = aws_ecs_service.app.name
}

# Database Outputs
output "db_instance_address" {
  description = "The address of the RDS instance"
  value       = aws_db_instance.postgres.address
}

output "db_instance_id" {
  description = "The RDS instance ID"
  value       = aws_db_instance.postgres.id
}

output "db_instance_endpoint" {
  description = "The connection endpoint of the RDS instance"
  value       = aws_db_instance.postgres.endpoint
}

# CloudFront Outputs
output "cloudfront_distribution_id" {
  description = "The ID of the CloudFront distribution"
  value       = aws_cloudfront_distribution.frontend.id
}

output "cloudfront_domain_name" {
  description = "The domain name of the CloudFront distribution"
  value       = aws_cloudfront_distribution.frontend.domain_name
}

# S3 Bucket Outputs
output "frontend_bucket_name" {
  description = "The name of the S3 bucket for frontend assets"
  value       = aws_s3_bucket.frontend.bucket
}

output "app_data_bucket_name" {
  description = "The name of the S3 bucket for application data"
  value       = aws_s3_bucket.app_data.bucket
}

# Route53 Outputs
output "domain_name" {
  description = "The domain name for the application"
  value       = local.domain_name
}

# Security Outputs
output "kms_key_id" {
  description = "The ID of the KMS key"
  value       = aws_kms_key.app.id
}

output "kms_key_arn" {
  description = "The ARN of the KMS key"
  value       = aws_kms_key.app.arn
}

# CloudWatch Outputs
output "cloudwatch_dashboard_name" {
  description = "The name of the CloudWatch dashboard"
  value       = aws_cloudwatch_dashboard.main.dashboard_name
}

output "sns_topic_arn" {
  description = "The ARN of the SNS topic for alerts"
  value       = aws_sns_topic.alerts.arn
}