#!/bin/bash
# Cost Optimization Script for SmartSphere AWS Infrastructure

set -e

# Configuration
OUTPUT_DIR="./cost-optimization"
REPORT_FILE="cost-optimization-report.json"
HTML_REPORT="cost-optimization-report.html"

echo "SmartSphere Cost Optimization Report Generator"
echo "=============================================="
echo

# Create output directory if it doesn't exist
mkdir -p ${OUTPUT_DIR}

# Check if required AWS CLI is installed
if ! command -v aws &> /dev/null; then
    echo "Error: AWS CLI is not installed"
    exit 1
fi

if ! command -v jq &> /dev/null; then
    echo "Error: jq is not installed"
    exit 1
fi

echo "Analyzing infrastructure for cost optimization opportunities..."

# Define optimization categories
CATEGORIES=(
  "Compute"
  "Storage"
  "Database"
  "Networking"
  "ElasticCache"
  "Other"
)

# Initialize recommendations JSON structure
cat > ${OUTPUT_DIR}/${REPORT_FILE} << EOL
{
  "reportMetadata": {
    "generatedAt": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
    "project": "SmartSphere",
    "region": "$(aws configure get region)",
    "version": "1.0.0"
  },
  "totalSavings": {
    "monthly": 0,
    "annual": 0
  },
  "recommendations": []
}
EOL

# Function to get EC2 right-sizing recommendations
get_ec2_recommendations() {
  echo "Analyzing EC2 instances for right-sizing opportunities..."
  
  # Get EC2 instances
  aws ec2 describe-instances --query 'Reservations[*].Instances[*].[InstanceId,InstanceType,State.Name,Tags[?Key==`Name`].Value | [0]]' --output json > ${OUTPUT_DIR}/ec2_instances.json 2>/dev/null || echo "Warning: Could not retrieve EC2 instances"
  
  # Check for running instances that could be downsized based on CloudWatch metrics
  INSTANCES=$(jq -r '.[][] | select(.[2] == "running") | .[0]' ${OUTPUT_DIR}/ec2_instances.json 2>/dev/null || echo "")
  
  for INSTANCE_ID in ${INSTANCES}; do
    # Get instance details
    INSTANCE_TYPE=$(jq -r ".[][] | select(.[0] == \"${INSTANCE_ID}\") | .[1]" ${OUTPUT_DIR}/ec2_instances.json)
    INSTANCE_NAME=$(jq -r ".[][] | select(.[0] == \"${INSTANCE_ID}\") | .[3] // \"Unnamed\"" ${OUTPUT_DIR}/ec2_instances.json)
    
    # Get CPU utilization for the past 14 days
    aws cloudwatch get-metric-statistics \
      --namespace AWS/EC2 \
      --metric-name CPUUtilization \
      --dimensions Name=InstanceId,Value=${INSTANCE_ID} \
      --start-time $(date -u -d "14 days ago" +"%Y-%m-%dT%H:%M:%SZ") \
      --end-time $(date -u +"%Y-%m-%dT%H:%M:%SZ") \
      --period 86400 \
      --statistics Maximum Average \
      --output json > ${OUTPUT_DIR}/ec2_${INSTANCE_ID}_cpu.json 2>/dev/null || echo "Warning: Could not retrieve CPU metrics for ${INSTANCE_ID}"
    
    # Check if instance is underutilized
    MAX_CPU=$(jq -r '.Datapoints[].Maximum | select(. != null) | tonumber' ${OUTPUT_DIR}/ec2_${INSTANCE_ID}_cpu.json 2>/dev/null | sort -rn | head -1)
    AVG_CPU=$(jq -r '.Datapoints[].Average | select(. != null) | tonumber' ${OUTPUT_DIR}/ec2_${INSTANCE_ID}_cpu.json 2>/dev/null | sort -rn | head -1)
    
    # If max CPU is less than 50% and average is less than 20%, recommend downsizing
    if [ ! -z "$MAX_CPU" ] && [ ! -z "$AVG_CPU" ] && (( $(echo "${MAX_CPU} < 50" | bc -l) )) && (( $(echo "${AVG_CPU} < 20" | bc -l) )); then
      # Determine a smaller instance type
      CURRENT_TYPE_FAMILY=$(echo ${INSTANCE_TYPE} | grep -o '^[a-z][0-9][a-z]*')
      CURRENT_SIZE=$(echo ${INSTANCE_TYPE} | grep -o '[a-z]*$')
      
      # Simple logic to recommend smaller size
      NEW_SIZE=""
      MONTHLY_SAVINGS=0
      
      if [[ "${CURRENT_SIZE}" == "2xlarge" ]]; then
        NEW_SIZE="xlarge"
        MONTHLY_SAVINGS=100
      elif [[ "${CURRENT_SIZE}" == "xlarge" ]]; then
        NEW_SIZE="large"
        MONTHLY_SAVINGS=50
      elif [[ "${CURRENT_SIZE}" == "large" ]]; then
        NEW_SIZE="medium"
        MONTHLY_SAVINGS=25
      elif [[ "${CURRENT_SIZE}" == "medium" ]]; then
        NEW_SIZE="small"
        MONTHLY_SAVINGS=10
      fi
      
      if [ ! -z "$NEW_SIZE" ]; then
        NEW_TYPE="${CURRENT_TYPE_FAMILY}.${NEW_SIZE}"
        
        # Add recommendation to the report
        jq --arg id "${INSTANCE_ID}" \
           --arg name "${INSTANCE_NAME}" \
           --arg type "EC2 Right-sizing" \
           --arg resource_type "EC2 Instance" \
           --arg current "${INSTANCE_TYPE}" \
           --arg recommended "${NEW_TYPE}" \
           --arg reason "Low CPU utilization (Max: ${MAX_CPU}%, Avg: ${AVG_CPU}%)" \
           --argjson monthly_savings ${MONTHLY_SAVINGS} \
           --argjson annual_savings $((MONTHLY_SAVINGS * 12)) \
           --arg category "Compute" \
           '.recommendations += [{
             "id": $id,
             "name": $name,
             "type": $type,
             "resourceType": $resource_type,
             "current": $current,
             "recommended": $recommended,
             "reason": $reason,
             "savings": {
               "monthly": $monthly_savings,
               "annual": $annual_savings
             },
             "category": $category,
             "difficulty": "Medium",
             "impact": "Low"
           }]' ${OUTPUT_DIR}/${REPORT_FILE} > ${OUTPUT_DIR}/temp.json && mv ${OUTPUT_DIR}/temp.json ${OUTPUT_DIR}/${REPORT_FILE}
        
        # Update total savings
        jq --argjson monthly_savings ${MONTHLY_SAVINGS} \
           --argjson annual_savings $((MONTHLY_SAVINGS * 12)) \
           '.totalSavings.monthly += $monthly_savings | .totalSavings.annual += $annual_savings' ${OUTPUT_DIR}/${REPORT_FILE} > ${OUTPUT_DIR}/temp.json && mv ${OUTPUT_DIR}/temp.json ${OUTPUT_DIR}/${REPORT_FILE}
      fi
    fi
  done
}

