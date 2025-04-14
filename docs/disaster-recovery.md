# SmartSphere Disaster Recovery Plan

This document outlines the disaster recovery procedures and strategies for the SmartSphere infrastructure.

## Recovery Objectives

### Recovery Time Objective (RTO)

| Environment | RTO             |
|-------------|-----------------|
| Production  | 1 hour          |
| Staging     | 4 hours         |
| Development | 24 hours        |

### Recovery Point Objective (RPO)

| Environment | RPO             |
|-------------|-----------------|
| Production  | 15 minutes      |
| Staging     | 1 hour          |
| Development | 24 hours        |

## Backup Strategy

### Database Backups

#### RDS PostgreSQL

- **Automated Snapshots**: Daily snapshots retained for 35 days
- **Continuous Backup**: Point-in-time recovery enabled with 5-minute increments
- **Snapshot Copies**: Cross-region copies for critical environments
- **Automated Testing**: Monthly restore testing

Configuration in Terraform:
```hcl
resource "aws_db_instance" "main" {
  # ... other configuration
  backup_retention_period    = 35
  backup_window              = "03:00-05:00"
  copy_tags_to_snapshot      = true
  deletion_protection        = true
  enabled_cloudwatch_logs_exports = ["postgresql", "upgrade"]
  performance_insights_enabled = true
  storage_encrypted          = true
}
```

### Object Storage Backups

#### S3 Buckets

- **Versioning**: Enabled on all buckets
- **Cross-Region Replication**: For production buckets
- **Lifecycle Policies**: For cost-effective retention
- **Object Lock**: For critical data (WORM protection)

Configuration in Terraform:
```hcl
resource "aws_s3_bucket" "main" {
  # ... other configuration
  
  versioning {
    enabled = true
  }
}

resource "aws_s3_bucket_replication_configuration" "main" {
  # Cross-region replication configuration
}
```

### Configuration Backups

- **Terraform State**: Versioned and replicated
- **Configuration Data**: Stored in version control
- **Secrets**: Backed up in AWS Secrets Manager with encryption

### Application Backups

- **Container Images**: Replicated across regions in ECR
- **Deployment Artifacts**: Stored with versioning
- **Pipeline Definitions**: Stored in version control

## High Availability Architecture

### Multi-AZ Deployments

- **RDS**: Multi-AZ for automatic failover
- **ECS Services**: Spread across multiple AZs
- **ALB**: Multi-AZ for load balancer resilience
- **NAT Gateways**: One per AZ in production

### Multi-Region Strategy

![Multi-Region Architecture](./images/multi-region-diagram.png)

#### Primary Region

- Active production workloads
- Full application stack
- Primary database instances

#### Secondary Region

- Replicated database
- Pre-provisioned infrastructure
- Reduced capacity (warm standby)
- Synchronized configuration

#### Global Services

- **Route 53**: DNS with health checks and failover routing
- **CloudFront**: Global content delivery
- **DynamoDB Global Tables**: Multi-region data replication
- **S3 Cross-Region Replication**: For critical buckets

## Disaster Recovery Procedures

### Failover Scenarios

#### Database Failover

1. **Automated RDS Failover**:
   - Monitors for primary instance failure
   - Promotes standby to primary
   - Updates DNS endpoint
   - Typically completes in 60-120 seconds

2. **Manual Cross-Region Failover**:
   - Promote read replica to master
   - Update application configuration
   - Execute using: `./scripts/db-failover.sh <region>`

#### Application Failover

1. **Zone Failure**:
   - Auto scaling group spreads to available zones
   - ALB routes traffic to healthy instances
   - No manual intervention required

2. **Region Failure**:
   - Execute cross-region failover script
   - Update Route 53 records
   - Scale up secondary region capacity
   - Execute using: `./scripts/region-failover.sh <primary-region> <secondary-region>`

### Recovery Procedures

#### Database Recovery

1. From automated snapshot:
   ```bash
   ./scripts/restore-db.sh --snapshot-id <snapshot-id> --target-instance <instance-id>
   ```

2. Point-in-time recovery:
   ```bash
   ./scripts/restore-db.sh --time "2025-04-10T15:30:00Z" --target-instance <instance-id>
   ```

#### Infrastructure Recovery

Complete infrastructure recreation:
```bash
./scripts/recover-environment.sh <environment> <region>
```

This script:
1. Initializes Terraform
2. Creates core infrastructure
3. Restores data from backups
4. Validates the deployment

### Communication Plan

| Role              | Responsibility                                     | Contact Method     |
|-------------------|----------------------------------------------------|-------------------|
| Incident Manager  | Overall coordination of recovery efforts           | Slack, Phone      |
| Database Engineer | Database restoration and verification              | Slack, Email      |
| DevOps Engineer   | Infrastructure and application deployment          | Slack, Email      |
| Communications    | Stakeholder and customer communications            | Email, Phone      |

### Escalation Path

1. Automated monitoring detects issue
2. On-call engineer notified
3. Incident manager engaged for major incidents
4. Executive notification for critical failures

## Testing and Validation

### Scheduled Testing

| Test Type               | Frequency | Last Performed | Next Scheduled |
|-------------------------|-----------|----------------|----------------|
| Database Restore        | Monthly   | 2025-03-15     | 2025-04-15     |
| Zone Failover           | Quarterly | 2025-02-01     | 2025-05-01     |
| Full Region Failover    | Bi-annual | 2025-01-10     | 2025-07-10     |
| Disaster Recovery Drill | Annual    | 2024-12-05     | 2025-12-05     |

### Testing Procedures

1. **Database Restore Test**:
   ```bash
   ./scripts/test-db-restore.sh
   ```

2. **Zone Failover Test**:
   ```bash
   ./scripts/test-zone-failover.sh
   ```

3. **Region Failover Test**:
   ```bash
   ./scripts/test-region-failover.sh
   ```

## Continuous Improvement

### Post-Incident Review

After each incident or test:
1. Document timeline and actions taken
2. Identify improvement opportunities
3. Update recovery procedures
4. Adjust architecture if needed

### Monitoring Improvements

Continuous enhancement of observability:
- Early warning indicators
- Automated recovery procedures
- Chaos engineering practices

## Appendices

### Recovery Runbooks

- [Database Recovery Runbook](./runbooks/database-recovery.md)
- [Application Recovery Runbook](./runbooks/application-recovery.md)
- [Network Failure Runbook](./runbooks/network-failure.md)
- [Security Incident Runbook](./runbooks/security-incident.md)

### Backup Inventory

| Resource Type | Backup Method | Retention | Frequency | Location |
|---------------|---------------|-----------|-----------|----------|
| RDS Database  | Snapshots     | 35 days   | Daily     | Same region + cross-region |
| S3 Data       | Versioning    | Indefinite| Real-time | Cross-region replication |
| ECR Images    | Replication   | 90 days   | On push   | Secondary region |
| Terraform State | Versioning  | Indefinite| On change | S3 with replication |

### Recovery Time Estimates

| Scenario              | Estimated Recovery Time | Validation Method |
|-----------------------|-------------------------|------------------|
| Single AZ failure     | < 5 minutes             | Chaos testing    |
| Database failure      | 15-30 minutes           | Failover testing |
| Region failure        | 45-60 minutes           | DR drill         |
| Complete rebuild      | 4-8 hours               | Annual DR test   |