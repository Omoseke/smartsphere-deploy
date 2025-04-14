# Multi-Region Configuration for SmartSphere
# Implements disaster recovery and global availability

locals {
  # Secondary region configuration
  secondary_region = var.enable_multi_region ? var.secondary_region : ""
  
  # Determine if this is the primary region deployment
  is_primary_region = true  # Since we're always deploying from the primary region
  
  # Only create resources in the secondary region if multi-region is enabled
  create_secondary_resources = var.enable_multi_region && local.is_primary_region
}

# Provider for the secondary region
provider "aws" {
  alias  = "secondary"
  region = var.enable_multi_region ? var.secondary_region : var.primary_region
  
  default_tags {
    tags = {
      Project     = local.project
      Environment = local.environment
      Terraform   = "true"
      Region      = var.enable_multi_region ? var.secondary_region : var.primary_region
    }
  }
}

# S3 Bucket for cross-region replication of application data
resource "aws_s3_bucket" "app_data_replica" {
  count = var.enable_multi_region ? 1 : 0
  
  provider = aws.secondary
  bucket   = "${local.project}-${local.environment}-app-data-replica"
  
  tags = {
    Name = "${local.project}-${local.environment}-app-data-replica"
  }
}

# Block public access for the replica bucket
resource "aws_s3_bucket_public_access_block" "app_data_replica" {
  count = var.enable_multi_region ? 1 : 0
  
  provider                = aws.secondary
  bucket                  = aws_s3_bucket.app_data_replica[0].id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Enable versioning for the replica bucket
resource "aws_s3_bucket_versioning" "app_data_replica" {
  count = var.enable_multi_region ? 1 : 0
  
  provider = aws.secondary
  bucket   = aws_s3_bucket.app_data_replica[0].id
  
  versioning_configuration {
    status = "Enabled"
  }
}

# Enable server-side encryption for the replica bucket
resource "aws_s3_bucket_server_side_encryption_configuration" "app_data_replica" {
  count = var.enable_multi_region ? 1 : 0
  
  provider = aws.secondary
  bucket   = aws_s3_bucket.app_data_replica[0].id
  
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# IAM Role for S3 replication
resource "aws_iam_role" "replication" {
  count = var.enable_multi_region ? 1 : 0
  
  name = "${local.project}-${local.environment}-replication-role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "s3.amazonaws.com"
        }
      }
    ]
  })
}

# IAM Policy for S3 replication
resource "aws_iam_policy" "replication" {
  count = var.enable_multi_region ? 1 : 0
  
  name        = "${local.project}-${local.environment}-replication-policy"
  description = "Policy for S3 bucket replication"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:GetReplicationConfiguration",
          "s3:ListBucket"
        ]
        Effect   = "Allow"
        Resource = [aws_s3_bucket.app_data.arn]
      },
      {
        Action = [
          "s3:GetObjectVersionForReplication",
          "s3:GetObjectVersionAcl",
          "s3:GetObjectVersionTagging"
        ]
        Effect   = "Allow"
        Resource = ["${aws_s3_bucket.app_data.arn}/*"]
      },
      {
        Action = [
          "s3:ReplicateObject",
          "s3:ReplicateDelete",
          "s3:ReplicateTags"
        ]
        Effect   = "Allow"
        Resource = ["${aws_s3_bucket.app_data_replica[0].arn}/*"]
      }
    ]
  })
}

# Attach the replication policy to the role
resource "aws_iam_role_policy_attachment" "replication" {
  count = var.enable_multi_region ? 1 : 0
  
  role       = aws_iam_role.replication[0].name
  policy_arn = aws_iam_policy.replication[0].arn
}

# Configure replication on the source bucket
resource "aws_s3_bucket_replication_configuration" "app_data" {
  count = var.enable_multi_region ? 1 : 0
  
  role   = aws_iam_role.replication[0].arn
  bucket = aws_s3_bucket.app_data.id
  
  rule {
    id     = "app-data-replication"
    status = "Enabled"
    
    destination {
      bucket        = aws_s3_bucket.app_data_replica[0].arn
      storage_class = "STANDARD"
    }
  }
  
  depends_on = [aws_s3_bucket_versioning.app_data]
}

