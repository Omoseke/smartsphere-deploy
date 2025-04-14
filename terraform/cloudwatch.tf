# CloudWatch Configuration for SmartSphere

# CloudWatch Dashboard
resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "${local.project}-${local.environment}"
  
  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "text"
        x      = 0
        y      = 0
        width  = 24
        height = 1
        properties = {
          markdown = "# ${upper(local.project)} - ${upper(local.environment)} Environment Metrics"
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
            ["AWS/ApplicationELB", "RequestCount", "LoadBalancer", aws_lb.main.arn_suffix]
          ]
          region = var.aws_region
          title  = "ALB Request Count"
          period = 60
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
            ["AWS/ApplicationELB", "TargetResponseTime", "LoadBalancer", aws_lb.main.arn_suffix, { "stat": "Average" }],
            ["AWS/ApplicationELB", "TargetResponseTime", "LoadBalancer", aws_lb.main.arn_suffix, { "stat": "p95" }]
          ]
          region = var.aws_region
          title  = "ALB Response Time (Average and p95)"
          period = 60
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 7
        width  = 8
        height = 6
        properties = {
          view    = "timeSeries"
          stacked = false
          metrics = [
            ["AWS/ECS", "CPUUtilization", "ServiceName", aws_ecs_service.app.name, "ClusterName", aws_ecs_cluster.main.name],
          ]
          region = var.aws_region
          title  = "ECS CPU Utilization (%)"
          period = 60
        }
      },
      {
        type   = "metric"
        x      = 8
        y      = 7
        width  = 8
        height = 6
        properties = {
          view    = "timeSeries"
          stacked = false
          metrics = [
            ["AWS/ECS", "MemoryUtilization", "ServiceName", aws_ecs_service.app.name, "ClusterName", aws_ecs_cluster.main.name],
          ]
          region = var.aws_region
          title  = "ECS Memory Utilization (%)"
          period = 60
        }
      },
      {
        type   = "metric"
        x      = 16
        y      = 7
        width  = 8
        height = 6
        properties = {
          view    = "timeSeries"
          stacked = false
          metrics = [
            ["AWS/RDS", "CPUUtilization", "DBInstanceIdentifier", aws_db_instance.postgres.id],
          ]
          region = var.aws_region
          title  = "RDS CPU Utilization (%)"
          period = 60
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 13
        width  = 12
        height = 6
        properties = {
          view    = "timeSeries"
          stacked = false
          metrics = [
            ["AWS/RDS", "ReadIOPS", "DBInstanceIdentifier", aws_db_instance.postgres.id],
            ["AWS/RDS", "WriteIOPS", "DBInstanceIdentifier", aws_db_instance.postgres.id]
          ]
          region = var.aws_region
          title  = "RDS Read/Write IOPS"
          period = 60
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 13
        width  = 12
        height = 6
        properties = {
          view    = "timeSeries"
          stacked = false
          metrics = [
            ["AWS/CloudFront", "Requests", "DistributionId", aws_cloudfront_distribution.frontend.id, "Region", "Global"]
          ]
          region = "us-east-1" # CloudFront metrics are in us-east-1 regardless of distribution region
          title  = "CloudFront Requests"
          period = 60
        }
      },
      {
        type   = "log"
        x      = 0
        y      = 19
        width  = 24
        height = 6
        properties = {
          query  = "SOURCE '/aws/ecs/${local.project}-${local.environment}/app' | filter @message like /ERROR/ | stats count(*) as error_count by bin(30s)"
          region = var.aws_region
          title  = "Application Error Count (30s bins)"
          view   = "timeSeries"
        }
      }
    ]
  })
}

# High CPU Alarm for ECS Service
resource "aws_cloudwatch_metric_alarm" "ecs_cpu_high" {
  alarm_name          = "${local.project}-${local.environment}-ecs-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = 60
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "Average CPU utilization is too high"
  
  dimensions = {
    ClusterName = aws_ecs_cluster.main.name
    ServiceName = aws_ecs_service.app.name
  }
  
  alarm_actions = [aws_sns_topic.alerts.arn]
  ok_actions    = [aws_sns_topic.alerts.arn]
}

