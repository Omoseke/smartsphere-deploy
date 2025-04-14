#!/bin/bash
# Rollback Deployment Script for SmartSphere

set -e

# Parse command line arguments
ENVIRONMENT="dev"
VERSION=""
CONFIRM=false

while [ "$1" != "" ]; do
    case $1 in
        --environment | -e)  shift
                         ENVIRONMENT=$1
                         ;;
        --version | -v)     shift
                         VERSION=$1
                         ;;
        --yes | -y)      CONFIRM=true
                         ;;
        -h | --help)     echo "Usage: $0 [--environment dev|staging|prod] [--version VERSION] [--yes]"
                         echo "  --environment, -e: Environment to rollback (default: dev)"
                         echo "  --version, -v: Specific version to rollback to (optional)"
                         echo "  --yes, -y: Skip confirmation prompt"
                         exit 0
                         ;;
        *)               echo "Unknown option: $1"
                         echo "Usage: $0 [--environment dev|staging|prod] [--version VERSION] [--yes]"
                         exit 1
    esac
    shift
done

echo "SmartSphere Deployment Rollback Script"
echo "===================================="
echo "Environment: $ENVIRONMENT"
if [ -n "$VERSION" ]; then
  echo "Target version: $VERSION"
else
  echo "Target version: Previous deployment"
fi
echo

# Check if AWS CLI is available
if ! command -v aws &> /dev/null; then
    echo "Error: AWS CLI not found"
    exit 1
fi

# Validate environment
if [[ ! "$ENVIRONMENT" =~ ^(dev|staging|prod)$ ]]; then
    echo "Error: Invalid environment. Must be one of: dev, staging, prod"
    exit 1
fi

# Get current and previous deployment information
echo "Retrieving deployment information..."

# Get ECS service and cluster names
ECS_CLUSTER="smartsphere-${ENVIRONMENT}-cluster"
ECS_SERVICE="smartsphere-${ENVIRONMENT}-service"

# Get CodeDeploy application and deployment group
CODEDEPLOY_APP="smartsphere-${ENVIRONMENT}"
CODEDEPLOY_GROUP="smartsphere-${ENVIRONMENT}-deployment-group"

# Get current task definition
CURRENT_TASK_DEF=$(aws ecs describe-services --cluster $ECS_CLUSTER --services $ECS_SERVICE --query "services[0].taskDefinition" --output text)
echo "Current task definition: $CURRENT_TASK_DEF"

# Get previous task definition (or specific version)
if [ -n "$VERSION" ]; then
  # Look for specific version in task definition family
  TASK_DEF_FAMILY=$(echo $CURRENT_TASK_DEF | cut -d':' -f1)
  PREVIOUS_TASK_DEF="${TASK_DEF_FAMILY}:${VERSION}"
  
  # Verify this task definition exists
  aws ecs describe-task-definition --task-definition $PREVIOUS_TASK_DEF > /dev/null 2>&1
  if [ $? -ne 0 ]; then
    echo "Error: Task definition version ${VERSION} not found"
    exit 1
  fi
else
  # Get the task definition family
  TASK_DEF_FAMILY=$(echo $CURRENT_TASK_DEF | cut -d':' -f1)
  
  # List recent task definitions
  TASK_DEFS=$(aws ecs list-task-definitions --family-prefix $TASK_DEF_FAMILY --status ACTIVE --sort DESC --max-items 10 --query 'taskDefinitionArns' --output text)
  
  # Find previous task definition (not the current one)
  for td in $TASK_DEFS; do
    if [ "$td" != "$CURRENT_TASK_DEF" ]; then
      PREVIOUS_TASK_DEF=$td
      break
    fi
  done
  
  if [ -z "$PREVIOUS_TASK_DEF" ]; then
    echo "Error: No previous task definition found to roll back to"
    exit 1
  fi
fi

echo "Target task definition for rollback: $PREVIOUS_TASK_DEF"

# Get information about the task definition to show what we're rolling back to
TASK_DEF_INFO=$(aws ecs describe-task-definition --task-definition $PREVIOUS_TASK_DEF --query "taskDefinition.containerDefinitions[0].image" --output text)

