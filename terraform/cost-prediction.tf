# AI-Powered Cost Prediction for SmartSphere

locals {
  # Cost prediction configuration
  cost_data_s3_prefix    = "cost-data"
  cost_forecast_s3_prefix = "cost-forecast"
  forecast_horizon       = 90 # 90 days forecast
  training_window        = 366 # 1 year of training data
}

# S3 bucket for cost data and forecasts
resource "aws_s3_bucket" "cost_prediction" {
  bucket = "${local.project}-${local.environment}-cost-prediction"
  
  tags = {
    Name        = "${local.project}-${local.environment}-cost-prediction"
    Environment = local.environment
    Service     = "CostPrediction"
  }
}

# Block public access for cost prediction bucket
resource "aws_s3_bucket_public_access_block" "cost_prediction" {
  bucket = aws_s3_bucket.cost_prediction.id
  
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Enable versioning for cost prediction bucket
resource "aws_s3_bucket_versioning" "cost_prediction" {
  bucket = aws_s3_bucket.cost_prediction.id
  
  versioning_configuration {
    status = "Enabled"
  }
}

# Enable server-side encryption for cost prediction bucket
resource "aws_s3_bucket_server_side_encryption_configuration" "cost_prediction" {
  bucket = aws_s3_bucket.cost_prediction.id
  
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# IAM Role for Cost Explorer data export
resource "aws_iam_role" "cost_explorer_export" {
  name = "${local.project}-${local.environment}-cost-explorer-export-role"
  
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
    Name        = "${local.project}-${local.environment}-cost-explorer-export-role"
    Environment = local.environment
  }
}

# IAM Policy for Cost Explorer access
resource "aws_iam_policy" "cost_explorer_access" {
  name        = "${local.project}-${local.environment}-cost-explorer-access"
  description = "Allow access to Cost Explorer API"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "ce:GetCostAndUsage",
          "ce:GetDimensionValues",
          "ce:GetTags"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
      {
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Effect   = "Allow"
        Resource = [
          aws_s3_bucket.cost_prediction.arn,
          "${aws_s3_bucket.cost_prediction.arn}/*"
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
      }
    ]
  })
}

# Attach policy to role
resource "aws_iam_role_policy_attachment" "cost_explorer_access" {
  role       = aws_iam_role.cost_explorer_export.name
  policy_arn = aws_iam_policy.cost_explorer_access.arn
}

# IAM Role for Forecast
resource "aws_iam_role" "forecast" {
  name = "${local.project}-${local.environment}-forecast-role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "forecast.amazonaws.com"
        }
      }
    ]
  })
  
  tags = {
    Name        = "${local.project}-${local.environment}-forecast-role"
    Environment = local.environment
  }
}

# IAM Policy for Forecast
resource "aws_iam_policy" "forecast_access" {
  name        = "${local.project}-${local.environment}-forecast-access"
  description = "Allow Amazon Forecast to access necessary resources"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket",
          "s3:GetBucketAcl"
        ]
        Effect   = "Allow"
        Resource = [
          aws_s3_bucket.cost_prediction.arn,
          "${aws_s3_bucket.cost_prediction.arn}/*"
        ]
      }
    ]
  })
}

# Attach policy to forecast role
resource "aws_iam_role_policy_attachment" "forecast_access" {
  role       = aws_iam_role.forecast.name
  policy_arn = aws_iam_policy.forecast_access.arn
}

# Lambda function for exporting Cost Explorer data
resource "aws_lambda_function" "cost_data_export" {
  function_name    = "${local.project}-${local.environment}-cost-data-export"
  role             = aws_iam_role.cost_explorer_export.arn
  handler          = "index.handler"
  runtime          = "nodejs16.x"
  timeout          = 300
  memory_size      = 512
  
  filename         = "${path.module}/lambda/cost-export.zip"
  
  environment {
    variables = {
      OUTPUT_BUCKET = aws_s3_bucket.cost_prediction.id
      OUTPUT_PREFIX = local.cost_data_s3_prefix
      PROJECT_TAG   = local.project
      ENVIRONMENT   = local.environment
    }
  }
  
  tags = {
    Name        = "${local.project}-${local.environment}-cost-data-export"
    Environment = local.environment
    Service     = "CostPrediction"
  }
}

# CloudWatch rule to trigger cost data export monthly
resource "aws_cloudwatch_event_rule" "cost_export_monthly" {
  name                = "${local.project}-${local.environment}-cost-export-monthly"
  description         = "Trigger cost data export monthly"
  schedule_expression = "cron(0 1 1 * ? *)" # Run at 01:00 UTC on the 1st day of every month
  
  tags = {
    Name        = "${local.project}-${local.environment}-cost-export-monthly"
    Environment = local.environment
    Service     = "CostPrediction"
  }
}