# High Memory Alarm for ECS Service
resource "aws_cloudwatch_metric_alarm" "ecs_memory_high" {
  alarm_name          = "${local.project}-${local.environment}-ecs-memory-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "MemoryUtilization"
  namespace           = "AWS/ECS"
  period              = 60
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "Average memory utilization is too high"
  
  dimensions = {
    ClusterName = aws_ecs_cluster.main.name
    ServiceName = aws_ecs_service.app.name
  }
  
  alarm_actions = [aws_sns_topic.alerts.arn]
  ok_actions    = [aws_sns_topic.alerts.arn]
}

# High CPU Alarm for RDS
resource "aws_cloudwatch_metric_alarm" "db_cpu_high" {
  alarm_name          = "${local.project}-${local.environment}-db-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = 60
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "Average database CPU utilization is too high"
  
  dimensions = {
    DBInstanceIdentifier = aws_db_instance.postgres.id
  }
  
  alarm_actions = [aws_sns_topic.alerts.arn]
  ok_actions    = [aws_sns_topic.alerts.arn]
}

# High DB Connections Alarm
resource "aws_cloudwatch_metric_alarm" "db_connections_high" {
  alarm_name          = "${local.project}-${local.environment}-db-connections-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  metric_name         = "DatabaseConnections"
  namespace           = "AWS/RDS"
  period              = 60
  statistic           = "Average"
  threshold           = local.environment == "prod" ? 80 : 50
  alarm_description   = "Average database connection count is too high"
  
  dimensions = {
    DBInstanceIdentifier = aws_db_instance.postgres.id
  }
  
  alarm_actions = [aws_sns_topic.alerts.arn]
  ok_actions    = [aws_sns_topic.alerts.arn]
}

# Low Storage Space Alarm
resource "aws_cloudwatch_metric_alarm" "db_storage_low" {
  alarm_name          = "${local.project}-${local.environment}-db-storage-low"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 1
  metric_name         = "FreeStorageSpace"
  namespace           = "AWS/RDS"
  period              = 60
  statistic           = "Average"
  threshold           = local.environment == "prod" ? 20480 : 10240 # 20GB for prod, 10GB otherwise
  alarm_description   = "Average free storage space is too low"
  
  dimensions = {
    DBInstanceIdentifier = aws_db_instance.postgres.id
  }
  
  alarm_actions = [aws_sns_topic.alerts.arn]
  ok_actions    = [aws_sns_topic.alerts.arn]
}

# High 5XX Error Rate Alarm for ALB
resource "aws_cloudwatch_metric_alarm" "alb_5xx_errors" {
  alarm_name          = "${local.project}-${local.environment}-alb-5xx-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "HTTPCode_ELB_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Sum"
  threshold           = 10
  alarm_description   = "Load balancer is returning 5XX errors"
  
  dimensions = {
    LoadBalancer = aws_lb.main.arn_suffix
  }
  
  alarm_actions = [aws_sns_topic.alerts.arn]
  ok_actions    = [aws_sns_topic.alerts.arn]
}

# Target 5XX Error Rate Alarm for ALB
resource "aws_cloudwatch_metric_alarm" "target_5xx_errors" {
  alarm_name          = "${local.project}-${local.environment}-target-5xx-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "HTTPCode_Target_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Sum"
  threshold           = 10
  alarm_description   = "Targets are returning 5XX errors"
  
  dimensions = {
    LoadBalancer = aws_lb.main.arn_suffix
  }
  
  alarm_actions = [aws_sns_topic.alerts.arn]
  ok_actions    = [aws_sns_topic.alerts.arn]
}

