# AWS Amplify configuration for SmartSphere frontend deployment

# AWS Amplify App
resource "aws_amplify_app" "smartsphere" {
  name         = "smartsphere"
  repository   = var.github_repository
  access_token = var.github_access_token
  
  # Enable auto branch creation
  enable_auto_branch_creation = true
  
  # The default patterns to match branches that should automatically be built
  auto_branch_creation_patterns = [
    "main",
    "develop",
    "feature/*",
    "release/*"
  ]
  
  # The default build spec for auto created branches
  auto_branch_creation_config {
    enable_auto_build     = true
    enable_pull_request_preview = true
    enable_performance_mode = var.enable_performance_mode
  }
  
  # Build specification
  build_spec = <<-EOT
    version: 1
    frontend:
      phases:
        preBuild:
          commands:
            - npm ci
        build:
          commands:
            - echo "Running tests..."
            - npm test
            - echo "Building production bundle..."
            - npm run build
      artifacts:
        baseDirectory: build
        files:
          - '**/*'
      cache:
        paths:
          - node_modules/**/*
    test:
      phases:
        test:
          commands:
            - npm run test:ci
      artifacts:
        baseDirectory: coverage
        files:
          - '**/*'
    EOT
  
  # Environment variables
  environment_variables = {
    REACT_APP_API_ENDPOINT = var.api_endpoint_url
    REACT_APP_STAGE        = var.environment
    REACT_APP_VERSION      = var.app_version
    NODE_OPTIONS           = "--max-old-space-size=4096"
  }
  
  # Custom rules
  custom_rule {
    source = "/<*>"
    status = "404"
    target = "/index.html"
  }
  
  custom_rule {
    source = "</^[^.]+$|\\.(?!(css|gif|ico|jpg|js|png|txt|svg|woff|woff2|ttf|map|json)$)([^.]+$)/>"
    status = "200"
    target = "/index.html"
  }
  
  # Enable basic auth during development
  enable_basic_auth = var.environment != "production"
  basic_auth_credentials = var.environment != "production" ? "${var.basic_auth_username}:${var.basic_auth_password}" : null
  
  # Tags
  tags = merge(
    var.tags,
    {
      Name = "smartsphere-amplify"
      Environment = var.environment
    }
  )
}

# Define branches to deploy
resource "aws_amplify_branch" "main" {
  app_id      = aws_amplify_app.smartsphere.id
  branch_name = "main"
  
  framework = "React"
  stage     = "PRODUCTION"
  
  enable_auto_build = true
  
  environment_variables = {
    REACT_APP_API_ENDPOINT = var.api_endpoint_url
    REACT_APP_STAGE        = "production"
    NODE_ENV               = "production"
  }
  
  tags = merge(
    var.tags,
    {
      Name = "smartsphere-main"
      Environment = "production"
    }
  )
}

resource "aws_amplify_branch" "develop" {
  app_id      = aws_amplify_app.smartsphere.id
  branch_name = "develop"
  
  framework = "React"
  stage     = "DEVELOPMENT"
  
  enable_auto_build = true
  
  environment_variables = {
    REACT_APP_API_ENDPOINT = var.api_endpoint_url_dev
    REACT_APP_STAGE        = "development"
    NODE_ENV               = "development"
  }
  
  tags = merge(
    var.tags,
    {
      Name = "smartsphere-develop"
      Environment = "development"
    }
  )
}

# Domain association
resource "aws_amplify_domain_association" "smartsphere" {
  count       = var.enable_custom_domain ? 1 : 0
  app_id      = aws_amplify_app.smartsphere.id
  domain_name = var.custom_domain
  
  # Production branch
  sub_domain {
    branch_name = aws_amplify_branch.main.branch_name
    prefix      = ""
  }
  
  # Development branch
  sub_domain {
    branch_name = aws_amplify_branch.develop.branch_name
    prefix      = "dev"
  }
  
  # Staging branch (if created)
  dynamic "sub_domain" {
    for_each = var.create_staging_branch ? [1] : []
    content {
      branch_name = aws_amplify_branch.staging[0].branch_name
      prefix      = "staging"
    }
  }
}

# Optional staging branch
resource "aws_amplify_branch" "staging" {
  count       = var.create_staging_branch ? 1 : 0
  app_id      = aws_amplify_app.smartsphere.id
  branch_name = "staging"
  
  framework = "React"
  stage     = "PRODUCTION"
  
  enable_auto_build = true
  
  environment_variables = {
    REACT_APP_API_ENDPOINT = var.api_endpoint_url_staging
    REACT_APP_STAGE        = "staging"
    NODE_ENV               = "production"
  }
  
  tags = merge(
    var.tags,
    {
      Name = "smartsphere-staging"
      Environment = "staging"
    }
  )
}

# Webhook configuration for CI/CD
resource "aws_amplify_webhook" "smartsphere" {
  app_id      = aws_amplify_app.smartsphere.id
  branch_name = aws_amplify_branch.main.branch_name
  description = "Main branch webhook for CI/CD integration"
}

# Amplify backend environment for optional AWS Amplify backend services
resource "aws_amplify_backend_environment" "main" {
  count = var.enable_amplify_backend ? 1 : 0
  
  app_id           = aws_amplify_app.smartsphere.id
  environment_name = "main"
  
  deployment_artifacts = var.amplify_backend_deployment_artifacts
  stack_name           = "smartsphere-amplify-backend"
}

# Add variables for Amplify configuration to variables.tf
# These variables need to be defined in the variables.tf file for this to work
# Example:
# 
# variable "github_repository" {
#   description = "GitHub repository URL for the SmartSphere frontend"
#   type        = string
# }
# 
# variable "github_access_token" {
#   description = "GitHub personal access token for Amplify to access the repository"
#   type        = string
#   sensitive   = true
# }
# 
# variable "api_endpoint_url" {
#   description = "API endpoint URL for the production environment"
#   type        = string
# }
# 
# variable "api_endpoint_url_dev" {
#   description = "API endpoint URL for the development environment"
#   type        = string
# }
# 
# variable "api_endpoint_url_staging" {
#   description = "API endpoint URL for the staging environment"
#   type        = string
#   default     = ""
# }
# 
# variable "app_version" {
#   description = "Application version"
#   type        = string
#   default     = "1.0.0"
# }
# 
# variable "enable_custom_domain" {
#   description = "Whether to enable custom domain for Amplify"
#   type        = bool
#   default     = false
# }
# 
# variable "custom_domain" {
#   description = "Custom domain for Amplify"
#   type        = string
#   default     = ""
# }
# 
# variable "create_staging_branch" {
#   description = "Whether to create a staging branch"
#   type        = bool
#   default     = true
# }
# 
# variable "enable_performance_mode" {
#   description = "Whether to enable performance mode for Amplify builds"
#   type        = bool
#   default     = false
# }
# 
# variable "basic_auth_username" {
#   description = "Username for basic auth (non-production environments)"
#   type        = string
#   default     = "smartsphere"
# }
# 
# variable "basic_auth_password" {
#   description = "Password for basic auth (non-production environments)"
#   type        = string
#   sensitive   = true
#   default     = ""
# }
# 
# variable "enable_amplify_backend" {
#   description = "Whether to enable Amplify backend environment"
#   type        = bool
#   default     = false
# }
# 
# variable "amplify_backend_deployment_artifacts" {
#   description = "S3 bucket path for Amplify backend deployment artifacts"
#   type        = string
#   default     = ""
# }