echo "Target container image: $TASK_DEF_INFO"

# Check if deployment is in progress
DEPLOYMENT_STATUS=$(aws ecs describe-services --cluster $ECS_CLUSTER --services $ECS_SERVICE --query "services[0].deployments" --output json)
DEPLOYMENT_COUNT=$(echo $DEPLOYMENT_STATUS | jq 'length')

if [ $DEPLOYMENT_COUNT -gt 1 ]; then
  echo "Warning: There is already a deployment in progress."
  
  if [ "$CONFIRM" != true ]; then
    echo -n "Do you want to force rollback anyway? (y/n): "
    read -r answer
    if [[ ! "$answer" =~ ^[Yy]$ ]]; then
      echo "Rollback cancelled."
      exit 0
    fi
  fi
fi

# Confirmation unless --yes was provided
if [ "$CONFIRM" != true ]; then
  echo "You are about to roll back the deployment in the $ENVIRONMENT environment."
  echo "This will revert to task definition: $PREVIOUS_TASK_DEF"
  echo -n "Do you want to continue? (y/n): "
  read -r answer
  if [[ ! "$answer" =~ ^[Yy]$ ]]; then
    echo "Rollback cancelled."
    exit 0
  fi
fi

echo "Starting rollback process..."

# Check if we should use CodeDeploy for the rollback
CODEDEPLOY_EXISTS=$(aws deploy get-application --application-name $CODEDEPLOY_APP > /dev/null 2>&1 && echo "true" || echo "false")

if [ "$CODEDEPLOY_EXISTS" = "true" ]; then
  echo "Using CodeDeploy for rollback..."
  
  # Create a new deployment using the previous revision
  DEPLOYMENT_ID=$(aws deploy create-deployment \
    --application-name $CODEDEPLOY_APP \
    --deployment-group-name $CODEDEPLOY_GROUP \
    --revision revisionType=AppSpecContent,appSpecContent="{content='version: 0.0\nResources:\n  - TargetService:\n      Type: AWS::ECS::Service\n      Properties:\n        TaskDefinition: ${PREVIOUS_TASK_DEF}\n        LoadBalancerInfo:\n          ContainerName: smartsphere-app\n          ContainerPort: 80'}" \
    --description "Rollback to previous version" \
    --query 'deploymentId' \
    --output text)
  
  echo "CodeDeploy rollback deployment initiated: $DEPLOYMENT_ID"
  
  # Monitor deployment progress
  echo "Monitoring rollback deployment..."
  STATUS="InProgress"
  
  while [ "$STATUS" == "InProgress" ] || [ "$STATUS" == "Created" ] || [ "$STATUS" == "Queued" ] || [ "$STATUS" == "Ready" ]; do
    echo "Rollback in progress... waiting 10 seconds"
    sleep 10
    STATUS=$(aws deploy get-deployment --deployment-id $DEPLOYMENT_ID --query 'deploymentInfo.status' --output text)
  done
  
  if [ "$STATUS" == "Succeeded" ]; then
    echo "Rollback deployment completed successfully!"
  else
    echo "Rollback deployment failed with status: $STATUS"
    exit 1
  fi
else
  echo "Using ECS update-service for rollback..."
  
  # Update the service to use the previous task definition
  aws ecs update-service \
    --cluster $ECS_CLUSTER \
    --service $ECS_SERVICE \
    --task-definition $PREVIOUS_TASK_DEF \
    --force-new-deployment
  
  echo "ECS service update initiated for rollback"
  
  # Monitor service stability
  echo "Monitoring service stability..."
  aws ecs wait services-stable \
    --cluster $ECS_CLUSTER \
    --services $ECS_SERVICE
  
  echo "Service is now stable after rollback"
fi

echo "Verifying rollback deployment..."
../scripts/verify-deployment.sh $ENVIRONMENT

echo "Generating updated dashboard..."
../scripts/generate-dashboard.sh

echo "Rollback completed successfully!"
echo "The $ENVIRONMENT environment has been reverted to: $PREVIOUS_TASK_DEF"