# High Response Time Alarm for ALB
resource "aws_cloudwatch_metric_alarm" "alb_response_time" {
  alarm_name          = "${local.project}-${local.environment}-alb-response-time"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  metric_name         = "TargetResponseTime"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Maximum"
  # Note: For percentiles, use extended_statistic instead of statistic
  # extended_statistic   = "p95"
  threshold           = 1 # 1 second
  alarm_description   = "Target response time is too high (p95)"
  
  dimensions = {
    LoadBalancer = aws_lb.main.arn_suffix
  }
  
  alarm_actions = [aws_sns_topic.alerts.arn]
  ok_actions    = [aws_sns_topic.alerts.arn]
}

# SNS Topic for Alarms
resource "aws_sns_topic" "alerts" {
  name = "${local.project}-${local.environment}-alerts"
  
  tags = {
    Name = "${local.project}-${local.environment}-alerts"
  }
}

# Log Metric Filter for Application Errors
resource "aws_cloudwatch_log_metric_filter" "app_errors" {
  name           = "${local.project}-${local.environment}-app-errors"
  pattern        = "ERROR"
  log_group_name = aws_cloudwatch_log_group.app.name
  
  metric_transformation {
    name      = "AppErrorCount"
    namespace = "${local.project}/${local.environment}"
    value     = "1"
  }
}

# Application Error Alarm
resource "aws_cloudwatch_metric_alarm" "app_errors" {
  alarm_name          = "${local.project}-${local.environment}-app-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "AppErrorCount"
  namespace           = "${local.project}/${local.environment}"
  period              = 60
  statistic           = "Sum"
  threshold           = local.environment == "prod" ? 5 : 10
  alarm_description   = "High number of application errors detected"
  
  alarm_actions = [aws_sns_topic.alerts.arn]
  ok_actions    = [aws_sns_topic.alerts.arn]
}

# Composite Alarm for Critical Issues
resource "aws_cloudwatch_composite_alarm" "critical" {
  count = local.environment == "prod" ? 1 : 0
  
  alarm_name        = "${local.project}-${local.environment}-critical-issues"
  alarm_description = "Alarm when multiple critical issues are detected"
  
  alarm_rule = <<EOF
ALARM(${aws_cloudwatch_metric_alarm.ecs_cpu_high.alarm_name}) OR
ALARM(${aws_cloudwatch_metric_alarm.db_cpu_high.alarm_name}) OR
(ALARM(${aws_cloudwatch_metric_alarm.alb_5xx_errors.alarm_name}) AND ALARM(${aws_cloudwatch_metric_alarm.app_errors.alarm_name}))
EOF
  
  alarm_actions = [aws_sns_topic.alerts.arn]
  ok_actions    = [aws_sns_topic.alerts.arn]
}

# CloudWatch Logs Insights Queries
resource "aws_cloudwatch_query_definition" "error_analysis" {
  name = "${local.project}-${local.environment}-error-analysis"
  
  log_group_names = [
    aws_cloudwatch_log_group.app.name
  ]
  
  query_string = <<EOF
fields @timestamp, @message
| filter @message like /ERROR/
| stats count(*) as error_count by bin(1h)
| sort @timestamp desc
EOF
}

resource "aws_cloudwatch_query_definition" "slow_requests" {
  name = "${local.project}-${local.environment}-slow-requests"
  
  log_group_names = [
    aws_cloudwatch_log_group.app.name
  ]
  
  query_string = <<EOF
fields @timestamp, @message
| filter @message like /duration/ and @message like /ms/
| parse @message /duration*: *(?<duration_ms>[0-9.]+)ms/ 
| filter duration_ms > 1000
| sort by duration_ms desc
| limit 100
EOF
}

####################################################################
# Performance Benchmark Alerts
####################################################################