# Function to get EBS volume optimization recommendations
get_ebs_recommendations() {
  echo "Analyzing EBS volumes for optimization opportunities..."
  
  # Get EBS volumes
  aws ec2 describe-volumes --query 'Volumes[*].[VolumeId,Size,VolumeType,State,CreateTime,Tags[?Key==`Name`].Value | [0]]' --output json > ${OUTPUT_DIR}/ebs_volumes.json 2>/dev/null || echo "Warning: Could not retrieve EBS volumes"
  
  # Check for volumes that are not attached (available state)
  AVAILABLE_VOLUMES=$(jq -r '.[] | select(.[3] == "available") | .[0]' ${OUTPUT_DIR}/ebs_volumes.json 2>/dev/null || echo "")
  
  for VOLUME_ID in ${AVAILABLE_VOLUMES}; do
    # Get volume details
    SIZE=$(jq -r ".[] | select(.[0] == \"${VOLUME_ID}\") | .[1]" ${OUTPUT_DIR}/ebs_volumes.json)
    TYPE=$(jq -r ".[] | select(.[0] == \"${VOLUME_ID}\") | .[2]" ${OUTPUT_DIR}/ebs_volumes.json)
    CREATED=$(jq -r ".[] | select(.[0] == \"${VOLUME_ID}\") | .[4]" ${OUTPUT_DIR}/ebs_volumes.json)
    NAME=$(jq -r ".[] | select(.[0] == \"${VOLUME_ID}\") | .[5] // \"Unnamed\"" ${OUTPUT_DIR}/ebs_volumes.json)
    
    # Calculate age in days
    CREATED_TIMESTAMP=$(date -d "${CREATED}" +%s)
    CURRENT_TIMESTAMP=$(date +%s)
    AGE_DAYS=$(( (CURRENT_TIMESTAMP - CREATED_TIMESTAMP) / 86400 ))
    
    # If volume is unattached for more than 30 days, recommend deletion
    if [ ${AGE_DAYS} -gt 30 ]; then
      # Estimate cost savings based on volume type and size
      MONTHLY_SAVINGS=0
      
      if [[ "${TYPE}" == "gp2" ]]; then
        MONTHLY_SAVINGS=$(echo "${SIZE} * 0.1" | bc -l)
      elif [[ "${TYPE}" == "io1" ]]; then
        MONTHLY_SAVINGS=$(echo "${SIZE} * 0.125" | bc -l)
      elif [[ "${TYPE}" == "st1" ]]; then
        MONTHLY_SAVINGS=$(echo "${SIZE} * 0.045" | bc -l)
      elif [[ "${TYPE}" == "sc1" ]]; then
        MONTHLY_SAVINGS=$(echo "${SIZE} * 0.025" | bc -l)
      else
        MONTHLY_SAVINGS=$(echo "${SIZE} * 0.08" | bc -l)
      fi
      
      # Round to 2 decimal places
      MONTHLY_SAVINGS=$(printf "%.2f" ${MONTHLY_SAVINGS})
      
      # Add recommendation to the report
      jq --arg id "${VOLUME_ID}" \
         --arg name "${NAME}" \
         --arg type "Unused EBS Volume" \
         --arg resource_type "EBS Volume" \
         --arg current "${TYPE}, ${SIZE} GB" \
         --arg recommended "Delete" \
         --arg reason "Volume has been unattached for ${AGE_DAYS} days" \
         --argjson monthly_savings ${MONTHLY_SAVINGS} \
         --argjson annual_savings $(echo "${MONTHLY_SAVINGS} * 12" | bc -l) \
         --arg category "Storage" \
         '.recommendations += [{
           "id": $id,
           "name": $name,
           "type": $type,
           "resourceType": $resource_type,
           "current": $current,
           "recommended": $recommended,
           "reason": $reason,
           "savings": {
             "monthly": $monthly_savings,
             "annual": $annual_savings
           },
           "category": $category,
           "difficulty": "Low",
           "impact": "None"
         }]' ${OUTPUT_DIR}/${REPORT_FILE} > ${OUTPUT_DIR}/temp.json && mv ${OUTPUT_DIR}/temp.json ${OUTPUT_DIR}/${REPORT_FILE}
      
      # Update total savings
      jq --argjson monthly_savings ${MONTHLY_SAVINGS} \
         --argjson annual_savings $(echo "${MONTHLY_SAVINGS} * 12" | bc -l) \
         '.totalSavings.monthly += $monthly_savings | .totalSavings.annual += $annual_savings' ${OUTPUT_DIR}/${REPORT_FILE} > ${OUTPUT_DIR}/temp.json && mv ${OUTPUT_DIR}/temp.json ${OUTPUT_DIR}/${REPORT_FILE}
    fi
  done
  
  # Check for GP2 volumes that could be migrated to GP3
  GP2_VOLUMES=$(jq -r '.[] | select(.[2] == "gp2") | .[0]' ${OUTPUT_DIR}/ebs_volumes.json 2>/dev/null || echo "")
  
  for VOLUME_ID in ${GP2_VOLUMES}; then
    # Get volume details
    SIZE=$(jq -r ".[] | select(.[0] == \"${VOLUME_ID}\") | .[1]" ${OUTPUT_DIR}/ebs_volumes.json)
    NAME=$(jq -r ".[] | select(.[0] == \"${VOLUME_ID}\") | .[5] // \"Unnamed\"" ${OUTPUT_DIR}/ebs_volumes.json)
    
    # Calculate savings from gp2 to gp3 migration
    # gp3 is approximately 20% cheaper than gp2
    MONTHLY_SAVINGS=$(echo "${SIZE} * 0.1 * 0.2" | bc -l)
    MONTHLY_SAVINGS=$(printf "%.2f" ${MONTHLY_SAVINGS})
    
    # Add recommendation to the report
    jq --arg id "${VOLUME_ID}" \
       --arg name "${NAME}" \
       --arg type "EBS Volume Type Migration" \
       --arg resource_type "EBS Volume" \
       --arg current "gp2, ${SIZE} GB" \
       --arg recommended "gp3, ${SIZE} GB" \
       --arg reason "GP3 volumes provide better price/performance than GP2" \
       --argjson monthly_savings ${MONTHLY_SAVINGS} \
       --argjson annual_savings $(echo "${MONTHLY_SAVINGS} * 12" | bc -l) \
       --arg category "Storage" \
       '.recommendations += [{
         "id": $id,
         "name": $name,
         "type": $type,
         "resourceType": $resource_type,
         "current": $current,
         "recommended": $recommended,
         "reason": $reason,
         "savings": {
           "monthly": $monthly_savings,
           "annual": $annual_savings
         },
         "category": $category,
         "difficulty": "Low",
         "impact": "None"
       }]' ${OUTPUT_DIR}/${REPORT_FILE} > ${OUTPUT_DIR}/temp.json && mv ${OUTPUT_DIR}/temp.json ${OUTPUT_DIR}/${REPORT_FILE}
    
    # Update total savings
    jq --argjson monthly_savings ${MONTHLY_SAVINGS} \
       --argjson annual_savings $(echo "${MONTHLY_SAVINGS} * 12" | bc -l) \
       '.totalSavings.monthly += $monthly_savings | .totalSavings.annual += $annual_savings' ${OUTPUT_DIR}/${REPORT_FILE} > ${OUTPUT_DIR}/temp.json && mv ${OUTPUT_DIR}/temp.json ${OUTPUT_DIR}/${REPORT_FILE}
  done
}

