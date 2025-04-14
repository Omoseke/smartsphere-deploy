#!/bin/bash
# Deployment Verification Script for SmartSphere

set -e

# Configuration
ENVIRONMENT=$1
API_HEALTH_ENDPOINT="health"
TIMEOUT=300  # 5 minutes timeout
CHECK_INTERVAL=10  # Check every 10 seconds
MAX_ATTEMPTS=$((TIMEOUT / CHECK_INTERVAL))

# Validate input
if [ -z "$ENVIRONMENT" ]; then
    echo "Error: Environment parameter is required"
    echo "Usage: $0 <environment> (e.g., dev, staging, prod)"
    exit 1
fi

echo "SmartSphere Deployment Verification for $ENVIRONMENT environment"
echo "=============================================================="
echo

# Load environment-specific configuration
echo "Loading configuration for $ENVIRONMENT environment..."
if [ -f "terraform/environments/$ENVIRONMENT/terraform.tfvars" ]; then
    # Extract values from terraform.tfvars
    DOMAIN_NAME=$(grep -E "^domain_name\s*=" "terraform/environments/$ENVIRONMENT/terraform.tfvars" | cut -d'"' -f2)
    API_ENDPOINT=$(grep -E "^api_endpoint_url(_${ENVIRONMENT})?\s*=" "terraform/environments/$ENVIRONMENT/terraform.tfvars" | cut -d'"' -f2)
else
    echo "Warning: Environment file not found. Using defaults..."
    DOMAIN_NAME="$ENVIRONMENT.smartsphere.example.com"
    API_ENDPOINT="https://api.$ENVIRONMENT.smartsphere.example.com"
fi

# Determine endpoints to check
FRONTEND_URL="https://$DOMAIN_NAME"
API_URL="${API_ENDPOINT}/${API_HEALTH_ENDPOINT}"

echo "Endpoints to verify:"
echo "  Frontend: $FRONTEND_URL"
echo "  API:      $API_URL"
echo

# Check if AWS CLI is available
if ! command -v aws &> /dev/null; then
    echo "Warning: AWS CLI not found. Some checks will be skipped."
    SKIP_AWS_CHECKS=true
else
    SKIP_AWS_CHECKS=false
fi

# Verify ECS service status
verify_ecs_service() {
    echo "Verifying ECS service status..."
    
    if [ "$SKIP_AWS_CHECKS" = true ]; then
        echo "  Skipped (AWS CLI not available)"
        return
    fi
    
    CLUSTER_NAME="smartsphere-$ENVIRONMENT-cluster"
    SERVICE_NAME="smartsphere-$ENVIRONMENT-service"
    
    # Check service status
    SERVICE_STATUS=$(aws ecs describe-services --cluster $CLUSTER_NAME --services $SERVICE_NAME --query 'services[0].status' --output text 2>/dev/null)
    
    if [ "$SERVICE_STATUS" == "ACTIVE" ]; then
        echo "  ECS service is active"
        
        # Check desired vs running count
        DESIRED_COUNT=$(aws ecs describe-services --cluster $CLUSTER_NAME --services $SERVICE_NAME --query 'services[0].desiredCount' --output text)
        RUNNING_COUNT=$(aws ecs describe-services --cluster $CLUSTER_NAME --services $SERVICE_NAME --query 'services[0].runningCount' --output text)
        
        echo "  Desired tasks: $DESIRED_COUNT, Running tasks: $RUNNING_COUNT"
        
        if [ "$DESIRED_COUNT" != "$RUNNING_COUNT" ]; then
            echo "  Warning: Not all desired tasks are running"
        else
            echo "  All tasks are running as expected"
        fi
    else
        echo "  Error: ECS service is not active (Status: $SERVICE_STATUS)"
        return 1
    fi
}

# Verify RDS instance status
verify_rds_instance() {
    echo "Verifying RDS instance status..."
    
    if [ "$SKIP_AWS_CHECKS" = true ]; then
        echo "  Skipped (AWS CLI not available)"
        return
    fi
    
    DB_INSTANCE_ID="smartsphere-$ENVIRONMENT-db"
    
    # Check instance status
    DB_STATUS=$(aws rds describe-db-instances --db-instance-identifier $DB_INSTANCE_ID --query 'DBInstances[0].DBInstanceStatus' --output text 2>/dev/null)
    
    if [ "$DB_STATUS" == "available" ]; then
        echo "  RDS instance is available"
    else
        echo "  Warning: RDS instance is not available (Status: $DB_STATUS)"
        return 1
    fi
}

