# SmartSphere Deployment Guide

This comprehensive guide outlines the deployment processes, tools, and best practices for the SmartSphere application infrastructure.

## Table of Contents

1. [Deployment Architecture](#deployment-architecture)
2. [Prerequisites](#prerequisites)
3. [Infrastructure Deployment](#infrastructure-deployment)
4. [CI/CD Pipeline](#ci-cd-pipeline)
5. [Blue-Green Deployment Strategy](#blue-green-deployment-strategy)
6. [Multi-Region Deployment](#multi-region-deployment)
7. [AWS Amplify Frontend Deployment](#aws-amplify-frontend-deployment)
8. [Rollback Procedures](#rollback-procedures)
9. [Monitoring Deployment Health](#monitoring-deployment-health)
10. [Troubleshooting](#troubleshooting)

## Deployment Architecture

SmartSphere employs a modern, cloud-native architecture deployed on AWS with the following key components:

- **Frontend**: React application deployed via AWS Amplify
- **Backend Services**: Containerized microservices deployed on Amazon ECS
- **Database**: Amazon RDS with PostgreSQL
- **Storage**: Amazon S3 for static files and backups
- **CDN**: Amazon CloudFront for content delivery
- **Load Balancer**: Application Load Balancer (ALB) for traffic distribution
- **Networking**: VPC with public and private subnets
- **Monitoring**: CloudWatch for metrics, logs, and alarms
- **Security**: WAF, Security Groups, IAM, and KMS for encryption

The infrastructure is defined as code using Terraform, enabling consistent and reproducible deployments across environments.

## Prerequisites

Before deploying SmartSphere, ensure you have the following prerequisites:

1. **AWS Account** with appropriate permissions:
   - IAM permissions for creating resources
   - Service-linked roles for ECS, RDS, etc.

2. **Tools Installed**:
   - Terraform >= 1.0.0
   - AWS CLI >= 2.0.0
   - Git
   - Node.js >= 16.x (for frontend development)
   - Docker (for local container testing)

3. **Configuration**:
   - AWS credentials configured (`~/.aws/credentials`)
   - S3 bucket for Terraform state
   - DynamoDB table for state locking

4. **Domain and Certificates**:
   - Registered domain name
   - Route 53 hosted zone
   - ACM certificates for HTTPS

## Infrastructure Deployment

### Environment Setup

SmartSphere supports multiple deployment environments:

- **Development (dev)**: For ongoing development and testing
- **Staging**: For pre-production validation
- **Production (prod)**: For live workloads

Each environment has its own dedicated infrastructure defined in separate Terraform variable files located in `terraform/environments/`.

### Deployment Steps

1. **Initialize Terraform**:

   ```bash
   cd terraform
   terraform init -backend-config=environments/${ENV}/backend.tfvars
   ```

2. **Select Workspace**:

   ```bash
   terraform workspace select ${ENV} || terraform workspace new ${ENV}
   ```

3. **Plan the Deployment**:

   ```bash
   terraform plan -var-file=environments/${ENV}/terraform.tfvars -out=tfplan
   ```

4. **Apply the Changes**:

   ```bash
   terraform apply tfplan
   ```

5. **Verify Deployment**:

   ```bash
   ./scripts/verify-deployment.sh ${ENV}
   ```

### Infrastructure Visualization

Generate an interactive visualization of the deployed infrastructure:

```bash
./scripts/generate-topology.sh
```

This creates an interactive HTML visualization of your infrastructure in the `topology/` directory.

## CI/CD Pipeline

SmartSphere leverages GitHub Actions for continuous integration and deployment:

### Workflow Files

- `.github/workflows/ci.yml`: Runs on pull requests to validate changes
- `.github/workflows/cd.yml`: Deploys infrastructure and application on merges to main branches

### CI Pipeline Steps

1. **Code Checkout**: Retrieves the latest code from the repository
2. **Dependency Installation**: Installs required packages
3. **Code Linting**: Verifies code style and formatting
4. **Unit Testing**: Runs automated tests
5. **Security Scanning**: Checks for vulnerabilities
6. **Terraform Validation**: Ensures Terraform configurations are valid

### CD Pipeline Steps

1. **Environment Selection**: Determines the target environment
2. **Infrastructure Deployment**: Applies Terraform changes
3. **Application Deployment**: Updates ECS services and Amplify applications
4. **Database Migrations**: Applies schema changes
5. **Synthetic Testing**: Validates deployment with automated tests
6. **Notification**: Sends deployment status notifications

## Blue-Green Deployment Strategy

SmartSphere implements zero-downtime deployments using a blue-green strategy:

### How It Works

1. **Initial State**: Traffic routes to the "blue" environment
2. **New Deployment**: A new "green" environment is provisioned with the updated application
3. **Testing**: Automated tests verify the green environment's functionality
4. **Traffic Shifting**: Traffic gradually transitions from blue to green
5. **Completion**: When green receives 100% of traffic, blue becomes standby

### Implementation Details

The blue-green deployment is orchestrated through the Terraform configuration in `terraform/blue-green.tf` with AWS CodeDeploy managing the traffic shifting.

To manually control deployments:

```bash
./scripts/deploy.sh --color green  # Force deployment to green
./scripts/deploy.sh --gradual      # Gradual traffic shifting
```

## Multi-Region Deployment

For high availability and disaster recovery, SmartSphere supports multi-region deployment:

### Architecture

- **Primary Region**: Handles normal production traffic
- **Secondary Region**: Maintains a synchronized standby environment
- **Route 53**: Uses health checks and routing policies to direct traffic
- **Data Replication**: RDS cross-region replicas and S3 replication

### Activation Procedure

In case of primary region failure:

1. **Detection**: CloudWatch alarms trigger on service degradation
2. **Failover**: Automated or manual promotion of the secondary region
3. **DNS Update**: Route 53 redirects traffic to the secondary region
4. **Notification**: Operators are alerted about the failover

```bash
# Manual failover
./scripts/failover.sh --region us-west-2
```

## AWS Amplify Frontend Deployment

SmartSphere's frontend is deployed using AWS Amplify for simplified CI/CD:

### Configuration

The Amplify configuration is defined in `terraform/amplify.tf`, which sets up:

- GitHub repository connection
- Build and deployment settings
- Branch-specific environments
- Custom domain configuration

### Deployment Process

1. Code is pushed to a configured Git branch
2. Amplify automatically detects changes and triggers a build
3. The build process runs tests and creates optimized assets
4. The new version is deployed to the corresponding environment
5. If enabled, previews are generated for pull requests

### Environment-Specific Settings

Each branch environment can have custom settings:

- **Main Branch**: Maps to production environment
- **Develop Branch**: Maps to development environment
- **Feature Branches**: Create temporary preview environments

## Rollback Procedures

In case of deployment issues, SmartSphere provides several rollback options:

### Infrastructure Rollback

```bash
terraform apply -var-file=environments/${ENV}/terraform.tfvars -target=module.previous_state
```

### Application Rollback

For ECS deployments:

```bash
aws ecs update-service --cluster smartsphere-cluster --service smartsphere-service --task-definition smartsphere:previous
```

For Amplify deployments:

```bash
aws amplify start-deployment --app-id <AMPLIFY_APP_ID> --branch-name main --job-id <PREVIOUS_JOB_ID>
```

### Database Rollback

```bash
./scripts/rollback-database.sh --to-version <PREVIOUS_VERSION>
```

### One-Click Rollback

For emergencies, use the quick rollback script:

```bash
./scripts/rollback-deployment.sh --environment prod
```

## Monitoring Deployment Health

SmartSphere provides comprehensive deployment health monitoring:

### Health Dashboard

Generate a real-time deployment health dashboard:

```bash
./scripts/generate-dashboard.sh
```

This creates an interactive dashboard showing:

- Service health metrics
- Deployment history
- Performance indicators
- Alert status

### Key Metrics

Monitor these key metrics during and after deployments:

- **Response Times**: Should remain consistent during deployment
- **Error Rates**: Should not increase
- **CPU/Memory Usage**: Should stay within expected ranges
- **Database Connections**: Should maintain healthy levels
- **API Success Rate**: Should maintain high success rates

### Automated Canaries

Synthetic monitoring continuously validates critical flows:

```bash
aws synthetics start-canary --name api-performance-canary
```

## Troubleshooting

Common deployment issues and their solutions:

### Infrastructure Deployment Failures

- **State Lock Issues**: Use `terraform force-unlock` if a lock is stuck
- **Permission Errors**: Verify IAM roles and policies
- **Service Quota Limits**: Request increases for needed resources

### Application Deployment Issues

- **Container Health Checks**: Verify the application is properly responding to health checks
- **Resource Constraints**: Check for CPU/memory limits
- **Configuration Errors**: Validate environment variables and secrets

### Database Migration Problems

- **Schema Conflicts**: Resolve by reviewing migration scripts
- **Locking Issues**: Schedule migrations during low-traffic periods
- **Rollback Errors**: Ensure backward-compatible changes when possible

### Logging and Debugging

Access logs to diagnose issues:

```bash
# View ECS container logs
aws logs get-log-events --log-group-name /ecs/smartsphere --log-stream-name <CONTAINER_ID>

# View deployment logs
aws deploy get-deployment --deployment-id <DEPLOYMENT_ID>

# View ALB access logs
aws s3 cp s3://smartsphere-logs/alb/ ./alb-logs/ --recursive
```

For additional assistance, refer to AWS documentation or contact the DevOps team.

---

## Appendix: Useful Commands

```bash
# Check deployment status
./scripts/deployment-status.sh

# View cost prediction for the deployment
./scripts/cost-prediction.sh

# Generate security compliance report
./scripts/compliance-report.sh

# Create infrastructure visualization
./scripts/generate-topology.sh

# Generate deployment health dashboard
./scripts/generate-dashboard.sh
```