# SmartSphere Architecture

## Overview

SmartSphere is deployed on AWS using a modern, scalable architecture designed for high availability, security, and performance. The infrastructure is managed through Terraform to ensure consistency and reproducibility across environments.

## Architecture Components

### Infrastructure as Code

All infrastructure is defined as code using Terraform. This ensures:

- Reproducible deployments
- Version-controlled infrastructure
- Consistent environments (dev, staging, prod)
- Automated provisioning and scaling

### Network Architecture

![Network Architecture](./images/network-diagram.png)

- **VPC**: Isolated network for the application
- **Public Subnets**: For ALB and NAT Gateways
- **Private Subnets**: For application containers and database
- **Database Subnets**: Isolated for RDS instances
- **NAT Gateways**: Provide internet access to private subnets

### Compute Layer

- **ECS Fargate**: Serverless container orchestration
  - Automatic scaling based on CPU, memory, and request metrics
  - Zero-downtime deployments with blue/green strategy
  - Task-level security isolation

### Database Layer

- **RDS PostgreSQL**: Managed relational database
  - Multi-AZ deployment for high availability (in production)
  - Automated backups and point-in-time recovery
  - Encryption at rest and in transit

### Storage Layer

- **S3 Buckets**:
  - Frontend assets (static files)
  - Application data (user uploads, generated content)
  - Access logs
  - Terraform state

### Content Delivery

- **CloudFront**: Global content delivery network
  - Edge caching for improved performance
  - HTTPS enforcement
  - DDoS protection
  - Custom domain support

### Security

- **WAF**: Web Application Firewall for protection against common attacks
- **Security Groups**: Granular network security controls
- **IAM Roles**: Principle of least privilege for all components
- **KMS**: Key management for encryption
- **Secrets Manager**: Secure storage of credentials
- **SSL/TLS**: Encryption for all data in transit

## CI/CD Pipeline

![CI/CD Pipeline](./images/cicd-diagram.png)

The CI/CD pipeline is implemented using GitHub Actions:

1. **CI Pipeline**:
   - Code linting and formatting
   - Unit and integration testing
   - Security scanning (Trivy)
   - Docker image building and scanning
   - Infrastructure validation

2. **CD Pipeline**:
   - Automated deployments to appropriate environment
   - Blue/green deployment strategy for zero-downtime updates
   - Post-deployment testing and verification
   - CloudFront cache invalidation

## Monitoring and Observability

- **CloudWatch**:
  - Centralized logging
  - Custom metrics and dashboards
  - Alarms for critical thresholds
  - Automated notification via SNS

- **X-Ray**:
  - Distributed tracing
  - Service maps
  - Performance analysis

## Environment Strategy

SmartSphere uses three distinct environments:

1. **Development (dev)**:
   - For ongoing development work
   - Minimal resources for cost optimization
   - Frequent deployments

2. **Staging (staging)**:
   - Mirror of production for testing
   - Pre-release verification
   - Performance testing

3. **Production (prod)**:
   - Customer-facing environment
   - Maximum reliability and security
   - Controlled release process

## Disaster Recovery

- **Backup Strategy**:
  - Automated RDS backups (daily)
  - S3 versioning and cross-region replication
  - Database point-in-time recovery

- **High Availability**:
  - Multi-AZ deployments
  - Load balancing across availability zones
  - Automatic failover for database

## Cost Optimization

- **Auto-scaling**: Resources scale based on demand
- **Spot Instances**: Used for non-critical workloads
- **Resource right-sizing**: Appropriate instance sizes for each environment
- **S3 Lifecycle Policies**: Automatic transition to lower-cost storage tiers

## Future Enhancements

- Multi-region deployments for global redundancy
- Enhanced blue/green deployments with canary testing
- Integration with AWS Config for compliance monitoring
- Expanded security scanning and automated remediation