# Route53 Configuration for SmartSphere

# Main DNS record for the application
resource "aws_route53_record" "main" {
  zone_id = var.route53_zone_id
  name    = local.domain_name
  type    = "A"
  
  alias {
    name                   = aws_cloudfront_distribution.frontend.domain_name
    zone_id                = aws_cloudfront_distribution.frontend.hosted_zone_id
    evaluate_target_health = false
  }
}

# DNS record for API subdomain
resource "aws_route53_record" "api" {
  zone_id = var.route53_zone_id
  name    = "api-${local.environment == "prod" ? "" : "${local.environment}."}smartsphere.example.com"
  type    = "A"
  
  alias {
    name                   = aws_lb.main.dns_name
    zone_id                = aws_lb.main.zone_id
    evaluate_target_health = true
  }
}

# Health Check for High Availability
resource "aws_route53_health_check" "main" {
  fqdn              = local.domain_name
  port              = 443
  type              = "HTTPS"
  resource_path     = "/health"
  failure_threshold = 3
  request_interval  = 30
  
  tags = {
    Name = "${local.project}-${local.environment}-health-check"
  }
}

# DNS failover configuration (primary)
resource "aws_route53_record" "primary_failover" {
  count = local.environment == "prod" ? 1 : 0
  
  zone_id = var.route53_zone_id
  name    = "failover.${var.domain_name}"
  type    = "A"
  
  failover_routing_policy {
    type = "PRIMARY"
  }
  
  set_identifier = "primary"
  health_check_id = aws_route53_health_check.main.id
  
  alias {
    name                   = aws_cloudfront_distribution.frontend.domain_name
    zone_id                = aws_cloudfront_distribution.frontend.hosted_zone_id
    evaluate_target_health = true
  }
}

# DNS failover configuration (secondary) - static backup site
resource "aws_route53_record" "secondary_failover" {
  count = local.environment == "prod" ? 1 : 0
  
  zone_id = var.route53_zone_id
  name    = "failover.${var.domain_name}"
  type    = "A"
  
  failover_routing_policy {
    type = "SECONDARY"
  }
  
  set_identifier = "secondary"
  
  alias {
    name                   = aws_s3_bucket_website_configuration.failover[0].website_domain
    zone_id                = aws_s3_bucket.failover[0].hosted_zone_id
    evaluate_target_health = false
  }
}

# S3 bucket for failover (static backup site)
resource "aws_s3_bucket" "failover" {
  count = local.environment == "prod" ? 1 : 0
  
  bucket = "${local.project}-failover"
  
  tags = {
    Name = "${local.project}-failover"
  }
}

# Enable S3 bucket website configuration for failover site
resource "aws_s3_bucket_website_configuration" "failover" {
  count = local.environment == "prod" ? 1 : 0
  
  bucket = aws_s3_bucket.failover[0].id
  
  index_document {
    suffix = "index.html"
  }
  
  error_document {
    key = "error.html"
  }
}

# S3 bucket public access for failover (static backup site)
resource "aws_s3_bucket_public_access_block" "failover" {
  count = local.environment == "prod" ? 1 : 0
  
  bucket = aws_s3_bucket.failover[0].id
  
  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

# S3 bucket policy for public read access to failover site
resource "aws_s3_bucket_policy" "failover" {
  count = local.environment == "prod" ? 1 : 0
  
  bucket = aws_s3_bucket.failover[0].id
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Principal = "*"
        Action = [
          "s3:GetObject"
        ]
        Effect = "Allow"
        Resource = [
          "${aws_s3_bucket.failover[0].arn}/*"
        ]
      }
    ]
  })
}

# Default failover page content
resource "aws_s3_object" "failover_index" {
  count = local.environment == "prod" ? 1 : 0
  
  bucket       = aws_s3_bucket.failover[0].id
  key          = "index.html"
  content      = <<-EOT
    <!DOCTYPE html>
    <html>
    <head>
      <title>SmartSphere - Maintenance</title>
      <style>
        body {
          font-family: Arial, sans-serif;
          margin: 0;
          padding: 0;
          display: flex;
          justify-content: center;
          align-items: center;
          height: 100vh;
          text-align: center;
          background-color: #f5f5f5;
        }
        .container {
          max-width: 600px;
          padding: 40px;
          background-color: white;
          border-radius: 10px;
          box-shadow: 0 4px 8px rgba(0, 0, 0, 0.1);
        }
        h1 {
          color: #333;
        }
        p {
          color: #666;
          font-size: 18px;
          line-height: 1.6;
        }
      </style>
    </head>
    <body>
      <div class="container">
        <h1>SmartSphere is currently undergoing maintenance</h1>
        <p>We're working hard to improve our services and will be back shortly.</p>
        <p>Thank you for your patience.</p>
      </div>
    </body>
    </html>
  EOT
  content_type = "text/html"
}

# Error page for failover site
resource "aws_s3_object" "failover_error" {
  count = local.environment == "prod" ? 1 : 0
  
  bucket       = aws_s3_bucket.failover[0].id
  key          = "error.html"
  content      = <<-EOT
    <!DOCTYPE html>
    <html>
    <head>
      <title>SmartSphere - Error</title>
      <style>
        body {
          font-family: Arial, sans-serif;
          margin: 0;
          padding: 0;
          display: flex;
          justify-content: center;
          align-items: center;
          height: 100vh;
          text-align: center;
          background-color: #f5f5f5;
        }
        .container {
          max-width: 600px;
          padding: 40px;
          background-color: white;
          border-radius: 10px;
          box-shadow: 0 4px 8px rgba(0, 0, 0, 0.1);
        }
        h1 {
          color: #333;
        }
        p {
          color: #666;
          font-size: 18px;
          line-height: 1.6;
        }
      </style>
    </head>
    <body>
      <div class="container">
        <h1>Page Not Found</h1>
        <p>The requested page could not be found.</p>
        <p>Please try again later or contact support if the problem persists.</p>
      </div>
    </body>
    </html>
  EOT
  content_type = "text/html"
}