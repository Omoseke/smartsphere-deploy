# Advanced monitoring and alerting configuration for SmartSphere

# Dashboard for service health metrics
resource "aws_cloudwatch_dashboard" "smartsphere" {
  dashboard_name = "SmartSphere-${var.environment}-Dashboard"
  
  dashboard_body = jsonencode({
    widgets = [
      # Service Health Overview
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 24
        height = 6
        properties = {
          metrics = [
            ["SmartSphere/${var.environment}", "ServiceHealth", "Service", "Frontend", { "stat" = "Average", "period" = 300 }],
            ["SmartSphere/${var.environment}", "ServiceHealth", "Service", "Backend", { "stat" = "Average", "period" = 300 }],
            ["SmartSphere/${var.environment}", "ServiceHealth", "Service", "Database", { "stat" = "Average", "period" = 300 }]
          ]
          view = "timeSeries"
          stacked = false
          region = var.aws_region
          title = "Service Health Overview"
          period = 300
          yAxis = {
            left = {
              min = 0
              max = 100
            }
          }
          annotations = {
            horizontal = [
              {
                value = 80
                label = "Warning Threshold"
                color = "#ff9900"
              },
              {
                value = 60
                label = "Critical Threshold"
                color = "#d13212"
              }
            ]
          }
        }
      },
      # API Latency
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/ApiGateway", "Latency", "ApiName", "smartsphere-api", { "stat" = "Average", "period" = 300 }],
            ["AWS/ApiGateway", "Latency", "ApiName", "smartsphere-api", { "stat" = "p90", "period" = 300 }],
            ["AWS/ApiGateway", "Latency", "ApiName", "smartsphere-api", { "stat" = "p99", "period" = 300 }]
          ]
          view = "timeSeries"
          stacked = false
          region = var.aws_region
          title = "API Latency"
          period = 300
        }
      },
      # Error Rates
      {
        type   = "metric"
        x      = 12
        y      = 6
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/ApiGateway", "5XXError", "ApiName", "smartsphere-api", { "stat" = "Sum", "period" = 300 }],
            ["AWS/ApiGateway", "4XXError", "ApiName", "smartsphere-api", { "stat" = "Sum", "period" = 300 }]
          ]
          view = "timeSeries"
          stacked = false
          region = var.aws_region
          title = "API Error Rates"
          period = 300
        }
      },
      # Database Metrics
      {
        type   = "metric"
        x      = 0
        y      = 12
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/RDS", "CPUUtilization", "DBInstanceIdentifier", "smartsphere-db", { "stat" = "Average", "period" = 300 }],
            ["AWS/RDS", "DatabaseConnections", "DBInstanceIdentifier", "smartsphere-db", { "stat" = "Average", "period" = 300, "yAxis" = "right" }]
          ]
          view = "timeSeries"
          stacked = false
          region = var.aws_region
          title = "Database Performance"
          period = 300
          yAxis = {
            left = {
              label = "CPU Utilization (%)"
            },
            right = {
              label = "DB Connections"
            }
          }
        }
      },
      # ECS Metrics
      {
        type   = "metric"
        x      = 12
        y      = 12
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/ECS", "CPUUtilization", "ServiceName", "smartsphere-service", "ClusterName", "smartsphere-cluster", { "stat" = "Average", "period" = 300 }],
            ["AWS/ECS", "MemoryUtilization", "ServiceName", "smartsphere-service", "ClusterName", "smartsphere-cluster", { "stat" = "Average", "period" = 300 }]
          ]
          view = "timeSeries"
          stacked = false
          region = var.aws_region
          title = "ECS Service Performance"
          period = 300
          yAxis = {
            left = {
              min = 0
              max = 100
              label = "Utilization (%)"
            }
          }
        }
      },
      # Custom Business Metrics
      {
        type   = "metric"
        x      = 0
        y      = 18
        width  = 24
        height = 6
        properties = {
          metrics = [
            ["SmartSphere/${var.environment}", "UserSignups", { "stat" = "Sum", "period" = 3600 }],
            ["SmartSphere/${var.environment}", "ActiveSessions", { "stat" = "Average", "period" = 300, "yAxis" = "right" }]
          ]
          view = "timeSeries"
          stacked = false
          region = var.aws_region
          title = "Business Metrics"
          period = 3600
          yAxis = {
            left = {
              label = "Sign-ups (Count)"
            },
            right = {
              label = "Active Sessions"
            }
          }
        }
      }
    ]
  })
}

# Enhanced CloudWatch Log Groups with improved retention and metric filters
resource "aws_cloudwatch_log_group" "api_logs" {
  name              = "/aws/apigateway/${var.environment}-smartsphere-api"
  retention_in_days = 30
  
  tags = merge(
    var.tags,
    {
      Name = "smartsphere-api-logs"
      Environment = var.environment
    }
  )
}

resource "aws_cloudwatch_log_group" "application_logs" {
  name              = "/smartsphere/${var.environment}/application"
  retention_in_days = 30
  
  tags = merge(
    var.tags,
    {
      Name = "smartsphere-application-logs"
      Environment = var.environment
    }
  )
}