# API Response Time Performance Benchmark Alarm
resource "aws_cloudwatch_metric_alarm" "api_performance_benchmark" {
  alarm_name          = "${local.project}-${local.environment}-api-performance-benchmark"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 5
  datapoints_to_alarm = 3
  threshold           = local.environment == "prod" ? 0.5 : 1.0 # Stricter in production
  alarm_description   = "API response time exceeds performance benchmark thresholds"
  treat_missing_data  = "notBreaching"
  
  metric_query {
    id          = "m1"
    return_data = true
    expression  = "ANOMALY_DETECTION_BAND(m2, 2)"
    label       = "API Response Time (Expected Range)"
  }
  
  metric_query {
    id          = "m2"
    return_data = false
    metric {
      metric_name = "TargetResponseTime"
      namespace   = "AWS/ApplicationELB"
      period      = 60
      stat        = "p95"
      dimensions = {
        LoadBalancer = aws_lb.main.arn_suffix
      }
    }
  }
  
  alarm_actions = [aws_sns_topic.performance_alerts.arn]
  ok_actions    = [aws_sns_topic.performance_alerts.arn]
  
  tags = {
    Name        = "${local.project}-${local.environment}-api-performance-benchmark"
    Environment = local.environment
    Type        = "PerformanceBenchmark"
  }
}

# Database Query Performance Benchmark Alarm
resource "aws_cloudwatch_metric_alarm" "db_performance_benchmark" {
  alarm_name          = "${local.project}-${local.environment}-db-performance-benchmark"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 5
  datapoints_to_alarm = 3
  threshold           = 0.2
  alarm_description   = "Database read/write latency exceeds performance benchmark thresholds"
  treat_missing_data  = "notBreaching"
  
  metric_query {
    id          = "e1"
    expression  = "MAX([m1, m2])"
    label       = "Maximum DB Latency"
    return_data = true
  }
  
  metric_query {
    id          = "m1"
    return_data = false
    metric {
      metric_name = "ReadLatency"
      namespace   = "AWS/RDS"
      period      = 60
      stat        = "Average"
      dimensions = {
        DBInstanceIdentifier = aws_db_instance.postgres.id
      }
    }
  }
  
  metric_query {
    id          = "m2"
    return_data = false
    metric {
      metric_name = "WriteLatency"
      namespace   = "AWS/RDS"
      period      = 60
      stat        = "Average"
      dimensions = {
        DBInstanceIdentifier = aws_db_instance.postgres.id
      }
    }
  }
  
  alarm_actions = [aws_sns_topic.performance_alerts.arn]
  ok_actions    = [aws_sns_topic.performance_alerts.arn]
  
  tags = {
    Name        = "${local.project}-${local.environment}-db-performance-benchmark"
    Environment = local.environment
    Type        = "PerformanceBenchmark"
  }
}

# UI Load Time Performance Benchmark Alarm (via CloudFront)
resource "aws_cloudwatch_metric_alarm" "ui_performance_benchmark" {
  alarm_name          = "${local.project}-${local.environment}-ui-performance-benchmark"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 5
  datapoints_to_alarm = 3
  threshold           = 100 # 100ms download time for UI assets
  alarm_description   = "UI assets download time exceeds performance benchmark thresholds"
  treat_missing_data  = "notBreaching"
  
  metric_name         = "DownloadTime"
  namespace           = "AWS/CloudFront"
  period              = 60
  statistic           = "Average"
  dimensions = {
    DistributionId = aws_cloudfront_distribution.frontend.id
    Region         = "Global"
  }
  
  alarm_actions = [aws_sns_topic.performance_alerts.arn]
  ok_actions    = [aws_sns_topic.performance_alerts.arn]
  
  tags = {
    Name        = "${local.project}-${local.environment}-ui-performance-benchmark"
    Environment = local.environment
    Type        = "PerformanceBenchmark"
  }
}