# DynamoDB Global Table for state information
resource "aws_dynamodb_table" "global_state" {
  count = var.enable_multi_region ? 1 : 0
  
  name           = "${local.project}-${local.environment}-global-state"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "StateKey"
  stream_enabled = true
  stream_view_type = "NEW_AND_OLD_IMAGES"
  
  attribute {
    name = "StateKey"
    type = "S"
  }
  
  replica {
    region_name = local.secondary_region
  }
  
  tags = {
    Name = "${local.project}-${local.environment}-global-state"
  }
}

# RDS Read Replica in the secondary region
resource "aws_db_instance" "secondary" {
  count = var.enable_multi_region ? 1 : 0
  
  provider                = aws.secondary
  identifier              = "${local.project}-${local.environment}-db-replica"
  replicate_source_db     = aws_db_instance.postgres.identifier
  instance_class          = var.db_instance_class
  storage_encrypted       = true
  skip_final_snapshot     = true
  backup_retention_period = 7
  deletion_protection     = var.enable_deletion_protection
  
  tags = {
    Name = "${local.project}-${local.environment}-db-replica"
  }
}

# CloudFront Distribution with multiple origins
resource "aws_cloudfront_distribution" "multi_region" {
  count = var.enable_multi_region ? 1 : 0
  
  enabled             = true
  is_ipv6_enabled     = true
  comment             = "${local.project}-${local.environment}-multi-region"
  default_root_object = "index.html"
  price_class         = "PriceClass_All" # Global distribution
  
  # Primary region origin
  origin {
    domain_name = aws_lb.main.dns_name
    origin_id   = "primary"
    
    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "https-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }
  
  # Secondary region origin (failover)
  origin {
    domain_name = var.secondary_alb_dns_name
    origin_id   = "secondary"
    
    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "https-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }
  
  # Default behavior (primary region)
  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "primary"
    
    forwarded_values {
      query_string = true
      cookies {
        forward = "all"
      }
      headers = ["Host", "Origin", "Authorization"]
    }
    
    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }
  
  # Origin failover configuration
  origin_group {
    origin_id = "failover_group"
    
    failover_criteria {
      status_codes = [500, 502, 503, 504]
    }
    
    member {
      origin_id = "primary"
    }
    
    member {
      origin_id = "secondary"
    }
  }
  
  # Custom failover behavior
  ordered_cache_behavior {
    path_pattern     = "/api/*"
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "failover_group"
    
    forwarded_values {
      query_string = true
      cookies {
        forward = "all"
      }
      headers = ["Host", "Origin", "Authorization"]
    }
    
    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 0
    max_ttl                = 0
  }
  
  # SSL certificate
  viewer_certificate {
    acm_certificate_arn      = var.certificate_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }
  
  # Restrictions
  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }
  
  # Custom error responses
  custom_error_response {
    error_code            = 500
    error_caching_min_ttl = 10
    response_code         = 500
    response_page_path    = "/500.html"
  }
  
  tags = {
    Name = "${local.project}-${local.environment}-multi-region"
  }
}

# Route 53 Health Check for the primary region
resource "aws_route53_health_check" "primary" {
  count = var.enable_multi_region ? 1 : 0
  
  fqdn              = aws_lb.main.dns_name
  port              = 443
  type              = "HTTPS"
  resource_path     = var.health_check_path
  failure_threshold = 3
  request_interval  = 30
  
  tags = {
    Name = "${local.project}-${local.environment}-primary-health-check"
  }
}

# Route 53 Health Check for the secondary region
resource "aws_route53_health_check" "secondary" {
  count = var.enable_multi_region ? 1 : 0
  
  fqdn              = var.secondary_alb_dns_name
  port              = 443
  type              = "HTTPS"
  resource_path     = var.health_check_path
  failure_threshold = 3
  request_interval  = 30
  
  tags = {
    Name = "${local.project}-${local.environment}-secondary-health-check"
  }
}

