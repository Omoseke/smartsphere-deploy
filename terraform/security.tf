# Security Configuration for SmartSphere

# Application Security Policies
resource "aws_iam_policy" "app_policy" {
  name        = "${local.project}-${local.environment}-app-policy"
  description = "Policy for ${local.project} application in ${local.environment} environment"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:ListBucket",
          "s3:DeleteObject"
        ]
        Resource = [
          aws_s3_bucket.app_data.arn,
          "${aws_s3_bucket.app_data.arn}/*"
        ]
      },
      {
        Effect   = "Allow"
        Action   = [
          "secretsmanager:GetSecretValue"
        ]
        Resource = [
          aws_secretsmanager_secret.db_password.arn
        ]
      },
      {
        Effect   = "Allow"
        Action   = [
          "cloudwatch:PutMetricData"
        ]
        Resource = "*"
      },
      {
        Effect   = "Allow"
        Action   = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogStreams"
        ]
        Resource = [
          "arn:aws:logs:${var.aws_region}:*:log-group:/aws/ecs/${local.project}-${local.environment}*"
        ]
      }
    ]
  })
  
  tags = {
    Name = "${local.project}-${local.environment}-app-policy"
  }
}

# IAM Role for CI/CD Pipeline
resource "aws_iam_role" "cicd" {
  name = "${local.project}-${local.environment}-cicd-role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "codebuild.amazonaws.com"
        }
      },
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "codepipeline.amazonaws.com"
        }
      },
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "codedeploy.amazonaws.com"
        }
      }
    ]
  })
  
  tags = {
    Name = "${local.project}-${local.environment}-cicd-role"
  }
}

# IAM Policy for CI/CD Pipeline
resource "aws_iam_policy" "cicd" {
  name        = "${local.project}-${local.environment}-cicd-policy"
  description = "Policy for CI/CD operations in ${local.environment} environment"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload",
          "ecr:PutImage"
        ]
        Resource = "*"
      },
      {
        Effect   = "Allow"
        Action   = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:GetObjectVersion",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.frontend.arn,
          "${aws_s3_bucket.frontend.arn}/*"
        ]
      },
      {
        Effect   = "Allow"
        Action   = [
          "cloudformation:*"
        ]
        Resource = "*"
      },
      {
        Effect   = "Allow"
        Action   = [
          "ecs:DescribeServices",
          "ecs:DescribeTaskDefinition",
          "ecs:RegisterTaskDefinition",
          "ecs:UpdateService"
        ]
        Resource = "*"
      },
      {
        Effect   = "Allow"
        Action   = [
          "iam:PassRole"
        ]
        Resource = [
          aws_iam_role.ecs_task_execution.arn,
          aws_iam_role.ecs_task.arn
        ]
      },
      {
        Effect   = "Allow"
        Action   = [
          "cloudfront:CreateInvalidation"
        ]
        Resource = aws_cloudfront_distribution.frontend.arn
      }
    ]
  })
  
  tags = {
    Name = "${local.project}-${local.environment}-cicd-policy"
  }
}

# Attach policy to CI/CD role
resource "aws_iam_role_policy_attachment" "cicd" {
  role       = aws_iam_role.cicd.name
  policy_arn = aws_iam_policy.cicd.arn
}

# KMS Key for Encryption
resource "aws_kms_key" "app" {
  description             = "KMS key for ${local.project} ${local.environment} environment"
  deletion_window_in_days = 30
  enable_key_rotation     = true
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "Enable IAM User Permissions"
        Effect    = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action    = "kms:*"
        Resource  = "*"
      },
      {
        Sid       = "Allow ECS Task Execution Role to use the key"
        Effect    = "Allow"
        Principal = {
          AWS = aws_iam_role.ecs_task_execution.arn
        }
        Action    = [
          "kms:Decrypt",
          "kms:DescribeKey",
          "kms:Encrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*"
        ]
        Resource  = "*"
      }
    ]
  })
  
  tags = {
    Name = "${local.project}-${local.environment}-kms-key"
  }
}

resource "aws_kms_alias" "app" {
  name          = "alias/${local.project}-${local.environment}"
  target_key_id = aws_kms_key.app.key_id
}

# Security Notifications
resource "aws_sns_topic" "security" {
  name = "${local.project}-${local.environment}-security-notifications"
  
  tags = {
    Name = "${local.project}-${local.environment}-security-notifications"
  }
}

# AWS Config Rule for Encryption
resource "aws_config_config_rule" "encrypted_volumes" {
  name        = "${local.project}-${local.environment}-encrypted-volumes"
  description = "Checks whether EBS volumes that are in an attached state are encrypted"
  
  source {
    owner             = "AWS"
    source_identifier = "ENCRYPTED_VOLUMES"
  }
  
  tags = {
    Name = "${local.project}-${local.environment}-encrypted-volumes"
  }
}

# AWS Config Rule for Public Access
resource "aws_config_config_rule" "restricted_ssh" {
  name        = "${local.project}-${local.environment}-restricted-ssh"
  description = "Checks whether security groups that are in use disallow unrestricted incoming SSH traffic"
  
  source {
    owner             = "AWS"
    source_identifier = "RESTRICTED_INCOMING_TRAFFIC"
  }
  
  input_parameters = jsonencode({
    blockedPort1 = "22"
  })
  
  tags = {
    Name = "${local.project}-${local.environment}-restricted-ssh"
  }
}

# AWS Shield Advanced Protection
resource "aws_shield_protection" "cloudfront" {
  count = local.environment == "prod" ? 1 : 0
  
  name         = "${local.project}-${local.environment}-cf-protection"
  resource_arn = aws_cloudfront_distribution.frontend.arn
}

resource "aws_shield_protection" "alb" {
  count = local.environment == "prod" ? 1 : 0
  
  name         = "${local.project}-${local.environment}-alb-protection"
  resource_arn = aws_lb.main.arn
}

# Secret Rotation Function
resource "aws_iam_role" "secrets_rotation" {
  name = "${local.project}-${local.environment}-rotation-role"
  
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
    Name = "${local.project}-${local.environment}-rotation-role"
  }
}

resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.secrets_rotation.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy" "secrets_rotation" {
  name = "${local.project}-${local.environment}-rotation-policy"
  role = aws_iam_role.secrets_rotation.id
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:DescribeSecret",
          "secretsmanager:GetSecretValue",
          "secretsmanager:PutSecretValue",
          "secretsmanager:UpdateSecretVersionStage"
        ]
        Resource = aws_secretsmanager_secret.db_password.arn
      },
      {
        Effect = "Allow"
        Action = [
          "rds:ModifyDBInstance"
        ]
        Resource = aws_db_instance.postgres.arn
      }
    ]
  })
}