# Function to get S3 lifecycle policy recommendations
get_s3_recommendations() {
  echo "Analyzing S3 buckets for optimization opportunities..."
  
  # Get S3 buckets
  aws s3api list-buckets --query 'Buckets[*].[Name,CreationDate]' --output json > ${OUTPUT_DIR}/s3_buckets.json 2>/dev/null || echo "Warning: Could not retrieve S3 buckets"
  
  # Get buckets that might benefit from lifecycle policies
  BUCKETS=$(jq -r '.[][0]' ${OUTPUT_DIR}/s3_buckets.json 2>/dev/null || echo "")
  
  for BUCKET in ${BUCKETS}; do
    # Check if lifecycle configuration exists
    aws s3api get-bucket-lifecycle-configuration --bucket ${BUCKET} > ${OUTPUT_DIR}/s3_${BUCKET}_lifecycle.json 2>/dev/null
    
    if [ $? -ne 0 ]; then
      # No lifecycle policy exists
      
      # Get storage metrics for the bucket
      aws s3api list-objects-v2 --bucket ${BUCKET} --query 'Contents[*].[Size,LastModified]' --output json > ${OUTPUT_DIR}/s3_${BUCKET}_objects.json 2>/dev/null || echo "Warning: Could not retrieve objects for ${BUCKET}"
      
      # Calculate total size in GB
      TOTAL_SIZE=$(jq -r '.[].0 // 0' ${OUTPUT_DIR}/s3_${BUCKET}_objects.json 2>/dev/null | awk '{s+=$1} END {print s/1024/1024/1024}')
      
      if [ ! -z "$TOTAL_SIZE" ] && (( $(echo "${TOTAL_SIZE} > 1" | bc -l) )); then
        # Bucket is large enough to benefit from lifecycle policies
        
        # Calculate potential savings with Intelligent Tiering
        # Assume 40% of data could move to cheaper tiers
        MONTHLY_SAVINGS=$(echo "${TOTAL_SIZE} * 0.023 * 0.4" | bc -l)  # $0.023 per GB difference
        MONTHLY_SAVINGS=$(printf "%.2f" ${MONTHLY_SAVINGS})
        
        # Add recommendation to the report
        jq --arg id "${BUCKET}" \
           --arg name "${BUCKET}" \
           --arg type "S3 Lifecycle Policy" \
           --arg resource_type "S3 Bucket" \
           --arg current "Standard storage for all objects" \
           --arg recommended "Implement lifecycle policy for older objects" \
           --arg reason "Automatically transition objects to cheaper storage classes" \
           --argjson monthly_savings ${MONTHLY_SAVINGS} \
           --argjson annual_savings $(echo "${MONTHLY_SAVINGS} * 12" | bc -l) \
           --arg category "Storage" \
           '.recommendations += [{
             "id": $id,
             "name": $name,
             "type": $type,
             "resourceType": $resource_type,
             "current": $current,
             "recommended": $recommended,
             "reason": $reason,
             "savings": {
               "monthly": $monthly_savings,
               "annual": $annual_savings
             },
             "category": $category,
             "difficulty": "Low",
             "impact": "None"
           }]' ${OUTPUT_DIR}/${REPORT_FILE} > ${OUTPUT_DIR}/temp.json && mv ${OUTPUT_DIR}/temp.json ${OUTPUT_DIR}/${REPORT_FILE}
        
        # Update total savings
        jq --argjson monthly_savings ${MONTHLY_SAVINGS} \
           --argjson annual_savings $(echo "${MONTHLY_SAVINGS} * 12" | bc -l) \
           '.totalSavings.monthly += $monthly_savings | .totalSavings.annual += $annual_savings' ${OUTPUT_DIR}/${REPORT_FILE} > ${OUTPUT_DIR}/temp.json && mv ${OUTPUT_DIR}/temp.json ${OUTPUT_DIR}/${REPORT_FILE}
      fi
    fi
  done
}

