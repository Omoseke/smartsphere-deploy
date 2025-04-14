#!/bin/bash
# Deployment Script for SmartSphere

set -e

# Parse command line arguments
COLOR=""
GRADUAL=false
ENVIRONMENT="dev"

while [ "$1" != "" ]; do
    case $1 in
        --color)      shift
                      COLOR=$1
                      ;;
        --gradual)    GRADUAL=true
                      ;;
        --env)        shift
                      ENVIRONMENT=$1
                      ;;
        -h | --help)  echo "Usage: $0 [--color blue|green] [--gradual] [--env dev|staging|prod]"
                      exit 0
                      ;;
        *)            echo "Unknown option: $1"
                      echo "Usage: $0 [--color blue|green] [--gradual] [--env dev|staging|prod]"
                      exit 1
    esac
    shift
done

echo "SmartSphere Deployment Script"
echo "============================"
echo "Environment: $ENVIRONMENT"
if [ -n "$COLOR" ]; then
  echo "Deployment target: $COLOR environment"
fi
if [ "$GRADUAL" = true ]; then
  echo "Deployment method: Gradual traffic shifting"
else
  echo "Deployment method: Immediate cutover"
fi
echo

# Check if AWS CLI is available
if ! command -v aws &> /dev/null; then
    echo "Error: AWS CLI not found"
    exit 1
fi

# Check if Terraform is available
if ! command -v terraform &> /dev/null; then
    echo "Error: Terraform not found"
    exit 1
fi

# Validate environment
if [[ ! "$ENVIRONMENT" =~ ^(dev|staging|prod)$ ]]; then
    echo "Error: Invalid environment. Must be one of: dev, staging, prod"
    exit 1
fi

# Initialize Terraform
echo "Initializing Terraform..."
cd terraform
terraform init -backend-config=environments/${ENVIRONMENT}/backend.tfvars

# Select workspace
echo "Selecting Terraform workspace..."
terraform workspace select ${ENVIRONMENT} || terraform workspace new ${ENVIRONMENT}

# Apply Terraform with color override if specified
if [ -n "$COLOR" ]; then
  echo "Applying Terraform with color override..."
  terraform apply -var-file=environments/${ENVIRONMENT}/terraform.tfvars -var="force_deployment_color=${COLOR}" -auto-approve
else
  echo "Applying Terraform..."
  terraform apply -var-file=environments/${ENVIRONMENT}/terraform.tfvars -auto-approve
fi

# Get deployment ID from Terraform output
DEPLOYMENT_ID=$(terraform output -raw deployment_id 2>/dev/null || echo "")

# If there's a valid deployment ID and gradual traffic shifting is requested
if [ -n "$DEPLOYMENT_ID" ] && [ "$DEPLOYMENT_ID" != "null" ] && [ "$GRADUAL" = true ]; then
  echo "Starting gradual traffic shifting for deployment: $DEPLOYMENT_ID"
  
  # Update CodeDeploy deployment configuration to enable traffic shifting
  aws deploy update-deployment-group \
    --application-name smartsphere-${ENVIRONMENT} \
    --deployment-group-name smartsphere-${ENVIRONMENT}-deployment-group \
    --deployment-config-name CodeDeployDefault.TimeBasedCanary10PercentEvery1Minute
  
  # Create all-at-once deployment configuration as fallback
  aws deploy create-deployment-config \
    --deployment-config-name CodeDeployDefault.AllAtOnce \
    --minimum-healthy-hosts type=FLEET_PERCENT,value=0
    
  # Start the deployment with traffic shifting
  aws deploy create-deployment \
    --application-name smartsphere-${ENVIRONMENT} \
    --deployment-group-name smartsphere-${ENVIRONMENT}-deployment-group \
    --revision revisionType=S3,s3Location="{bucket=smartsphere-${ENVIRONMENT}-deployments,key=revision.zip,bundleType=zip}" \
    --deployment-config-name CodeDeployDefault.TimeBasedCanary10PercentEvery1Minute \
    --description "Gradual deployment initiated via script"
    
  echo "Gradual traffic shifting initiated. Monitoring deployment..."
  
  # Monitor deployment progress
  DEPLOYMENT_STATUS="InProgress"
  while [ "$DEPLOYMENT_STATUS" == "InProgress" ]; do
    echo "Deployment in progress... waiting 10 seconds"
    sleep 10
    DEPLOYMENT_STATUS=$(aws deploy get-deployment --deployment-id $DEPLOYMENT_ID --query "deploymentInfo.status" --output text)
  done
  
  if [ "$DEPLOYMENT_STATUS" == "Succeeded" ]; then
    echo "Deployment completed successfully!"
  else
    echo "Deployment failed with status: $DEPLOYMENT_STATUS"
    exit 1
  fi
fi

echo "Verifying deployment..."
cd ..
./scripts/verify-deployment.sh ${ENVIRONMENT}

echo "Generating deployment dashboard..."
./scripts/generate-dashboard.sh

echo "Deployment completed successfully!"