resource "aws_cloudwatch_log_group" "ecs_logs" {
  name              = "/aws/ecs/smartsphere-${var.environment}"
  retention_in_days = 30
  
  tags = merge(
    var.tags,
    {
      Name = "smartsphere-ecs-logs"
      Environment = var.environment
    }
  )
}

# Metric filter for error tracking
resource "aws_cloudwatch_log_metric_filter" "error_metric" {
  name           = "smartsphere-${var.environment}-errors"
  pattern        = "ERROR"
  log_group_name = aws_cloudwatch_log_group.application_logs.name
  
  metric_transformation {
    name      = "ErrorCount"
    namespace = "SmartSphere/${var.environment}"
    value     = "1"
    dimensions = {
      Environment = var.environment
      LogGroup    = "application"
    }
  }
}

# Metric filter for API latency tracking from logs
resource "aws_cloudwatch_log_metric_filter" "api_latency_metric" {
  name           = "smartsphere-${var.environment}-api-latency"
  pattern        = "[timestamp, requestId, level, message = \"API Request Completed\", latency, status]"
  log_group_name = aws_cloudwatch_log_group.api_logs.name
  
  metric_transformation {
    name      = "ApiLatency"
    namespace = "SmartSphere/${var.environment}"
    value     = "$latency"
    dimensions = {
      Environment = var.environment
      LogGroup    = "api"
    }
  }
}

# Anomaly detection for error rates
resource "aws_cloudwatch_metric_alarm" "error_anomaly" {
  alarm_name          = "smartsphere-${var.environment}-error-anomaly"
  comparison_operator = "GreaterThanUpperThreshold"
  evaluation_periods  = 3
  threshold_metric_id = "e1"
  alarm_description   = "This alarm triggers when error rates exceed the expected threshold based on historical patterns"
  alarm_actions       = [aws_sns_topic.monitoring_alerts.arn]
  ok_actions          = [aws_sns_topic.monitoring_alerts.arn]
  
  metric_query {
    id          = "e1"
    expression  = "ANOMALY_DETECTION_BAND(m1, 2)"
    label       = "ErrorCount (Expected)"
    return_data = true
  }
  
  metric_query {
    id          = "m1"
    metric {
      metric_name = "ErrorCount"
      namespace   = "SmartSphere/${var.environment}"
      period      = 300
      stat        = "Sum"
      dimensions  = {
        Environment = var.environment
        LogGroup    = "application"
      }
    }
    return_data = true
  }
}

# Composite alarm for service health
resource "aws_cloudwatch_composite_alarm" "service_health" {
  alarm_name        = "smartsphere-${var.environment}-service-health"
  alarm_description = "Monitors overall service health across multiple components"
  alarm_actions     = [aws_sns_topic.monitoring_alerts.arn]
  ok_actions        = [aws_sns_topic.monitoring_alerts.arn]
  
  alarm_rule = "ALARM(${aws_cloudwatch_metric_alarm.api_error_rate.alarm_name}) OR ALARM(${aws_cloudwatch_metric_alarm.api_latency.alarm_name}) OR ALARM(${aws_cloudwatch_metric_alarm.db_cpu.alarm_name})"
}

# Standard CloudWatch Alarms
resource "aws_cloudwatch_metric_alarm" "api_error_rate" {
  alarm_name          = "smartsphere-${var.environment}-api-error-rate"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  metric_name         = "5XXError"
  namespace           = "AWS/ApiGateway"
  period              = 300
  statistic           = "Sum"
  threshold           = 5
  alarm_description   = "This alarm monitors API Gateway 5XX error rate"
  alarm_actions       = [aws_sns_topic.monitoring_alerts.arn]
  ok_actions          = [aws_sns_topic.monitoring_alerts.arn]
  
  dimensions = {
    ApiName = "smartsphere-api"
  }
}

resource "aws_cloudwatch_metric_alarm" "api_latency" {
  alarm_name          = "smartsphere-${var.environment}-api-latency"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  metric_name         = "Latency"
  namespace           = "AWS/ApiGateway"
  period              = 300
  extended_statistic  = "p95"
  threshold           = 1000 # 1 second
  alarm_description   = "This alarm monitors API Gateway p95 latency"
  alarm_actions       = [aws_sns_topic.monitoring_alerts.arn]
  ok_actions          = [aws_sns_topic.monitoring_alerts.arn]
  
  dimensions = {
    ApiName = "smartsphere-api"
  }
}

resource "aws_cloudwatch_metric_alarm" "db_cpu" {
  alarm_name          = "smartsphere-${var.environment}-db-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "This alarm monitors RDS CPU utilization"
  alarm_actions       = [aws_sns_topic.monitoring_alerts.arn]
  ok_actions          = [aws_sns_topic.monitoring_alerts.arn]
  
  dimensions = {
    DBInstanceIdentifier = "smartsphere-db"
  }
}

