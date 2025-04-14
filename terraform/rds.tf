# RDS Database Configuration for SmartSphere

# Security Group for RDS
resource "aws_security_group" "rds" {
  name        = "${local.project}-${local.environment}-rds-sg"
  description = "Security group for RDS database"
  vpc_id      = module.vpc.vpc_id
  
  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs_tasks.id]
    description     = "Allow PostgreSQL traffic from ECS tasks"
  }
  
  tags = {
    Name = "${local.project}-${local.environment}-rds-sg"
  }
}

# Random password for RDS admin
resource "random_password" "db_password" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

# Store the password in Secrets Manager
resource "aws_secretsmanager_secret" "db_password" {
  name        = "${local.project}/${local.environment}/db-password"
  description = "Database password for ${local.project} ${local.environment} environment"
  
  tags = {
    Name = "${local.project}-${local.environment}-db-password"
  }
}

resource "aws_secretsmanager_secret_version" "db_password" {
  secret_id     = aws_secretsmanager_secret.db_password.id
  secret_string = jsonencode({
    password = random_password.db_password.result
  })
}

# RDS Parameter Group
resource "aws_db_parameter_group" "postgres" {
  name        = "${local.project}-${local.environment}-pg"
  family      = "postgres14"
  description = "Parameter group for ${local.project} ${local.environment} PostgreSQL database"
  
  parameter {
    name  = "log_statement"
    value = local.environment == "prod" ? "none" : "all"
  }
  
  parameter {
    name  = "log_min_duration_statement"
    value = local.environment == "prod" ? "1000" : "500"
  }
  
  parameter {
    name  = "max_connections"
    value = local.environment == "prod" ? "200" : "100"
  }
  
  parameter {
    name  = "shared_buffers"
    value = local.environment == "prod" ? "{DBInstanceClassMemory/32768}" : "{DBInstanceClassMemory/65536}"
  }
  
  parameter {
    name  = "work_mem"
    value = local.environment == "prod" ? "16384" : "8192"
  }
  
  tags = {
    Name = "${local.project}-${local.environment}-pg"
  }
}

# RDS Subnet Group
resource "aws_db_subnet_group" "postgres" {
  name        = "${local.project}-${local.environment}-subnet-group"
  description = "Subnet group for ${local.project} ${local.environment} PostgreSQL database"
  subnet_ids  = module.vpc.database_subnets
  
  tags = {
    Name = "${local.project}-${local.environment}-subnet-group"
  }
}

# RDS Instance
resource "aws_db_instance" "postgres" {
  identifier                  = "${local.project}-${local.environment}"
  engine                      = "postgres"
  engine_version              = "14.5"
  instance_class              = var.db_instance_class
  allocated_storage           = var.db_allocated_storage
  max_allocated_storage       = var.db_allocated_storage * 5
  storage_type                = "gp3"
  storage_encrypted           = true
  username                    = var.db_username
  password                    = random_password.db_password.result
  db_name                     = var.db_name
  port                        = 5432
  publicly_accessible         = false
  vpc_security_group_ids      = [aws_security_group.rds.id]
  db_subnet_group_name        = aws_db_subnet_group.postgres.name
  parameter_group_name        = aws_db_parameter_group.postgres.name
  multi_az                    = local.environment == "prod" ? true : false
  backup_retention_period     = local.environment == "prod" ? 30 : 7
  backup_window               = "03:00-04:00"
  maintenance_window          = "mon:04:00-mon:05:00"
  copy_tags_to_snapshot       = true
  deletion_protection         = var.enable_deletion_protection
  skip_final_snapshot         = local.environment != "prod"
  final_snapshot_identifier   = local.environment == "prod" ? "${local.project}-${local.environment}-final-snapshot" : null
  performance_insights_enabled = local.environment == "prod" ? true : false
  enabled_cloudwatch_logs_exports = ["postgresql", "upgrade"]
  auto_minor_version_upgrade  = true
  
  lifecycle {
    prevent_destroy = false
  }
  
  tags = {
    Name = "${local.project}-${local.environment}-postgres"
  }
}

# RDS Enhanced Monitoring Role
resource "aws_iam_role" "rds_monitoring" {
  name = "${local.project}-${local.environment}-rds-monitoring"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "monitoring.rds.amazonaws.com"
        }
      }
    ]
  })
  
  tags = {
    Name = "${local.project}-${local.environment}-rds-monitoring-role"
  }
}

resource "aws_iam_role_policy_attachment" "rds_monitoring" {
  role       = aws_iam_role.rds_monitoring.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}

# Automatic Snapshots
resource "aws_db_snapshot" "initial" {
  db_instance_identifier = aws_db_instance.postgres.id
  db_snapshot_identifier = "${local.project}-${local.environment}-initial-snapshot"
  
  tags = {
    Name = "${local.project}-${local.environment}-initial-snapshot"
  }
}