# Function to get RDS optimization recommendations
get_rds_recommendations() {
  echo "Analyzing RDS instances for optimization opportunities..."
  
  # Get RDS instances
  aws rds describe-db-instances --query 'DBInstances[*].[DBInstanceIdentifier,DBInstanceClass,Engine,MultiAZ,AllocatedStorage]' --output json > ${OUTPUT_DIR}/rds_instances.json 2>/dev/null || echo "Warning: Could not retrieve RDS instances"
  
  # Check for instances that might be oversized or could use reserved instances
  INSTANCES=$(jq -r '.[][0]' ${OUTPUT_DIR}/rds_instances.json 2>/dev/null || echo "")
  
  for INSTANCE_ID in ${INSTANCES}; do
    # Get instance details
    INSTANCE_CLASS=$(jq -r ".[] | select(.[0] == \"${INSTANCE_ID}\") | .[1]" ${OUTPUT_DIR}/rds_instances.json)
    ENGINE=$(jq -r ".[] | select(.[0] == \"${INSTANCE_ID}\") | .[2]" ${OUTPUT_DIR}/rds_instances.json)
    MULTI_AZ=$(jq -r ".[] | select(.[0] == \"${INSTANCE_ID}\") | .[3]" ${OUTPUT_DIR}/rds_instances.json)
    
    # Get RDS CPU utilization for the past 14 days
    aws cloudwatch get-metric-statistics \
      --namespace AWS/RDS \
      --metric-name CPUUtilization \
      --dimensions Name=DBInstanceIdentifier,Value=${INSTANCE_ID} \
      --start-time $(date -u -d "14 days ago" +"%Y-%m-%dT%H:%M:%SZ") \
      --end-time $(date -u +"%Y-%m-%dT%H:%M:%SZ") \
      --period 86400 \
      --statistics Maximum Average \
      --output json > ${OUTPUT_DIR}/rds_${INSTANCE_ID}_cpu.json 2>/dev/null || echo "Warning: Could not retrieve CPU metrics for ${INSTANCE_ID}"
    
    # Check if instance is underutilized
    MAX_CPU=$(jq -r '.Datapoints[].Maximum | select(. != null) | tonumber' ${OUTPUT_DIR}/rds_${INSTANCE_ID}_cpu.json 2>/dev/null | sort -rn | head -1)
    AVG_CPU=$(jq -r '.Datapoints[].Average | select(. != null) | tonumber' ${OUTPUT_DIR}/rds_${INSTANCE_ID}_cpu.json 2>/dev/null | sort -rn | head -1)
    
    # If max CPU is less than 40% and average is less than 15%, recommend downsizing
    if [ ! -z "$MAX_CPU" ] && [ ! -z "$AVG_CPU" ] && (( $(echo "${MAX_CPU} < 40" | bc -l) )) && (( $(echo "${AVG_CPU} < 15" | bc -l) )); then
      # Determine a smaller instance class
      CURRENT_CLASS_FAMILY=$(echo ${INSTANCE_CLASS} | grep -o '^[a-z][0-9][a-z]*\.[a-z]*')
      CURRENT_SIZE=$(echo ${INSTANCE_CLASS} | grep -o '[0-9]*[a-z]*$')
      
      # Simple logic to recommend smaller size
      NEW_SIZE=""
      MONTHLY_SAVINGS=0
      
      if [[ "${CURRENT_SIZE}" == "4xlarge" ]]; then
        NEW_SIZE="2xlarge"
        MONTHLY_SAVINGS=200
      elif [[ "${CURRENT_SIZE}" == "2xlarge" ]]; then
        NEW_SIZE="xlarge"
        MONTHLY_SAVINGS=150
      elif [[ "${CURRENT_SIZE}" == "xlarge" ]]; then
        NEW_SIZE="large"
        MONTHLY_SAVINGS=100
      elif [[ "${CURRENT_SIZE}" == "large" ]]; then
        NEW_SIZE="medium"
        MONTHLY_SAVINGS=60
      fi
      
      if [ ! -z "$NEW_SIZE" ]; then
        NEW_CLASS="${CURRENT_CLASS_FAMILY}${NEW_SIZE}"
        
        # Add recommendation to the report
        jq --arg id "${INSTANCE_ID}" \
           --arg name "${INSTANCE_ID}" \
           --arg type "RDS Right-sizing" \
           --arg resource_type "RDS Instance" \
           --arg current "${INSTANCE_CLASS}" \
           --arg recommended "${NEW_CLASS}" \
           --arg reason "Low CPU utilization (Max: ${MAX_CPU}%, Avg: ${AVG_CPU}%)" \
           --argjson monthly_savings ${MONTHLY_SAVINGS} \
           --argjson annual_savings $((MONTHLY_SAVINGS * 12)) \
           --arg category "Database" \
           '.recommendations += [{
             "id": $id,
             "name": $name,
             "type": $type,
             "resourceType": $resource_type,
             "current": $current,
             "recommended": $recommended,
             "reason": $reason,
             "savings": {
               "monthly": $monthly_savings,
               "annual": $annual_savings
             },
             "category": $category,
             "difficulty": "Medium",
             "impact": "Medium"
           }]' ${OUTPUT_DIR}/${REPORT_FILE} > ${OUTPUT_DIR}/temp.json && mv ${OUTPUT_DIR}/temp.json ${OUTPUT_DIR}/${REPORT_FILE}
        
        # Update total savings
        jq --argjson monthly_savings ${MONTHLY_SAVINGS} \
           --argjson annual_savings $((MONTHLY_SAVINGS * 12)) \
           '.totalSavings.monthly += $monthly_savings | .totalSavings.annual += $annual_savings' ${OUTPUT_DIR}/${REPORT_FILE} > ${OUTPUT_DIR}/temp.json && mv ${OUTPUT_DIR}/temp.json ${OUTPUT_DIR}/${REPORT_FILE}
      fi
    }
    
    # Check if this instance could benefit from reserved instances
    # For simplicity, recommend RIs for any instance without considering utilization patterns
    # In a real implementation, you'd check for stable workloads over time
    MONTHLY_ON_DEMAND_COST=0
    MONTHLY_RI_COST=0
    
    # Very simplified cost estimation based on instance class
    if [[ "${INSTANCE_CLASS}" == *"small"* ]]; then
      MONTHLY_ON_DEMAND_COST=100
      MONTHLY_RI_COST=60  # ~40% savings
    elif [[ "${INSTANCE_CLASS}" == *"medium"* ]]; then
      MONTHLY_ON_DEMAND_COST=200
      MONTHLY_RI_COST=120  # ~40% savings
    elif [[ "${INSTANCE_CLASS}" == *"large"* ]]; then
      MONTHLY_ON_DEMAND_COST=400
      MONTHLY_RI_COST=240  # ~40% savings
    elif [[ "${INSTANCE_CLASS}" == *"xlarge"* ]]; then
      MONTHLY_ON_DEMAND_COST=800
      MONTHLY_RI_COST=480  # ~40% savings
    elif [[ "${INSTANCE_CLASS}" == *"2xlarge"* ]]; then
      MONTHLY_ON_DEMAND_COST=1600
      MONTHLY_RI_COST=960  # ~40% savings
    fi
    
    if [ ${MONTHLY_ON_DEMAND_COST} -gt 0 ]; then
      MONTHLY_SAVINGS=$((MONTHLY_ON_DEMAND_COST - MONTHLY_RI_COST))
      
      # Add recommendation to the report
      jq --arg id "${INSTANCE_ID}_ri" \
         --arg name "${INSTANCE_ID}" \
         --arg type "RDS Reserved Instance" \
         --arg resource_type "RDS Instance" \
         --arg current "On-Demand pricing" \
         --arg recommended "Reserved Instance (1 year term)" \
         --arg reason "Save approximately 40% with a 1-year Reserved Instance commitment" \
         --argjson monthly_savings ${MONTHLY_SAVINGS} \
         --argjson annual_savings $((MONTHLY_SAVINGS * 12)) \
         --arg category "Database" \
         '.recommendations += [{
           "id": $id,
           "name": $name,
           "type": $type,
           "resourceType": $resource_type,
           "current": $current,
           "recommended": $recommended,
           "reason": $reason,
           "savings": {
             "monthly": $monthly_savings,
             "annual": $annual_savings
           },
           "category": $category,
           "difficulty": "Low",
           "impact": "None"
         }]' ${OUTPUT_DIR}/${REPORT_FILE} > ${OUTPUT_DIR}/temp.json && mv ${OUTPUT_DIR}/temp.json ${OUTPUT_DIR}/${REPORT_FILE}
      
      # Update total savings
      jq --argjson monthly_savings ${MONTHLY_SAVINGS} \
         --argjson annual_savings $((MONTHLY_SAVINGS * 12)) \
         '.totalSavings.monthly += $monthly_savings | .totalSavings.annual += $annual_savings' ${OUTPUT_DIR}/${REPORT_FILE} > ${OUTPUT_DIR}/temp.json && mv ${OUTPUT_DIR}/temp.json ${OUTPUT_DIR}/${REPORT_FILE}
    fi
  done
}

