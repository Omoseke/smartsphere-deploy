# VPC configuration for SmartSphere

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.0.0"

  name = "${local.project}-${local.environment}"
  cidr = var.vpc_cidr

  azs              = var.availability_zones
  private_subnets  = var.private_subnets
  public_subnets   = var.public_subnets
  database_subnets = var.database_subnets

  # NAT Gateway for outbound internet access from private subnets
  enable_nat_gateway     = true
  single_nat_gateway     = local.environment != "prod" # Use one NAT Gateway for non-prod environments
  one_nat_gateway_per_az = local.environment == "prod" # Use one NAT Gateway per AZ for production
  enable_vpn_gateway     = false

  # Enable DNS support
  enable_dns_hostnames = true
  enable_dns_support   = true

  # Database subnet group
  create_database_subnet_group = true

  # Flow logs for network visibility and security
  enable_flow_log                      = true
  create_flow_log_cloudwatch_log_group = true
  create_flow_log_cloudwatch_iam_role  = true
  flow_log_max_aggregation_interval    = 60

  # VPC Endpoints are defined separately below
  # These options are no longer supported in vpc module v5.0.0

  # Tags
  tags = {
    Name        = "${local.project}-${local.environment}-vpc"
    Environment = local.environment
  }

  # Public subnet tags for ALB
  public_subnet_tags = {
    "kubernetes.io/role/elb" = 1
  }

  # Private subnet tags for EKS if used
  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = 1
  }
}

# VPC Endpoints for AWS services
resource "aws_vpc_endpoint" "s3" {
  vpc_id       = module.vpc.vpc_id
  service_name = "com.amazonaws.${var.aws_region}.s3"
  
  tags = {
    Name = "${local.project}-${local.environment}-s3-endpoint"
  }
}

resource "aws_vpc_endpoint" "ecr_api" {
  vpc_id            = module.vpc.vpc_id
  service_name      = "com.amazonaws.${var.aws_region}.ecr.api"
  vpc_endpoint_type = "Interface"
  
  subnet_ids = module.vpc.private_subnets
  security_group_ids = [
    aws_security_group.vpc_endpoints.id,
  ]
  
  private_dns_enabled = true
  
  tags = {
    Name = "${local.project}-${local.environment}-ecr-api-endpoint"
  }
}

resource "aws_vpc_endpoint" "ecr_dkr" {
  vpc_id            = module.vpc.vpc_id
  service_name      = "com.amazonaws.${var.aws_region}.ecr.dkr"
  vpc_endpoint_type = "Interface"
  
  subnet_ids = module.vpc.private_subnets
  security_group_ids = [
    aws_security_group.vpc_endpoints.id,
  ]
  
  private_dns_enabled = true
  
  tags = {
    Name = "${local.project}-${local.environment}-ecr-dkr-endpoint"
  }
}

resource "aws_vpc_endpoint" "logs" {
  vpc_id            = module.vpc.vpc_id
  service_name      = "com.amazonaws.${var.aws_region}.logs"
  vpc_endpoint_type = "Interface"
  
  subnet_ids = module.vpc.private_subnets
  security_group_ids = [
    aws_security_group.vpc_endpoints.id,
  ]
  
  private_dns_enabled = true
  
  tags = {
    Name = "${local.project}-${local.environment}-logs-endpoint"
  }
}

resource "aws_security_group" "vpc_endpoints" {
  name        = "${local.project}-${local.environment}-vpc-endpoints-sg"
  description = "Security group for VPC endpoints"
  vpc_id      = module.vpc.vpc_id
  
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }
  
  tags = {
    Name = "${local.project}-${local.environment}-vpc-endpoints-sg"
  }
}