#!/bin/bash
# Terraform initialization script for SmartSphere

set -e

# Check if environment is provided
if [ -z "$1" ]; then
  echo "Usage: $0 <environment> [region]"
  echo "  environment: dev, staging, or prod"
  echo "  region: AWS region (default: us-east-1)"
  exit 1
fi

# Set variables
ENV=$1
REGION=${2:-us-east-1}
TERRAFORM_STATE_BUCKET="smartsphere-terraform-state"
TERRAFORM_LOCK_TABLE="smartsphere-terraform-locks"

echo "Initializing Terraform for SmartSphere $ENV environment in $REGION region"

# Check AWS CLI is installed
if ! command -v aws &> /dev/null; then
  echo "Error: AWS CLI is not installed. Please install it first."
  exit 1
fi

# Check AWS credentials
echo "Checking AWS credentials..."
if ! aws sts get-caller-identity &> /dev/null; then
  echo "Error: Unable to authenticate with AWS. Please check your credentials."
  exit 1
fi

# Create S3 bucket for Terraform state if it doesn't exist
echo "Checking if Terraform state bucket exists..."
if ! aws s3api head-bucket --bucket $TERRAFORM_STATE_BUCKET 2>/dev/null; then
  echo "Creating Terraform state bucket: $TERRAFORM_STATE_BUCKET"
  aws s3api create-bucket \
    --bucket $TERRAFORM_STATE_BUCKET \
    --region $REGION \
    --create-bucket-configuration LocationConstraint=$REGION
  
  echo "Enabling versioning on state bucket"
  aws s3api put-bucket-versioning \
    --bucket $TERRAFORM_STATE_BUCKET \
    --versioning-configuration Status=Enabled
  
  echo "Enabling encryption on state bucket"
  aws s3api put-bucket-encryption \
    --bucket $TERRAFORM_STATE_BUCKET \
    --server-side-encryption-configuration '{
      "Rules": [
        {
          "ApplyServerSideEncryptionByDefault": {
            "SSEAlgorithm": "AES256"
          }
        }
      ]
    }'
  
  echo "Blocking public access to state bucket"
  aws s3api put-public-access-block \
    --bucket $TERRAFORM_STATE_BUCKET \
    --public-access-block-configuration '{
      "BlockPublicAcls": true,
      "IgnorePublicAcls": true,
      "BlockPublicPolicy": true,
      "RestrictPublicBuckets": true
    }'
else
  echo "Terraform state bucket already exists"
fi

# Create DynamoDB table for state locking if it doesn't exist
echo "Checking if Terraform lock table exists..."
if ! aws dynamodb describe-table --table-name $TERRAFORM_LOCK_TABLE &>/dev/null; then
  echo "Creating Terraform lock table: $TERRAFORM_LOCK_TABLE"
  aws dynamodb create-table \
    --table-name $TERRAFORM_LOCK_TABLE \
    --attribute-definitions AttributeName=LockID,AttributeType=S \
    --key-schema AttributeName=LockID,KeyType=HASH \
    --billing-mode PAY_PER_REQUEST \
    --region $REGION
else
  echo "Terraform lock table already exists"
fi

# Navigate to terraform directory
cd "$(dirname "$0")/../terraform"

# Initialize Terraform with the backend
echo "Initializing Terraform..."
terraform init \
  -backend-config="bucket=${TERRAFORM_STATE_BUCKET}" \
  -backend-config="key=infrastructure/${ENV}/terraform.tfstate" \
  -backend-config="region=${REGION}" \
  -backend-config="dynamodb_table=${TERRAFORM_LOCK_TABLE}"

# Verify environment configuration
echo "Verifying terraform.tfvars file for $ENV environment..."
if [ ! -f "environments/$ENV/terraform.tfvars" ]; then
  echo "Error: terraform.tfvars file for $ENV environment not found"
  exit 1
fi

echo "Terraform initialization complete"
echo "You can now run: terraform plan -var-file=environments/$ENV/terraform.tfvars"