# CloudWatch event target for cost export
resource "aws_cloudwatch_event_target" "cost_export_target" {
  rule      = aws_cloudwatch_event_rule.cost_export_monthly.name
  target_id = "cost-export-lambda"
  arn       = aws_lambda_function.cost_data_export.arn
}

# Lambda permission for CloudWatch
resource "aws_lambda_permission" "allow_cloudwatch_cost_export" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.cost_data_export.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.cost_export_monthly.arn
}

# CloudWatch Log Group for cost export Lambda
resource "aws_cloudwatch_log_group" "cost_export_logs" {
  name              = "/aws/lambda/${aws_lambda_function.cost_data_export.function_name}"
  retention_in_days = 30
  
  tags = {
    Name        = "${local.project}-${local.environment}-cost-export-logs"
    Environment = local.environment
    Service     = "CostPrediction"
  }
}

# Lambda function for creating AWS Forecast resources
resource "aws_lambda_function" "forecast_creator" {
  function_name    = "${local.project}-${local.environment}-forecast-creator"
  role             = aws_iam_role.forecast.arn
  handler          = "index.handler"
  runtime          = "nodejs16.x"
  timeout          = 300
  memory_size      = 512
  
  filename         = "${path.module}/lambda/forecast-creator.zip"
  
  environment {
    variables = {
      DATA_BUCKET      = aws_s3_bucket.cost_prediction.id
      DATA_PREFIX      = local.cost_data_s3_prefix
      FORECAST_PREFIX  = local.cost_forecast_s3_prefix
      FORECAST_HORIZON = local.forecast_horizon
      TRAINING_WINDOW  = local.training_window
      PROJECT_NAME     = local.project
      ENVIRONMENT      = local.environment
      IAM_ROLE_ARN     = aws_iam_role.forecast.arn
    }
  }
  
  tags = {
    Name        = "${local.project}-${local.environment}-forecast-creator"
    Environment = local.environment
    Service     = "CostPrediction"
  }
}

# Lambda trigger after cost data export is completed
resource "aws_lambda_permission" "allow_s3_forecast_trigger" {
  statement_id  = "AllowExecutionFromS3"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.forecast_creator.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.cost_prediction.arn
}

# S3 bucket notification for forecast creation
resource "aws_s3_bucket_notification" "forecast_trigger" {
  bucket = aws_s3_bucket.cost_prediction.id
  
  lambda_function {
    lambda_function_arn = aws_lambda_function.forecast_creator.arn
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = "${local.cost_data_s3_prefix}/"
    filter_suffix       = ".csv"
  }
  
  depends_on = [aws_lambda_permission.allow_s3_forecast_trigger]
}

# CloudWatch Log Group for forecast creator Lambda
resource "aws_cloudwatch_log_group" "forecast_creator_logs" {
  name              = "/aws/lambda/${aws_lambda_function.forecast_creator.function_name}"
  retention_in_days = 30
  
  tags = {
    Name        = "${local.project}-${local.environment}-forecast-creator-logs"
    Environment = local.environment
    Service     = "CostPrediction"
  }
}

# Lambda function for notification when forecast is complete
resource "aws_lambda_function" "forecast_notification" {
  function_name    = "${local.project}-${local.environment}-forecast-notification"
  role             = aws_iam_role.forecast.arn
  handler          = "index.handler"
  runtime          = "nodejs16.x"
  timeout          = 60
  memory_size      = 128
  
  filename         = "${path.module}/lambda/forecast-notification.zip"
  
  environment {
    variables = {
      SNS_TOPIC_ARN = aws_sns_topic.forecast_notifications.arn
      PROJECT_NAME  = local.project
      ENVIRONMENT   = local.environment
    }
  }
  
  tags = {
    Name        = "${local.project}-${local.environment}-forecast-notification"
    Environment = local.environment
    Service     = "CostPrediction"
  }
}

# Lambda permission for S3 forecast notification
resource "aws_lambda_permission" "allow_s3_notification_trigger" {
  statement_id  = "AllowExecutionFromS3Notification"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.forecast_notification.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.cost_prediction.arn
}

# S3 bucket notification for forecast results
resource "aws_s3_bucket_notification" "forecast_result_trigger" {
  bucket = aws_s3_bucket.cost_prediction.id
  
  lambda_function {
    lambda_function_arn = aws_lambda_function.forecast_notification.arn
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = "${local.cost_forecast_s3_prefix}/"
    filter_suffix       = ".csv"
  }
  
  depends_on = [aws_lambda_permission.allow_s3_notification_trigger]
}

