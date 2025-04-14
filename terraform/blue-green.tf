# Blue-Green Deployment Configuration for SmartSphere

locals {
  # Determine deployment color based on current state
  current_color = var.force_deployment_color != "" ? var.force_deployment_color : "blue"
  next_color    = local.current_color == "blue" ? "green" : "blue"
  
  # Target group names
  blue_tg_name  = "${local.project}-${local.environment}-blue-tg"
  green_tg_name = "${local.project}-${local.environment}-green-tg"
  
  # Service names
  blue_service_name  = "${local.project}-${local.environment}-blue"
  green_service_name = "${local.project}-${local.environment}-green"
  
  # Container configuration
  container_name = "${local.project}-${local.environment}-container"
}

# SSM Parameter to track current deployment color
resource "aws_ssm_parameter" "current_color" {
  count = var.enable_blue_green_deployment ? 1 : 0
  
  name  = "/${local.project}/${local.environment}/current_color"
  type  = "String"
  value = local.next_color # Will be updated in deployment script
  
  lifecycle {
    ignore_changes = [value]
  }
}

# Use existing target groups from alb.tf
# They are already defined as aws_lb_target_group.blue and aws_lb_target_group.green

# Modified Listener Rule to point to the current color's target group
resource "aws_lb_listener_rule" "blue_green" {
  count = var.enable_blue_green_deployment ? 1 : 0
  
  listener_arn = aws_lb_listener.https.arn
  priority     = 100
  
  action {
    type             = "forward"
    target_group_arn = local.current_color == "blue" ? aws_lb_target_group.blue.arn : aws_lb_target_group.green.arn
  }
  
  condition {
    path_pattern {
      values = ["/*"]
    }
  }
  
  lifecycle {
    ignore_changes = [action]
  }
}

# Blue ECS Service
resource "aws_ecs_service" "blue" {
  count = var.enable_blue_green_deployment ? 1 : 0
  
  name            = local.blue_service_name
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.app.arn
  launch_type     = "FARGATE"
  
  # Only run tasks when current color is blue
  desired_count = local.current_color == "blue" ? var.desired_capacity : 0
  
  network_configuration {
    security_groups  = [aws_security_group.ecs_tasks.id]
    subnets          = module.vpc.private_subnets
    assign_public_ip = false
  }
  
  load_balancer {
    target_group_arn = aws_lb_target_group.blue.arn
    container_name   = local.container_name
    container_port   = var.container_port
  }
  
  deployment_controller {
    type = "ECS"
  }
  
  lifecycle {
    ignore_changes = [desired_count, task_definition]
  }
  
  tags = {
    Name        = local.blue_service_name
    Environment = local.environment
    Color       = "blue"
  }
}

# Green ECS Service
resource "aws_ecs_service" "green" {
  count = var.enable_blue_green_deployment ? 1 : 0
  
  name            = local.green_service_name
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.app.arn
  launch_type     = "FARGATE"
  
  # Only run tasks when current color is green
  desired_count = local.current_color == "green" ? var.desired_capacity : 0
  
  network_configuration {
    security_groups  = [aws_security_group.ecs_tasks.id]
    subnets          = module.vpc.private_subnets
    assign_public_ip = false
  }
  
  load_balancer {
    target_group_arn = aws_lb_target_group.green.arn
    container_name   = local.container_name
    container_port   = var.container_port
  }
  
  deployment_controller {
    type = "ECS"
  }
  
  lifecycle {
    ignore_changes = [desired_count, task_definition]
  }
  
  tags = {
    Name        = local.green_service_name
    Environment = local.environment
    Color       = "green"
  }
}

# CloudWatch Events Rule for Deployment Status
resource "aws_cloudwatch_event_rule" "deployment_event" {
  count = var.enable_blue_green_deployment ? 1 : 0
  
  name        = "${local.project}-${local.environment}-deployment-events"
  description = "Capture ECS deployment events"
  
  event_pattern = jsonencode({
    source      = ["aws.ecs"],
    detail-type = ["ECS Deployment State Change"],
    detail = {
      eventName = ["SERVICE_DEPLOYMENT_COMPLETED", "SERVICE_DEPLOYMENT_FAILED"]
      clusterArn = [aws_ecs_cluster.main.arn]
    }
  })
}

# SNS Topic for deployment notifications
resource "aws_sns_topic" "deployment_notifications" {
  count = var.enable_blue_green_deployment ? 1 : 0
  
  name = "${local.project}-${local.environment}-deployment-notifications"
  
  tags = {
    Name        = "${local.project}-${local.environment}-deployment-notifications"
    Environment = local.environment
  }
}

