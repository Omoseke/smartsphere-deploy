# Terraform Backend Configuration

terraform {
  backend "s3" {
    bucket         = "smartsphere-terraform-state"
    key            = "infrastructure/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "smartsphere-terraform-locks"
    encrypt        = true
  }
}

# State management resources - Comment out when first creating these resources
# then uncomment after they exist

# S3 bucket for Terraform state
resource "aws_s3_bucket" "terraform_state" {
  bucket = "smartsphere-terraform-state"
  
  lifecycle {
    prevent_destroy = true
  }
  
  tags = {
    Name = "SmartSphere Terraform State"
  }
}

# Enable versioning for state bucket
resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id
  
  versioning_configuration {
    status = "Enabled"
  }
}

# Server-side encryption for state bucket
resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id
  
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Block public access to state bucket
resource "aws_s3_bucket_public_access_block" "terraform_state" {
  bucket                  = aws_s3_bucket.terraform_state.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# DynamoDB table for Terraform state locking
resource "aws_dynamodb_table" "terraform_locks" {
  name         = "smartsphere-terraform-locks"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"
  
  attribute {
    name = "LockID"
    type = "S"
  }
  
  tags = {
    Name = "SmartSphere Terraform Lock Table"
  }
}