# Route 53 Failover record for the primary region
resource "aws_route53_record" "primary" {
  count = var.enable_multi_region ? 1 : 0
  
  zone_id = var.route53_zone_id
  name    = var.domain_name
  type    = "A"
  
  failover_routing_policy {
    type = "PRIMARY"
  }
  
  alias {
    name                   = aws_cloudfront_distribution.multi_region[0].domain_name
    zone_id                = aws_cloudfront_distribution.multi_region[0].hosted_zone_id
    evaluate_target_health = true
  }
  
  health_check_id = aws_route53_health_check.primary[0].id
  set_identifier  = "primary"
}

# Route 53 Failover record for the secondary region
resource "aws_route53_record" "secondary" {
  count = var.enable_multi_region ? 1 : 0
  
  zone_id = var.route53_zone_id
  name    = var.domain_name
  type    = "A"
  
  failover_routing_policy {
    type = "SECONDARY"
  }
  
  alias {
    name                   = aws_cloudfront_distribution.multi_region[0].domain_name
    zone_id                = aws_cloudfront_distribution.multi_region[0].hosted_zone_id
    evaluate_target_health = true
  }
  
  health_check_id = aws_route53_health_check.secondary[0].id
  set_identifier  = "secondary"
}

# CloudWatch dashboard for multi-region monitoring
resource "aws_cloudwatch_dashboard" "multi_region" {
  count = var.enable_multi_region ? 1 : 0
  
  dashboard_name = "${local.project}-${local.environment}-multi-region"
  
  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "text"
        x      = 0
        y      = 0
        width  = 24
        height = 1
        properties = {
          markdown = "# ${upper(local.project)} ${title(local.environment)} Multi-Region Dashboard"
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 1
        width  = 12
        height = 6
        properties = {
          view    = "timeSeries"
          stacked = false
          metrics = [
            ["AWS/ApplicationELB", "RequestCount", "LoadBalancer", aws_lb.main.arn_suffix, { "region" = var.primary_region, "label" = "Primary Region Requests" }],
            ["AWS/ApplicationELB", "RequestCount", "LoadBalancer", var.secondary_alb_arn_suffix, { "region" = var.secondary_region, "label" = "Secondary Region Requests" }]
          ]
          region  = var.primary_region
          title   = "Request Distribution"
          period  = 300
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 1
        width  = 12
        height = 6
        properties = {
          view    = "timeSeries"
          stacked = false
          metrics = [
            ["AWS/ApplicationELB", "TargetResponseTime", "LoadBalancer", aws_lb.main.arn_suffix, { "region" = var.primary_region, "label" = "Primary Region Response Time" }],
            ["AWS/ApplicationELB", "TargetResponseTime", "LoadBalancer", var.secondary_alb_arn_suffix, { "region" = var.secondary_region, "label" = "Secondary Region Response Time" }]
          ]
          region  = var.primary_region
          title   = "Response Times"
          period  = 300
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 7
        width  = 12
        height = 6
        properties = {
          view    = "timeSeries"
          stacked = false
          metrics = [
            ["AWS/S3", "ReplicationLatency", "BucketName", aws_s3_bucket.app_data.id, "RuleId", "app-data-replication", { "region" = var.primary_region }]
          ]
          region  = var.primary_region
          title   = "S3 Replication Latency"
          period  = 300
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 7
        width  = 12
        height = 6
        properties = {
          view    = "timeSeries"
          stacked = false
          metrics = [
            ["AWS/RDS", "ReplicaLag", "DBInstanceIdentifier", aws_db_instance.secondary[0].identifier, { "region" = var.secondary_region }]
          ]
          region  = var.secondary_region
          title   = "RDS Replica Lag"
          period  = 300
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 13
        width  = 24
        height = 6
        properties = {
          view    = "timeSeries"
          stacked = false
          metrics = [
            ["AWS/CloudFront", "Requests", "DistributionId", aws_cloudfront_distribution.multi_region[0].id, "Region", "Global"],
            ["AWS/CloudFront", "4xxErrorRate", "DistributionId", aws_cloudfront_distribution.multi_region[0].id, "Region", "Global"],
            ["AWS/CloudFront", "5xxErrorRate", "DistributionId", aws_cloudfront_distribution.multi_region[0].id, "Region", "Global"]
          ]
          region  = "us-east-1"
          title   = "CloudFront Global Metrics"
          period  = 300
        }
      }
    ]
  })
}