# CloudFront Distribution for SmartSphere Frontend

resource "aws_cloudfront_distribution" "frontend" {
  enabled             = true
  is_ipv6_enabled     = true
  comment             = "${local.project}-${local.environment} Distribution"
  default_root_object = "index.html"
  price_class         = "PriceClass_100" # Use only North America and Europe edge locations
  wait_for_deployment = false
  web_acl_id          = aws_wafv2_web_acl.cloudfront.arn
  
  # S3 origin for frontend static assets
  origin {
    domain_name              = aws_s3_bucket.frontend.bucket_regional_domain_name
    origin_id                = "S3-${local.project}-${local.environment}-frontend"
    origin_access_control_id = aws_cloudfront_origin_access_control.s3_oac.id
  }
  
  # ALB origin for API requests
  origin {
    domain_name = aws_lb.main.dns_name
    origin_id   = "ALB-${local.project}-${local.environment}"
    
    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "https-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }
  
  # Default cache behavior for frontend static assets
  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD", "OPTIONS"]
    target_origin_id       = "S3-${local.project}-${local.environment}-frontend"
    viewer_protocol_policy = "redirect-to-https"
    compress               = true
    
    cache_policy_id          = aws_cloudfront_cache_policy.frontend.id
    origin_request_policy_id = aws_cloudfront_origin_request_policy.frontend.id
    
    function_association {
      event_type   = "viewer-request"
      function_arn = aws_cloudfront_function.url_rewrite.arn
    }
  }
  
  # Cache behavior for API requests
  ordered_cache_behavior {
    path_pattern           = "/api/*"
    allowed_methods        = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods         = ["GET", "HEAD", "OPTIONS"]
    target_origin_id       = "ALB-${local.project}-${local.environment}"
    viewer_protocol_policy = "redirect-to-https"
    compress               = true
    
    cache_policy_id          = aws_cloudfront_cache_policy.api.id
    origin_request_policy_id = aws_cloudfront_origin_request_policy.api.id
  }
  
  # Custom error responses for SPA
  custom_error_response {
    error_code            = 403
    response_code         = 200
    response_page_path    = "/index.html"
    error_caching_min_ttl = 10
  }
  
  custom_error_response {
    error_code            = 404
    response_code         = 200
    response_page_path    = "/index.html"
    error_caching_min_ttl = 10
  }
  
  # Domain configuration
  aliases = [local.domain_name]
  
  # SSL certificate
  viewer_certificate {
    acm_certificate_arn      = var.certificate_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }
  
  # Geo restrictions - optional, can be customized
  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }
  
  tags = {
    Name = "${local.project}-${local.environment}-distribution"
  }
}

# CloudFront Origin Access Control for S3
resource "aws_cloudfront_origin_access_control" "s3_oac" {
  name                              = "${local.project}-${local.environment}-s3-oac"
  description                       = "Origin access control for S3 frontend bucket"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# CloudFront Function for URL rewrites (SPA support)
resource "aws_cloudfront_function" "url_rewrite" {
  name    = "${local.project}-${local.environment}-url-rewrite"
  runtime = "cloudfront-js-1.0"
  code    = <<-EOT
    function handler(event) {
      var request = event.request;
      var uri = request.uri;
      
      // Check whether the URI is missing a file extension
      if (!uri.includes('.')) {
        request.uri = '/index.html';
      }
      
      return request;
    }
  EOT
  
  publish = true
}

# Cache policy for frontend static assets
resource "aws_cloudfront_cache_policy" "frontend" {
  name        = "${local.project}-${local.environment}-frontend-cache-policy"
  comment     = "Cache policy for ${local.project} frontend static assets"
  default_ttl = 86400    # 1 day
  max_ttl     = 31536000 # 1 year
  min_ttl     = 0
  
  parameters_in_cache_key_and_forwarded_to_origin {
    cookies_config {
      cookie_behavior = "none"
    }
    
    headers_config {
      header_behavior = "none"
    }
    
    query_strings_config {
      query_string_behavior = "none"
    }
    
    enable_accept_encoding_brotli = true
    enable_accept_encoding_gzip   = true
  }
}

# Cache policy for API requests
resource "aws_cloudfront_cache_policy" "api" {
  name        = "${local.project}-${local.environment}-api-cache-policy"
  comment     = "Cache policy for ${local.project} API requests"
  default_ttl = 0
  max_ttl     = 0
  min_ttl     = 0
  
  parameters_in_cache_key_and_forwarded_to_origin {
    cookies_config {
      cookie_behavior = "all"
    }
    
    headers_config {
      header_behavior = "whitelist"
      headers {
        items = ["Authorization", "Content-Type", "Accept"]
      }
    }
    
    query_strings_config {
      query_string_behavior = "all"
    }
    
    enable_accept_encoding_brotli = true
    enable_accept_encoding_gzip   = true
  }
}

# Origin request policy for frontend static assets
resource "aws_cloudfront_origin_request_policy" "frontend" {
  name    = "${local.project}-${local.environment}-frontend-origin-policy"
  comment = "Origin request policy for ${local.project} frontend static assets"
  
  cookies_config {
    cookie_behavior = "none"
  }
  
  headers_config {
    header_behavior = "whitelist"
    headers {
      items = ["Origin", "Access-Control-Request-Method", "Access-Control-Request-Headers"]
    }
  }
  
  query_strings_config {
    query_string_behavior = "none"
  }
}

# Origin request policy for API requests
resource "aws_cloudfront_origin_request_policy" "api" {
  name    = "${local.project}-${local.environment}-api-origin-policy"
  comment = "Origin request policy for ${local.project} API requests"
  
  cookies_config {
    cookie_behavior = "all"
  }
  
  headers_config {
    header_behavior = "allViewer"
  }
  
  query_strings_config {
    query_string_behavior = "all"
  }
}

# WAF Web ACL for CloudFront
resource "aws_wafv2_web_acl" "cloudfront" {
  name        = "${local.project}-${local.environment}-cf-web-acl"
  description = "Web ACL for ${local.project}-${local.environment} CloudFront"
  scope       = "CLOUDFRONT"
  
  default_action {
    allow {}
  }
  
  # Common attack protection rule group
  rule {
    name     = "AWS-AWSManagedRulesCommonRuleSet"
    priority = 10
    
    override_action {
      none {}
    }
    
    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }
    
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AWSManagedRulesCommonRuleSet"
      sampled_requests_enabled   = true
    }
  }
  
  # SQL injection protection rule group
  rule {
    name     = "AWS-AWSManagedRulesSQLiRuleSet"
    priority = 20
    
    override_action {
      none {}
    }
    
    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesSQLiRuleSet"
        vendor_name = "AWS"
      }
    }
    
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AWSManagedRulesSQLiRuleSet"
      sampled_requests_enabled   = true
    }
  }
  
  # Rate limiting rule - higher limit for CloudFront
  rule {
    name     = "RateLimit"
    priority = 30
    
    action {
      block {}
    }
    
    statement {
      rate_based_statement {
        limit              = 5000
        aggregate_key_type = "IP"
      }
    }
    
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "RateLimit"
      sampled_requests_enabled   = true
    }
  }
  
  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "${local.project}-${local.environment}-cf-web-acl"
    sampled_requests_enabled   = true
  }
  
  tags = {
    Name = "${local.project}-${local.environment}-cf-web-acl"
  }
}