# CloudWatch Event Target for the SNS topic
resource "aws_cloudwatch_event_target" "deployment_notification" {
  count = var.enable_blue_green_deployment ? 1 : 0
  
  rule      = aws_cloudwatch_event_rule.deployment_event[0].name
  target_id = "SendToSNS"
  arn       = aws_sns_topic.deployment_notifications[0].arn
  
  input_transformer {
    input_paths = {
      cluster    = "$.detail.clusterArn",
      service    = "$.detail.serviceArn",
      status     = "$.detail.eventName",
      deploymentId = "$.detail.deploymentId",
      reason     = "$.detail.reason"
    }
    
    input_template = <<EOF
{
  "cluster": <cluster>,
  "service": <service>,
  "status": <status>,
  "deploymentId": <deploymentId>,
  "reason": <reason>,
  "environment": "${local.environment}",
  "project": "${local.project}",
  "timestamp": "${timestamp()}"
}
EOF
  }
}

# Blue-Green traffic shifting Lambda function
resource "aws_lambda_function" "traffic_shifter" {
  count = var.enable_blue_green_deployment ? 1 : 0
  
  function_name    = "${local.project}-${local.environment}-traffic-shifter"
  role             = aws_iam_role.traffic_shifter_role[0].arn
  handler          = "index.handler"
  runtime          = "nodejs16.x"
  timeout          = 60
  
  environment {
    variables = {
      BLUE_TARGET_GROUP_ARN  = aws_lb_target_group.blue.arn
      GREEN_TARGET_GROUP_ARN = aws_lb_target_group.green.arn
      LISTENER_ARN           = aws_lb_listener.https.arn
      SSM_PARAMETER_NAME     = aws_ssm_parameter.current_color[0].name
      CLUSTER_NAME           = aws_ecs_cluster.main.name
      BLUE_SERVICE_NAME      = local.blue_service_name
      GREEN_SERVICE_NAME     = local.green_service_name
      ENVIRONMENT            = local.environment
    }
  }
  
  # Inline code for Lambda function to shift traffic
  filename = "${path.module}/lambda/traffic-shifter.zip"
  
  tags = {
    Name        = "${local.project}-${local.environment}-traffic-shifter"
    Environment = local.environment
  }
  
  depends_on = [
    aws_iam_role_policy_attachment.traffic_shifter_policy,
  ]
}

# IAM Role for the Traffic Shifter Lambda
resource "aws_iam_role" "traffic_shifter_role" {
  count = var.enable_blue_green_deployment ? 1 : 0
  
  name = "${local.project}-${local.environment}-traffic-shifter-role"
  
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
    Name        = "${local.project}-${local.environment}-traffic-shifter-role"
    Environment = local.environment
  }
}

# IAM Policy for the Traffic Shifter Lambda
resource "aws_iam_policy" "traffic_shifter_policy" {
  count = var.enable_blue_green_deployment ? 1 : 0
  
  name        = "${local.project}-${local.environment}-traffic-shifter-policy"
  description = "Policy for Blue-Green deployment traffic shifter"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "elasticloadbalancing:ModifyListener",
          "elasticloadbalancing:ModifyRule",
          "elasticloadbalancing:DescribeListeners",
          "elasticloadbalancing:DescribeRules",
          "elasticloadbalancing:DescribeTargetGroups"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
      {
        Action = [
          "ecs:UpdateService",
          "ecs:DescribeServices"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
      {
        Action = [
          "ssm:GetParameter",
          "ssm:PutParameter"
        ]
        Effect   = "Allow"
        Resource = aws_ssm_parameter.current_color[0].arn
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

# Attach the policy to the role
resource "aws_iam_role_policy_attachment" "traffic_shifter_policy" {
  count = var.enable_blue_green_deployment ? 1 : 0
  
  role       = aws_iam_role.traffic_shifter_role[0].name
  policy_arn = aws_iam_policy.traffic_shifter_policy[0].arn
}

# CloudWatch Log Group for Lambda
resource "aws_cloudwatch_log_group" "traffic_shifter_logs" {
  count = var.enable_blue_green_deployment ? 1 : 0
  
  name              = "/aws/lambda/${local.project}-${local.environment}-traffic-shifter"
  retention_in_days = 14
  
  tags = {
    Name        = "${local.project}-${local.environment}-traffic-shifter-logs"
    Environment = local.environment
  }
}