# CloudWatch Log Group for forecast notification Lambda
resource "aws_cloudwatch_log_group" "forecast_notification_logs" {
  name              = "/aws/lambda/${aws_lambda_function.forecast_notification.function_name}"
  retention_in_days = 30
  
  tags = {
    Name        = "${local.project}-${local.environment}-forecast-notification-logs"
    Environment = local.environment
    Service     = "CostPrediction"
  }
}

# SNS Topic for forecast notifications
resource "aws_sns_topic" "forecast_notifications" {
  name = "${local.project}-${local.environment}-forecast-notifications"
  
  tags = {
    Name        = "${local.project}-${local.environment}-forecast-notifications"
    Environment = local.environment
    Service     = "CostPrediction"
  }
}

# CloudWatch Dashboard for Cost Prediction
resource "aws_cloudwatch_dashboard" "cost_prediction" {
  dashboard_name = "${local.project}-${local.environment}-cost-prediction"
  
  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "text"
        x      = 0
        y      = 0
        width  = 24
        height = 1
        properties = {
          markdown = "# ${upper(local.project)} - ${upper(local.environment)} AI-Powered Cost Prediction"
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 1
        width  = 24
        height = 6
        properties = {
          view    = "timeSeries"
          stacked = true
          metrics = [
            ["AWS/Billing", "EstimatedCharges", "ServiceName", "AmazonECS", { "region": "us-east-1" }],
            ["AWS/Billing", "EstimatedCharges", "ServiceName", "AmazonRDS", { "region": "us-east-1" }],
            ["AWS/Billing", "EstimatedCharges", "ServiceName", "AmazonS3", { "region": "us-east-1" }],
            ["AWS/Billing", "EstimatedCharges", "ServiceName", "AmazonCloudFront", { "region": "us-east-1" }],
            ["AWS/Billing", "EstimatedCharges", "ServiceName", "AmazonDynamoDB", { "region": "us-east-1" }],
            ["AWS/Billing", "EstimatedCharges", "ServiceName", "AmazonLambda", { "region": "us-east-1" }],
            ["AWS/Billing", "EstimatedCharges", "ServiceName", "AmazonEC2", { "region": "us-east-1" }]
          ]
          region  = "us-east-1"
          title   = "Current Month Cost by Service"
          period  = 86400
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
            ["AWS/Usage", "ResourceCount", "Type", "Resource", "Resource", "Lambda", "Service", "Lambda", { "region": "us-east-1" }],
            ["AWS/Usage", "ResourceCount", "Type", "Resource", "Resource", "ECS", "Service", "ECS", { "region": "us-east-1" }]
          ]
          region  = "us-east-1"
          title   = "Resource Count"
          period  = 86400
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
            ["${local.project}/${local.environment}", "ForecastAccuracy", { "stat": "Average" }]
          ]
          region  = var.primary_region
          title   = "Forecast Accuracy MAPE (Lower is Better)"
          period  = 86400
          yAxis   = {
            left = {
              min = 0,
              max = 100
            }
          }
        }
      },
      {
        type   = "text"
        x      = 0
        y      = 13
        width  = 24
        height = 1
        properties = {
          markdown = "## Cost Forecast vs Actual (Last 6 Months & Next 3 Months)"
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 14
        width  = 24
        height = 9
        properties = {
          view    = "timeSeries"
          stacked = false
          metrics = [
            ["${local.project}/${local.environment}", "ActualCost", { "stat": "Sum", "label": "Actual Cost" }],
            ["${local.project}/${local.environment}", "ForecastedCostP10", { "stat": "Average", "label": "Forecast (Lower Bound)" }],
            ["${local.project}/${local.environment}", "ForecastedCostP50", { "stat": "Average", "label": "Forecast (Median)" }],
            ["${local.project}/${local.environment}", "ForecastedCostP90", { "stat": "Average", "label": "Forecast (Upper Bound)" }]
          ]
          region  = var.primary_region
          title   = "Cost Forecast with Confidence Intervals"
          period  = 86400
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 23
        width  = 12
        height = 6
        properties = {
          view    = "timeSeries"
          stacked = false
          metrics = [
            ["${local.project}/${local.environment}", "CostAnomaly", { "stat": "Maximum" }],
          ]
          region  = var.primary_region
          title   = "Cost Anomalies Detected"
          period  = 86400
          annotations = {
            horizontal = [
              {
                value = 1,
                label = "Anomaly Threshold",
                color = "#ff0000"
              }
            ]
          }
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 23
        width  = 12
        height = 6
        properties = {
          view    = "timeSeries"
          stacked = false
          metrics = [
            ["${local.project}/${local.environment}", "CostOptimizationScore", { "stat": "Average" }],
          ]
          region  = var.primary_region
          title   = "Cost Optimization Score (0-100)"
          period  = 86400
          yAxis   = {
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