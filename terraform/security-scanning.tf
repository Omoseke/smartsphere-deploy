# Advanced Security Scanning for SmartSphere Infrastructure

locals {
  # Security scanning configuration
  security_scanning_schedule = "cron(0 0 * * ? *)"  # Daily at midnight UTC
  security_findings_bucket   = "${local.project}-${local.environment}-security-findings"
  security_findings_prefix   = "findings"
  security_reports_prefix    = "reports"
  
  # Configuration for various security scanners
  enable_inspector           = true
  enable_guardduty           = true
  enable_securityhub         = true
  enable_config              = true
  enable_prowler             = true
  
  # Severities to alert on
  alert_severities           = ["CRITICAL", "HIGH"]
}

# S3 bucket for security findings and reports
resource "aws_s3_bucket" "security_findings" {
  bucket = local.security_findings_bucket
  
  tags = {
    Name        = local.security_findings_bucket
    Environment = local.environment
    Service     = "SecurityScanning"
  }
}

# Block public access for security findings bucket
resource "aws_s3_bucket_public_access_block" "security_findings" {
  bucket = aws_s3_bucket.security_findings.id
  
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Enable versioning for security findings bucket
resource "aws_s3_bucket_versioning" "security_findings" {
  bucket = aws_s3_bucket.security_findings.id
  
  versioning_configuration {
    status = "Enabled"
  }
}

# Enable server-side encryption for security findings bucket
resource "aws_s3_bucket_server_side_encryption_configuration" "security_findings" {
  bucket = aws_s3_bucket.security_findings.id
  
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# SNS Topic for security findings
resource "aws_sns_topic" "security_findings" {
  name = "${local.project}-${local.environment}-security-findings"
  
  tags = {
    Name        = "${local.project}-${local.environment}-security-findings"
    Environment = local.environment
    Service     = "SecurityScanning"
  }
}

# IAM Role for security scanning Lambda
resource "aws_iam_role" "security_scanner" {
  name = "${local.project}-${local.environment}-security-scanner-role"
  
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
    Name        = "${local.project}-${local.environment}-security-scanner-role"
    Environment = local.environment
    Service     = "SecurityScanning"
  }
}

# IAM Policy for security scanning
resource "aws_iam_policy" "security_scanner" {
  name        = "${local.project}-${local.environment}-security-scanner-policy"
  description = "Policy for security scanning Lambda"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Effect   = "Allow"
        Resource = [
          aws_s3_bucket.security_findings.arn,
          "${aws_s3_bucket.security_findings.arn}/*"
        ]
      },
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Effect   = "Allow"
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Action = [
          "sns:Publish"
        ]
        Effect   = "Allow"
        Resource = aws_sns_topic.security_findings.arn
      },
      {
        Action = [
          "inspector2:ListFindings",
          "inspector2:ListCoverage",
          "inspector2:BatchGetFindingDetails",
          "inspector2:GetFindingsReportStatus",
          "inspector2:ListCoverageStatistics"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
      {
        Action = [
          "guardduty:ListFindings",
          "guardduty:GetFindings",
          "guardduty:GetFindingsStatistics"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
      {
        Action = [
          "securityhub:GetFindings",
          "securityhub:UpdateFindings",
          "securityhub:BatchImportFindings"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
      {
        Action = [
          "config:DescribeComplianceByConfigRule",
          "config:GetComplianceDetailsByConfigRule",
          "config:DescribeConfigRules"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
      {
        Action = [
          "ec2:DescribeInstances",
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeNetworkAcls",
          "ec2:DescribeVpcs",
          "ec2:DescribeSubnets",
          "ec2:DescribeRouteTables"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
      {
        Action = [
          "ecs:DescribeClusters",
          "ecs:DescribeServices",
          "ecs:DescribeTaskDefinition",
          "ecs:ListTasks",
          "ecs:DescribeTasks"
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
      }
    ]
  })
}

# Attach policy to role
resource "aws_iam_role_policy_attachment" "security_scanner" {
  role       = aws_iam_role.security_scanner.name
  policy_arn = aws_iam_policy.security_scanner.arn
}

# Amazon Inspector
resource "aws_inspector2_enabler" "inspector" {
  count = local.enable_inspector ? 1 : 0
  
  account_ids    = [data.aws_caller_identity.current.account_id]
  resource_types = ["EC2", "ECR"]
}

# GuardDuty
resource "aws_guardduty_detector" "main" {
  count = local.enable_guardduty ? 1 : 0
  
  enable = true
  
  finding_publishing_frequency = "SIX_HOURS"
  
  datasources {
    s3_logs {
      enable = true
    }
    kubernetes {
      audit_logs {
        enable = true
      }
    }
    malware_protection {
      scan_ec2_instance_with_findings {
        ebs_volumes {
          enable = true
        }
      }
    }
  }
}

# Security Hub
resource "aws_securityhub_account" "main" {
  count = local.enable_securityhub ? 1 : 0
  
  enable_default_standards = true
}

# AWS Config
resource "aws_config_configuration_recorder" "main" {
  count = local.enable_config ? 1 : 0
  
  name     = "${local.project}-${local.environment}-config-recorder"
  role_arn = aws_iam_role.config_role[0].arn
  
  recording_group {
    all_supported                 = true
    include_global_resource_types = true
  }
}

resource "aws_iam_role" "config_role" {
  count = local.enable_config ? 1 : 0
  
  name = "${local.project}-${local.environment}-config-role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "config.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "config_policy" {
  count = local.enable_config ? 1 : 0
  
  role       = aws_iam_role.config_role[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWS_ConfigRole"
}

resource "aws_config_delivery_channel" "main" {
  count = local.enable_config ? 1 : 0
  
  name           = "${local.project}-${local.environment}-config-channel"
  s3_bucket_name = aws_s3_bucket.security_findings.id
  s3_key_prefix  = "config"
  
  snapshot_delivery_properties {
    delivery_frequency = "One_Hour"
  }
  
  depends_on = [aws_config_configuration_recorder.main]
}

resource "aws_config_configuration_recorder_status" "main" {
  count = local.enable_config ? 1 : 0
  
  name       = aws_config_configuration_recorder.main[0].name
  is_enabled = true
  
  depends_on = [aws_config_delivery_channel.main]
}

# Lambda function for Prowler security scanning
resource "aws_lambda_function" "prowler_scanner" {
  count = local.enable_prowler ? 1 : 0
  
  function_name    = "${local.project}-${local.environment}-prowler-scanner"
  role             = aws_iam_role.security_scanner.arn
  handler          = "index.handler"
  runtime          = "python3.9"
  timeout          = 900  # 15 minutes
  memory_size      = 1024
  
  filename         = "${path.module}/lambda/prowler-scanner.zip"
  
  environment {
    variables = {
      OUTPUT_BUCKET   = aws_s3_bucket.security_findings.id
      OUTPUT_PREFIX   = "${local.security_findings_prefix}/prowler"
      SNS_TOPIC_ARN   = aws_sns_topic.security_findings.arn
      PROJECT_NAME    = local.project
      ENVIRONMENT     = local.environment
      ALERT_SEVERITIES = jsonencode(local.alert_severities)
    }
  }
  
  tags = {
    Name        = "${local.project}-${local.environment}-prowler-scanner"
    Environment = local.environment
    Service     = "SecurityScanning"
  }
}

# CloudWatch Log Group for Prowler scanner Lambda
resource "aws_cloudwatch_log_group" "prowler_scanner_logs" {
  count = local.enable_prowler ? 1 : 0
  
  name              = "/aws/lambda/${aws_lambda_function.prowler_scanner[0].function_name}"
  retention_in_days = 30
  
  tags = {
    Name        = "${local.project}-${local.environment}-prowler-scanner-logs"
    Environment = local.environment
    Service     = "SecurityScanning"
  }
}

# CloudWatch Event Rule to trigger security scanning
resource "aws_cloudwatch_event_rule" "security_scanning" {
  name                = "${local.project}-${local.environment}-security-scanning"
  description         = "Trigger security scanning"
  schedule_expression = local.security_scanning_schedule
  
  tags = {
    Name        = "${local.project}-${local.environment}-security-scanning"
    Environment = local.environment
    Service     = "SecurityScanning"
  }
}

# CloudWatch Event Target for Prowler scanner
resource "aws_cloudwatch_event_target" "prowler_scanner" {
  count = local.enable_prowler ? 1 : 0
  
  rule      = aws_cloudwatch_event_rule.security_scanning.name
  target_id = "prowler-scanner"
  arn       = aws_lambda_function.prowler_scanner[0].arn
}

# Lambda permission for CloudWatch Events
resource "aws_lambda_permission" "allow_cloudwatch_prowler" {
  count = local.enable_prowler ? 1 : 0
  
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.prowler_scanner[0].function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.security_scanning.arn
}

# Lambda function for security findings aggregation
resource "aws_lambda_function" "security_findings_aggregator" {
  function_name    = "${local.project}-${local.environment}-security-findings-aggregator"
  role             = aws_iam_role.security_scanner.arn
  handler          = "index.handler"
  runtime          = "nodejs16.x"
  timeout          = 300  # 5 minutes
  memory_size      = 512
  
  filename         = "${path.module}/lambda/security-findings-aggregator.zip"
  
  environment {
    variables = {
      OUTPUT_BUCKET   = aws_s3_bucket.security_findings.id
      REPORTS_PREFIX  = local.security_reports_prefix
      SNS_TOPIC_ARN   = aws_sns_topic.security_findings.arn
      PROJECT_NAME    = local.project
      ENVIRONMENT     = local.environment
      ALERT_SEVERITIES = jsonencode(local.alert_severities)
    }
  }
  
  tags = {
    Name        = "${local.project}-${local.environment}-security-findings-aggregator"
    Environment = local.environment
    Service     = "SecurityScanning"
  }
}

# CloudWatch Log Group for findings aggregator Lambda
resource "aws_cloudwatch_log_group" "security_findings_aggregator_logs" {
  name              = "/aws/lambda/${aws_lambda_function.security_findings_aggregator.function_name}"
  retention_in_days = 30
  
  tags = {
    Name        = "${local.project}-${local.environment}-security-findings-aggregator-logs"
    Environment = local.environment
    Service     = "SecurityScanning"
  }
}

# CloudWatch Event Rule to trigger findings aggregation
resource "aws_cloudwatch_event_rule" "security_findings_aggregation" {
  name                = "${local.project}-${local.environment}-security-findings-aggregation"
  description         = "Trigger security findings aggregation"
  schedule_expression = "cron(0 1 * * ? *)"  # Daily at 1:00 AM UTC (after scanning)
  
  tags = {
    Name        = "${local.project}-${local.environment}-security-findings-aggregation"
    Environment = local.environment
    Service     = "SecurityScanning"
  }
}

# CloudWatch Event Target for findings aggregator
resource "aws_cloudwatch_event_target" "security_findings_aggregator" {
  rule      = aws_cloudwatch_event_rule.security_findings_aggregation.name
  target_id = "security-findings-aggregator"
  arn       = aws_lambda_function.security_findings_aggregator.arn
}

# Lambda permission for CloudWatch Events
resource "aws_lambda_permission" "allow_cloudwatch_aggregator" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.security_findings_aggregator.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.security_findings_aggregation.arn
}

# Security findings dashboard
resource "aws_cloudwatch_dashboard" "security_dashboard" {
  dashboard_name = "${local.project}-${local.environment}-security"
  
  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "text"
        x      = 0
        y      = 0
        width  = 24
        height = 1
        properties = {
          markdown = "# ${upper(local.project)} - ${upper(local.environment)} Security Dashboard"
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 1
        width  = 8
        height = 6
        properties = {
          view    = "timeSeries"
          stacked = true
          metrics = [
            ["${local.project}/${local.environment}", "CriticalFindings", { "stat": "Sum" }],
            ["${local.project}/${local.environment}", "HighFindings", { "stat": "Sum" }],
            ["${local.project}/${local.environment}", "MediumFindings", { "stat": "Sum" }],
            ["${local.project}/${local.environment}", "LowFindings", { "stat": "Sum" }]
          ]
          region  = var.primary_region
          title   = "Security Findings by Severity"
          period  = 86400
        }
      },
      {
        type   = "metric"
        x      = 8
        y      = 1
        width  = 8
        height = 6
        properties = {
          view    = "timeSeries"
          stacked = false
          metrics = [
            ["${local.project}/${local.environment}", "TotalFindings", { "stat": "Sum" }]
          ]
          region  = var.primary_region
          title   = "Total Security Findings"
          period  = 86400
        }
      },
      {
        type   = "metric"
        x      = 16
        y      = 1
        width  = 8
        height = 6
        properties = {
          view    = "timeSeries"
          stacked = false
          metrics = [
            ["${local.project}/${local.environment}", "SecurityScore", { "stat": "Average" }]
          ]
          region  = var.primary_region
          title   = "Security Score (0-100)"
          period  = 86400
          yAxis = {
            left = {
              min = 0,
              max = 100
            }
          }
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
          stacked = true
          metrics = [
            ["${local.project}/${local.environment}", "InspectorFindings", { "stat": "Sum" }],
            ["${local.project}/${local.environment}", "GuardDutyFindings", { "stat": "Sum" }],
            ["${local.project}/${local.environment}", "SecurityHubFindings", { "stat": "Sum" }],
            ["${local.project}/${local.environment}", "ProwlerFindings", { "stat": "Sum" }]
          ]
          region  = var.primary_region
          title   = "Findings by Source"
          period  = 86400
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
          stacked = true
          metrics = [
            ["${local.project}/${local.environment}", "NetworkFindings", { "stat": "Sum" }],
            ["${local.project}/${local.environment}", "IAMFindings", { "stat": "Sum" }],
            ["${local.project}/${local.environment}", "DataFindings", { "stat": "Sum" }],
            ["${local.project}/${local.environment}", "ComputeFindings", { "stat": "Sum" }],
            ["${local.project}/${local.environment}", "OtherFindings", { "stat": "Sum" }]
          ]
          region  = var.primary_region
          title   = "Findings by Category"
          period  = 86400
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
            ["${local.project}/${local.environment}", "RemediationRate", { "stat": "Average" }]
          ]
          region  = var.primary_region
          title   = "Remediation Rate (%)"
          period  = 86400
          yAxis = {
            left = {
              min = 0,
              max = 100
            }
          }
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
            ["${local.project}/${local.environment}", "MeanTimeToRemediate", { "stat": "Average" }]
          ]
          region  = var.primary_region
          title   = "Mean Time To Remediate (Hours)"
          period  = 86400
        }
      }
    ]
  })
}

# Using existing aws_caller_identity data source defined in main.tf