# Network Latency Performance Benchmark Alarm
resource "aws_cloudwatch_metric_alarm" "network_performance_benchmark" {
  alarm_name          = "${local.project}-${local.environment}-network-performance-benchmark"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  datapoints_to_alarm = 2
  threshold           = 50 # 50ms network latency
  alarm_description   = "Network latency exceeds performance benchmark thresholds"
  treat_missing_data  = "notBreaching"
  
  metric_name         = "NetworkLatency"
  namespace           = "AWS/CloudFront"
  period              = 60
  statistic           = "Average"
  dimensions = {
    DistributionId = aws_cloudfront_distribution.frontend.id
    Region         = "Global"
  }
  
  alarm_actions = [aws_sns_topic.performance_alerts.arn]
  ok_actions    = [aws_sns_topic.performance_alerts.arn]
  
  tags = {
    Name        = "${local.project}-${local.environment}-network-performance-benchmark"
    Environment = local.environment
    Type        = "PerformanceBenchmark"
  }
}

# Synthetic Canary for End-to-End Performance Testing
resource "aws_synthetics_canary" "api_performance" {
  name                 = "${local.project}-${local.environment}-api-performance"
  artifact_s3_location = "s3://${aws_s3_bucket.monitoring.id}/canary-artifacts/"
  execution_role_arn   = aws_iam_role.canary_role.arn
  handler              = "apiCanary.handler"
  zip_file             = "${path.module}/canary/api-performance-canary.zip"
  runtime_version      = "syn-nodejs-puppeteer-3.5"
  
  schedule {
    expression = "rate(5 minutes)"
  }
  
  run_config {
    timeout_in_seconds = 60
    memory_in_mb       = 1024
    active_tracing     = true
  }
  
  success_retention_period = 7
  failure_retention_period = 30
  
  vpc_config {
    subnet_ids         = [module.vpc.private_subnets[0]]
    security_group_ids = [aws_security_group.canary.id]
  }
  
  tags = {
    Name        = "${local.project}-${local.environment}-api-performance"
    Environment = local.environment
    Type        = "PerformanceBenchmark"
  }
}

# IAM Role for Synthetics Canary
resource "aws_iam_role" "canary_role" {
  name = "${local.project}-${local.environment}-canary-role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
  
  tags = {
    Name        = "${local.project}-${local.environment}-canary-role"
    Environment = local.environment
  }
}

# IAM Policy for Synthetics Canary
resource "aws_iam_policy" "canary_policy" {
  name        = "${local.project}-${local.environment}-canary-policy"
  description = "Policy for CloudWatch Synthetics Canary"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:PutObject",
          "s3:GetObject"
        ]
        Effect   = "Allow"
        Resource = "${aws_s3_bucket.monitoring.arn}/*"
      },
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
      {
        Action = [
          "ec2:CreateNetworkInterface",
          "ec2:DescribeNetworkInterfaces",
          "ec2:DeleteNetworkInterface"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
      {
        Action = [
          "cloudwatch:PutMetricData"
        ]
        Effect   = "Allow"
        Resource = "*"
        Condition = {
          StringEquals = {
            "cloudwatch:namespace" = "CloudWatchSynthetics"
          }
        }
      }
    ]
  })
}

# Attach the policy to the role
resource "aws_iam_role_policy_attachment" "canary_policy_attachment" {
  role       = aws_iam_role.canary_role.name
  policy_arn = aws_iam_policy.canary_policy.arn
}

# Security Group for Canary
resource "aws_security_group" "canary" {
  name        = "${local.project}-${local.environment}-canary-sg"
  description = "Security group for CloudWatch Synthetic Canary"
  vpc_id      = module.vpc.vpc_id
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  tags = {
    Name        = "${local.project}-${local.environment}-canary-sg"
    Environment = local.environment
  }
}

# S3 Bucket for Monitoring Artifacts
resource "aws_s3_bucket" "monitoring" {
  bucket = "${local.project}-${local.environment}-monitoring"
  
  tags = {
    Name        = "${local.project}-${local.environment}-monitoring"
    Environment = local.environment
  }
}