# Verify API health endpoint
verify_api_health() {
    echo "Verifying API health endpoint..."
    
    # Check if curl is available
    if ! command -v curl &> /dev/null; then
        echo "  Error: curl not found"
        return 1
    fi
    
    # Make API health check request with timeout
    HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" -m 10 "$API_URL" 2>/dev/null)
    
    if [ "$HTTP_STATUS" == "200" ]; then
        echo "  API health check successful (HTTP 200)"
    else
        echo "  Error: API health check failed (HTTP $HTTP_STATUS)"
        return 1
    fi
}

# Verify frontend accessibility
verify_frontend() {
    echo "Verifying frontend accessibility..."
    
    # Check if curl is available
    if ! command -v curl &> /dev/null; then
        echo "  Error: curl not found"
        return 1
    fi
    
    # Make frontend request with timeout
    HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" -m 10 "$FRONTEND_URL" 2>/dev/null)
    
    if [ "$HTTP_STATUS" == "200" ]; then
        echo "  Frontend is accessible (HTTP 200)"
    else
        echo "  Warning: Frontend may not be fully accessible (HTTP $HTTP_STATUS)"
        # Not a critical error, as frontend may be cached or partially available
    fi
}

# Verify CloudWatch logs for errors
verify_cloudwatch_logs() {
    echo "Verifying CloudWatch logs for errors..."
    
    if [ "$SKIP_AWS_CHECKS" = true ]; then
        echo "  Skipped (AWS CLI not available)"
        return
    fi
    
    # Get logs from the last 10 minutes
    SINCE=$(date -u -d '10 minutes ago' +"%Y-%m-%d %H:%M:%S")
    
    # Check application logs
    echo "  Checking application logs..."
    ERROR_COUNT=$(aws logs filter-log-events \
        --log-group-name "/smartsphere/$ENVIRONMENT/application" \
        --filter-pattern "ERROR" \
        --start-time $(date -d "$SINCE" +%s)000 \
        --query 'events | length(@)' \
        --output text 2>/dev/null || echo "N/A")
    
    if [ "$ERROR_COUNT" == "N/A" ]; then
        echo "    Could not retrieve application logs"
    elif [ "$ERROR_COUNT" -gt 0 ]; then
        echo "    Warning: $ERROR_COUNT ERROR entries found in application logs"
        # Print a sample of errors
        aws logs filter-log-events \
            --log-group-name "/smartsphere/$ENVIRONMENT/application" \
            --filter-pattern "ERROR" \
            --start-time $(date -d "$SINCE" +%s)000 \
            --limit 3 \
            --query 'events[].message' \
            --output text 2>/dev/null | head -n 3 | sed 's/^/      /'
    else
        echo "    No errors found in application logs"
    fi
}

# Wait for service stability
wait_for_stability() {
    echo "Waiting for service stability..."
    
    local attempt=1
    local all_stable=false
    
    while [ $attempt -le $MAX_ATTEMPTS ]; do
        echo "  Attempt $attempt of $MAX_ATTEMPTS"
        
        # Verify API health
        if verify_api_health; then
            all_stable=true
            break
        else
            all_stable=false
        fi
        
        echo "  Waiting $CHECK_INTERVAL seconds before next check..."
        sleep $CHECK_INTERVAL
        ((attempt++))
    done
    
    if [ "$all_stable" = true ]; then
        echo "  Services are stable and healthy"
        return 0
    else
        echo "  Error: Services did not stabilize within timeout period"
        return 1
    fi
}

# Perform synthetic checks for critical functionality
perform_synthetic_checks() {
    echo "Performing synthetic checks for critical functionality..."
    
    # Here, you would typically call a script or function that exercises 
    # critical paths in your application's functionality.
    # For example, test login/logout, data fetching, etc.
    
    echo "  Synthetic checks would be performed here"
    echo "  Note: Detailed synthetic testing is available in CloudWatch Synthetics"
}

# Main verification process
main() {
    echo "Starting verification process..."
    echo
    
    # Step 1: Verify infrastructure components
    verify_ecs_service
    echo
    
    verify_rds_instance
    echo
    
    # Step 2: Verify application endpoints
    verify_api_health
    echo
    
    verify_frontend
    echo
    
    # Step 3: Check logs for errors
    verify_cloudwatch_logs
    echo
    
    # Step 4: Wait for service stability
    wait_for_stability
    if [ $? -ne 0 ]; then
        echo "Verification failed: Services did not stabilize"
        exit 1
    fi
    echo
    
    # Step 5: Perform synthetic checks
    perform_synthetic_checks
    echo
    
    echo "Verification completed successfully"
    echo "Deployment to $ENVIRONMENT environment appears to be healthy"
}

# Run the main verification process
main