# SNS Topic for monitoring alerts
resource "aws_sns_topic" "monitoring_alerts" {
  name         = "smartsphere-${var.environment}-monitoring-alerts"
  display_name = "SmartSphere Monitoring Alerts"
  
  tags = merge(
    var.tags,
    {
      Name = "smartsphere-monitoring-alerts"
      Environment = var.environment
    }
  )
}

resource "aws_sns_topic_subscription" "email_alerts" {
  count     = var.alert_email_addresses != null ? length(var.alert_email_addresses) : 0
  topic_arn = aws_sns_topic.monitoring_alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email_addresses[count.index]
}

# Lambda function for advanced alert processing and notification
resource "aws_lambda_function" "alert_processor" {
  function_name    = "smartsphere-${var.environment}-alert-processor"
  role             = aws_iam_role.lambda_alert_processor.arn
  handler          = "index.handler"
  runtime          = "nodejs16.x"
  timeout          = 30
  memory_size      = 128
  source_code_hash = filebase64sha256("${path.module}/lambda/alert-processor.zip")
  filename         = "${path.module}/lambda/alert-processor.zip"
  
  environment {
    variables = {
      ENVIRONMENT    = var.environment
      PROJECT_NAME   = var.project
      SNS_TOPIC_ARN  = aws_sns_topic.monitoring_alerts.arn
      SLACK_WEBHOOK  = var.slack_webhook_url
      PAGERDUTY_KEY  = var.pagerduty_integration_key
    }
  }
  
  tags = merge(
    var.tags,
    {
      Name = "smartsphere-alert-processor"
      Environment = var.environment
    }
  )
}

# IAM Role for the alert processor Lambda
resource "aws_iam_role" "lambda_alert_processor" {
  name = "smartsphere-${var.environment}-lambda-alert-processor"
  
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
  
  tags = merge(
    var.tags,
    {
      Name = "smartsphere-lambda-alert-processor-role"
      Environment = var.environment
    }
  )
}

resource "aws_iam_role_policy" "lambda_alert_processor" {
  name = "smartsphere-${var.environment}-lambda-alert-processor-policy"
  role = aws_iam_role.lambda_alert_processor.id
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Effect = "Allow"
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Action = [
          "sns:Publish"
        ]
        Effect = "Allow"
        Resource = aws_sns_topic.monitoring_alerts.arn
      },
      {
        Action = [
          "cloudwatch:GetMetricData",
          "cloudwatch:GetMetricStatistics",
          "cloudwatch:DescribeAlarms",
          "cloudwatch:ListMetrics"
        ]
        Effect = "Allow"
        Resource = "*"
      }
    ]
  })
}

# CloudWatch Events Rule to trigger alert processor on alarms
resource "aws_cloudwatch_event_rule" "alarm_event" {
  name        = "smartsphere-${var.environment}-alarm-events"
  description = "Capture CloudWatch Alarm state changes"
  
  event_pattern = jsonencode({
    source = ["aws.cloudwatch"]
    detail_type = ["CloudWatch Alarm State Change"]
    resources = [
      aws_cloudwatch_metric_alarm.api_error_rate.arn,
      aws_cloudwatch_metric_alarm.api_latency.arn,
      aws_cloudwatch_metric_alarm.db_cpu.arn,
      aws_cloudwatch_composite_alarm.service_health.arn
    ]
  })
  
  tags = merge(
    var.tags,
    {
      Name = "smartsphere-alarm-events"
      Environment = var.environment
    }
  )
}

resource "aws_cloudwatch_event_target" "lambda_target" {
  rule      = aws_cloudwatch_event_rule.alarm_event.name
  target_id = "SendToLambda"
  arn       = aws_lambda_function.alert_processor.arn
}

resource "aws_lambda_permission" "allow_cloudwatch" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.alert_processor.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.alarm_event.arn
}

# Custom service health metrics - published by application
resource "aws_cloudwatch_metric_alarm" "business_metric_alarm" {
  alarm_name          = "smartsphere-${var.environment}-business-metric"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 3
  metric_name         = "UserSignups"
  namespace           = "SmartSphere/${var.environment}"
  period              = 3600
  statistic           = "Sum"
  threshold           = var.environment == "prod" ? 10 : 1
  alarm_description   = "This alarm monitors business-level metrics"
  alarm_actions       = [aws_sns_topic.monitoring_alerts.arn]
  ok_actions          = [aws_sns_topic.monitoring_alerts.arn]
  
  tags = merge(
    var.tags,
    {
      Name = "smartsphere-business-metric-alarm"
      Environment = var.environment
    }
  )
}

# Add variables for the monitoring configuration to variables.tf
# These variables need to be defined in the variables.tf file
# Example:
# 
# variable "alert_email_addresses" {
#   description = "List of email addresses to send monitoring alerts to"
#   type        = list(string)
#   default     = []
# }
# 
# variable "slack_webhook_url" {
#   description = "Slack webhook URL for monitoring notifications"
#   type        = string
#   default     = ""
# }
# 
# variable "pagerduty_integration_key" {
#   description = "PagerDuty integration key for monitoring notifications"
#   type        = string
#   default     = ""
# }