# Block public access to the monitoring bucket
resource "aws_s3_bucket_public_access_block" "monitoring" {
  bucket = aws_s3_bucket.monitoring.id
  
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Enable server-side encryption for the monitoring bucket
resource "aws_s3_bucket_server_side_encryption_configuration" "monitoring" {
  bucket = aws_s3_bucket.monitoring.id
  
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# SNS Topic for Performance Alerts
resource "aws_sns_topic" "performance_alerts" {
  name = "${local.project}-${local.environment}-performance-alerts"
  
  tags = {
    Name        = "${local.project}-${local.environment}-performance-alerts"
    Environment = local.environment
    Type        = "PerformanceBenchmark"
  }
}

# Baseline Performance Dashboard
resource "aws_cloudwatch_dashboard" "performance_benchmarks" {
  dashboard_name = "${local.project}-${local.environment}-performance-benchmarks"
  
  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "text"
        x      = 0
        y      = 0
        width  = 24
        height = 1
        properties = {
          markdown = "# ${upper(local.project)} ${upper(local.environment)} - Performance Benchmarks Dashboard"
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
            ["AWS/ApplicationELB", "TargetResponseTime", "LoadBalancer", aws_lb.main.arn_suffix, { "stat": "p50", "label": "p50 (median)" }],
            ["AWS/ApplicationELB", "TargetResponseTime", "LoadBalancer", aws_lb.main.arn_suffix, { "stat": "p90", "label": "p90" }],
            ["AWS/ApplicationELB", "TargetResponseTime", "LoadBalancer", aws_lb.main.arn_suffix, { "stat": "p95", "label": "p95" }],
            ["AWS/ApplicationELB", "TargetResponseTime", "LoadBalancer", aws_lb.main.arn_suffix, { "stat": "p99", "label": "p99" }]
          ]
          region  = var.primary_region
          title   = "API Response Time Percentiles"
          period  = 60
          annotations = {
            horizontal = [
              {
                value = local.environment == "prod" ? 0.5 : 1.0,
                label = "Benchmark Threshold",
                color = "#ff0000"
              }
            ]
          }
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
            ["AWS/RDS", "ReadLatency", "DBInstanceIdentifier", aws_db_instance.postgres.id],
            ["AWS/RDS", "WriteLatency", "DBInstanceIdentifier", aws_db_instance.postgres.id]
          ]
          region  = var.primary_region
          title   = "Database Latency"
          period  = 60
          annotations = {
            horizontal = [
              {
                value = 0.02,
                label = "Good Performance",
                color = "#2ca02c"
              },
              {
                value = 0.05,
                label = "Acceptable Performance",
                color = "#dbdb0a"
              },
              {
                value = 0.2,
                label = "Poor Performance",
                color = "#d62728"
              }
            ]
          }
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
            ["AWS/CloudFront", "DownloadTime", "DistributionId", aws_cloudfront_distribution.frontend.id, "Region", "Global"]
          ]
          region  = "us-east-1"
          title   = "UI Asset Download Time"
          period  = 60
          annotations = {
            horizontal = [
              {
                value = 100,
                label = "Benchmark Threshold (100ms)",
                color = "#ff0000"
              }
            ]
          }
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
            ["CloudWatchSynthetics", "Duration", "CanaryName", aws_synthetics_canary.api_performance.name, { "stat": "Average" }],
            ["CloudWatchSynthetics", "Duration", "CanaryName", aws_synthetics_canary.api_performance.name, { "stat": "p90" }]
          ]
          region  = var.primary_region
          title   = "End-to-End Performance (Synthetic Canary)"
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
            ["CloudWatchSynthetics", "SuccessPercent", "CanaryName", aws_synthetics_canary.api_performance.name]
          ]
          region  = var.primary_region
          title   = "End-to-End Success Rate"
          period  = 300
          yAxis = {
            left = {
              min = 0,
              max = 100
            }
          }
        }
      }
    ]
  })
}