# Run all analysis functions
get_ec2_recommendations
get_ebs_recommendations
get_s3_recommendations
get_rds_recommendations

# Generate HTML report
echo "Generating HTML report..."

cat > ${OUTPUT_DIR}/${HTML_REPORT} << EOL
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>SmartSphere Cost Optimization Report</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.1.3/dist/css/bootstrap.min.css" rel="stylesheet">
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.8.1/font/bootstrap-icons.css">
    <script src="https://cdn.jsdelivr.net/npm/chart.js@3.7.1/dist/chart.min.js"></script>
    <style>
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background-color: #f8f9fa;
            padding-top: 20px;
        }
        .header {
            background-color: #fff;
            border-bottom: 1px solid #e9ecef;
            padding: 15px 0;
            margin-bottom: 20px;
        }
        .card {
            margin-bottom: 20px;
            border-radius: 8px;
            box-shadow: 0 4px 6px rgba(0, 0, 0, 0.05);
        }
        .card-header {
            border-radius: 8px 8px 0 0 !important;
            font-weight: 600;
        }
        .savings-card {
            background-color: #f9fff9;
            border-left: 4px solid #28a745;
        }
        .savings-value {
            font-size: 2.5rem;
            font-weight: 300;
            color: #28a745;
        }
        .savings-label {
            font-size: 0.875rem;
            color: #6c757d;
        }
        .filter-btn {
            margin-right: 5px;
            margin-bottom: 5px;
        }
        .recommendation-item {
            border-left: 4px solid #0066cc;
            padding: 15px;
            margin-bottom: 15px;
            background-color: #f8f9fa;
            transition: all 0.2s ease;
        }
        .recommendation-item:hover {
            box-shadow: 0 4px 8px rgba(0, 0, 0, 0.1);
        }
        .recommendation-title {
            font-weight: 600;
            margin-bottom: 5px;
        }
        .recommendation-id {
            font-size: 0.8rem;
            color: #6c757d;
        }
        .recommendation-savings {
            float: right;
            font-weight: 600;
            color: #28a745;
        }
        .recommendation-details {
            margin-top: 10px;
            font-size: 0.9rem;
        }
        .chart-container {
            height: 250px;
            margin-bottom: 20px;
        }
        .difficulty-tag {
            display: inline-block;
            padding: 2px 8px;
            border-radius: 4px;
            font-size: 0.75rem;
            font-weight: 600;
            text-transform: uppercase;
        }
        .difficulty-low {
            background-color: #d4edda;
            color: #155724;
        }
        .difficulty-medium {
            background-color: #fff3cd;
            color: #856404;
        }
        .difficulty-high {
            background-color: #f8d7da;
            color: #721c24;
        }
        .last-updated {
            font-size: 0.8rem;
            color: #6c757d;
            margin-top: 15px;
            text-align: center;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <div class="row align-items-center">
                <div class="col-md-6">
                    <h1 class="h3">SmartSphere Cost Optimization Report</h1>
                    <p class="text-muted">Recommendations to reduce AWS infrastructure costs</p>
                </div>
                <div class="col-md-6 text-end">
                    <button class="btn btn-primary" onclick="window.print()">
                        <i class="bi bi-printer"></i> Print Report
                    </button>
                    <button class="btn btn-outline-secondary" id="export-csv">
                        <i class="bi bi-file-earmark-excel"></i> Export CSV
                    </button>
                </div>
            </div>
        </div>
        
        <div class="row">
            <div class="col-md-8">
                <div class="row">
                    <div class="col-md-6">
                        <div class="card savings-card h-100">
                            <div class="card-body">
                                <div class="savings-label">Potential Monthly Savings</div>
                                <div class="savings-value" id="monthly-savings">$0.00</div>
                            </div>
                        </div>
                    </div>
                    <div class="col-md-6">
                        <div class="card savings-card h-100">
                            <div class="card-body">
                                <div class="savings-label">Potential Annual Savings</div>
                                <div class="savings-value" id="annual-savings">$0.00</div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
            <div class="col-md-4">
                <div class="card h-100">
                    <div class="card-body">
                        <canvas id="savingsByCategoryChart"></canvas>
                    </div>
                </div>
            </div>
        </div>
        
        <div class="row mt-4">
            <div class="col-md-12">
                <div class="card">
                    <div class="card-header bg-white">
                        <div class="d-flex justify-content-between align-items-center">
                            <div>
                                <i class="bi bi-lightning-charge me-2"></i> Optimization Recommendations
                            </div>
                            <div>
                                <div class="input-group">
                                    <input type="text" class="form-control form-control-sm" id="search-input" placeholder="Search recommendations...">
                                    <button class="btn btn-outline-secondary btn-sm" type="button" id="search-btn">
                                        <i class="bi bi-search"></i>
                                    </button>
                                </div>
                            </div>
                        </div>
                    </div>
                    <div class="card-body">
                        <div class="mb-3">
                            <button class="btn btn-sm btn-outline-primary filter-btn active" data-filter="all">All</button>
                            <button class="btn btn-sm btn-outline-primary filter-btn" data-filter="Compute">Compute</button>
                            <button class="btn btn-sm btn-outline-primary filter-btn" data-filter="Storage">Storage</button>
                            <button class="btn btn-sm btn-outline-primary filter-btn" data-filter="Database">Database</button>
                            <button class="btn btn-sm btn-outline-primary filter-btn" data-filter="Networking">Networking</button>
                        </div>
                        
                        <div id="recommendations-container">
                            <!-- Recommendations will be populated here -->
                        </div>
                    </div>
                </div>
            </div>
        </div>
        
        <div class="last-updated mt-4" id="report-metadata">
            <!-- Report metadata will be populated here -->
        </div>
    </div>
    
    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.1.3/dist/js/bootstrap.bundle.min.js"></script>
    <script>
        // Load and parse optimization data
        fetch('${REPORT_FILE}')
            .then(response => response.json())
            .then(data => {
                // Populate report metadata
                document.getElementById('report-metadata').textContent = 
                    'Report generated at: ' + new Date(data.reportMetadata.generatedAt).toLocaleString() + 
                    ' for ' + data.reportMetadata.project + ' (Region: ' + data.reportMetadata.region + ')';
                
                // Populate savings numbers
                document.getElementById('monthly-savings').textContent = '$' + data.totalSavings.monthly.toFixed(2);
                document.getElementById('annual-savings').textContent = '$' + data.totalSavings.annual.toFixed(2);
                
                // Render recommendations
                renderRecommendations(data.recommendations);
                
                // Render savings by category chart
                renderSavingsByCategoryChart(data.recommendations);
                
                // Set up event handlers
                document.querySelectorAll('.filter-btn').forEach(button => {
                    button.addEventListener('click', function() {
                        // Toggle active state
                        document.querySelectorAll('.filter-btn').forEach(btn => {
                            btn.classList.remove('active');
                        });
                        this.classList.add('active');
                        
                        // Filter recommendations
                        filterRecommendations(data.recommendations, this.getAttribute('data-filter'));
                    });
                });
                
                document.getElementById('search-btn').addEventListener('click', function() {
                    const searchTerm = document.getElementById('search-input').value.toLowerCase();
                    searchRecommendations(data.recommendations, searchTerm);
                });
                
                document.getElementById('search-input').addEventListener('keypress', function(e) {
                    if (e.key === 'Enter') {
                        const searchTerm = this.value.toLowerCase();
                        searchRecommendations(data.recommendations, searchTerm);
                    }
                });
                
                document.getElementById('export-csv').addEventListener('click', function() {
                    exportToCsv(data.recommendations);
                });
            })
            .catch(error => {
                console.error('Error loading optimization data:', error);
                alert('Failed to load optimization data');
            });
        
        // Render recommendations
        function renderRecommendations(recommendations) {
            const container = document.getElementById('recommendations-container');
            container.innerHTML = '';
            
            if (recommendations.length === 0) {
                container.innerHTML = '<div class="alert alert-info">No cost optimization recommendations found.</div>';
                return;
            }
            
            recommendations.forEach(recommendation => {
                const item = document.createElement('div');
                item.className = 'recommendation-item';
                item.setAttribute('data-category', recommendation.category);
                
                let difficultyClass = 'difficulty-low';
                if (recommendation.difficulty === 'Medium') {
                    difficultyClass = 'difficulty-medium';
                } else if (recommendation.difficulty === 'High') {
                    difficultyClass = 'difficulty-high';
                }
                
                item.innerHTML = \`
                    <div>
                        <span class="recommendation-id">\${recommendation.id}</span>
                        <span class="recommendation-savings">$\${recommendation.savings.monthly.toFixed(2)}/month</span>
                    </div>
                    <div class="recommendation-title">\${recommendation.type}: \${recommendation.name}</div>
                    <div>
                        <span class="badge bg-secondary">\${recommendation.category}</span>
                        <span class="difficulty-tag \${difficultyClass}">\${recommendation.difficulty}</span>
                    </div>
                    <div class="recommendation-details">
                        <div><strong>Current:</strong> \${recommendation.current}</div>
                        <div><strong>Recommended:</strong> \${recommendation.recommended}</div>
                        <div><strong>Reason:</strong> \${recommendation.reason}</div>
                        <div><strong>Savings:</strong> $\${recommendation.savings.monthly.toFixed(2)}/month ($\${recommendation.savings.annual.toFixed(2)}/year)</div>
                    </div>
                \`;
                
                container.appendChild(item);
            });
        }
        
        // Filter recommendations by category
        function filterRecommendations(recommendations, category) {
            const container = document.getElementById('recommendations-container');
            const items = container.querySelectorAll('.recommendation-item');
            
            items.forEach(item => {
                if (category === 'all' || item.getAttribute('data-category') === category) {
                    item.style.display = 'block';
                } else {
                    item.style.display = 'none';
                }
            });
        }
        
        // Search recommendations
        function searchRecommendations(recommendations, searchTerm) {
            const container = document.getElementById('recommendations-container');
            
            // If search term is empty, show all
            if (!searchTerm) {
                renderRecommendations(recommendations);
                return;
            }
            
            // Filter recommendations that match the search term
            const filteredRecommendations = recommendations.filter(rec => {
                return rec.name.toLowerCase().includes(searchTerm) || 
                       rec.id.toLowerCase().includes(searchTerm) || 
                       rec.type.toLowerCase().includes(searchTerm) || 
                       rec.category.toLowerCase().includes(searchTerm) || 
                       rec.reason.toLowerCase().includes(searchTerm);
            });
            
            renderRecommendations(filteredRecommendations);
        }
        
        // Render savings by category chart
        function renderSavingsByCategoryChart(recommendations) {
            // Group savings by category
            const categoryMap = {};
            
            recommendations.forEach(rec => {
                if (!categoryMap[rec.category]) {
                    categoryMap[rec.category] = 0;
                }
                categoryMap[rec.category] += rec.savings.monthly;
            });
            
            const categories = Object.keys(categoryMap);
            const savings = Object.values(categoryMap);
            
            // Define colors for each category
            const colors = {
                'Compute': '#007bff',
                'Storage': '#28a745',
                'Database': '#ffc107',
                'Networking': '#17a2b8',
                'ElasticCache': '#6610f2',
                'Other': '#6c757d'
            };
            
            const categoryColors = categories.map(category => colors[category] || '#6c757d');
            
            const ctx = document.getElementById('savingsByCategoryChart').getContext('2d');
            new Chart(ctx, {
                type: 'doughnut',
                data: {
                    labels: categories,
                    datasets: [{
                        data: savings,
                        backgroundColor: categoryColors,
                        borderWidth: 1
                    }]
                },
                options: {
                    responsive: true,
                    maintainAspectRatio: false,
                    plugins: {
                        legend: {
                            position: 'bottom',
                            labels: {
                                boxWidth: 12
                            }
                        },
                        title: {
                            display: true,
                            text: 'Monthly Savings by Category',
                            font: {
                                size: 14
                            }
                        }
                    }
                }
            });
        }
        
        // Export recommendations to CSV
        function exportToCsv(recommendations) {
            const headers = ['ID', 'Name', 'Type', 'Category', 'Current', 'Recommended', 'Reason', 'Monthly Savings', 'Annual Savings', 'Difficulty', 'Impact'];
            
            const rows = recommendations.map(rec => [
                rec.id,
                rec.name,
                rec.type,
                rec.category,
                rec.current,
                rec.recommended,
                rec.reason,
                '$' + rec.savings.monthly.toFixed(2),
                '$' + rec.savings.annual.toFixed(2),
                rec.difficulty,
                rec.impact
            ]);
            
            // Add headers
            rows.unshift(headers);
            
            // Convert to CSV
            const csvContent = rows.map(row => row.join(',')).join('\\n');
            
            // Create a blob and download
            const blob = new Blob([csvContent], { type: 'text/csv;charset=utf-8;' });
            const link = document.createElement('a');
            const url = URL.createObjectURL(blob);
            link.setAttribute('href', url);
            link.setAttribute('download', 'cost-optimization-recommendations.csv');
            link.style.visibility = 'hidden';
            document.body.appendChild(link);
            link.click();
            document.body.removeChild(link);
        }
    </script>
</body>
</html>
EOL

# Clean up temporary files
rm -f ${OUTPUT_DIR}/*_*.json 2>/dev/null

echo "Cost optimization report generated at:"
echo "- JSON report: ${OUTPUT_DIR}/${REPORT_FILE}"
echo "- HTML report: ${OUTPUT_DIR}/${HTML_REPORT}"
echo
echo "To view the HTML report, open: ${OUTPUT_DIR}/${HTML_REPORT}"
echo