// AWS Lambda function for aggregating security findings from multiple sources
const AWS = require('aws-sdk');
const s3 = new AWS.S3();
const sns = new AWS.SNS();
const inspector = new AWS.Inspector2();
const guardduty = new AWS.GuardDuty();
const securityhub = new AWS.SecurityHub();
const cloudwatch = new AWS.CloudWatch();

// Get environment variables
const outputBucket = process.env.OUTPUT_BUCKET;
const reportsPrefix = process.env.REPORTS_PREFIX;
const snsTopicArn = process.env.SNS_TOPIC_ARN;
const projectName = process.env.PROJECT_NAME;
const environment = process.env.ENVIRONMENT;
const alertSeverities = JSON.parse(process.env.ALERT_SEVERITIES || '["CRITICAL", "HIGH"]');

// Severity mapping for normalization
const severityMapping = {
  // GuardDuty
  'Low': 'LOW',
  'Medium': 'MEDIUM',
  'High': 'HIGH',
  // Inspector
  'INFORMATIONAL': 'INFO',
  'LOW': 'LOW',
  'MEDIUM': 'MEDIUM',
  'HIGH': 'HIGH',
  'CRITICAL': 'CRITICAL',
  // Security Hub
  'INFORMATIONAL': 'INFO',
  'LOW': 'LOW',
  'MEDIUM': 'MEDIUM',
  'HIGH': 'HIGH',
  'CRITICAL': 'CRITICAL',
};

exports.handler = async (event) => {
  try {
    console.log('Starting security findings aggregation');
    
    // Initialize findings counter
    const findingCounts = {
      total: 0,
      bySeverity: {
        CRITICAL: 0,
        HIGH: 0,
        MEDIUM: 0,
        LOW: 0,
        INFO: 0
      },
      bySource: {
        Inspector: 0,
        GuardDuty: 0,
        SecurityHub: 0,
        Prowler: 0
      },
      byCategory: {
        Network: 0,
        IAM: 0,
        Data: 0,
        Compute: 0,
        Other: 0
      }
    };
    
    // Collect security findings
    const allFindings = await collectSecurityFindings();
    
    // Process and categorize findings
    const processedFindings = processFindings(allFindings, findingCounts);
    
    // Generate comprehensive security report
    const report = generateSecurityReport(processedFindings, findingCounts);
    
    // Upload report to S3
    const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
    const reportKey = `${reportsPrefix}/security-report-${timestamp}.json`;
    
    await s3.putObject({
      Bucket: outputBucket,
      Key: reportKey,
      Body: JSON.stringify(report, null, 2),
      ContentType: 'application/json'
    }).promise();
    
    console.log(`Uploaded security report to s3://${outputBucket}/${reportKey}`);
    
    // Publish metrics to CloudWatch
    await publishMetrics(findingCounts);
    
    // Send notification if critical or high findings are present
    if (findingCounts.bySeverity.CRITICAL > 0 || findingCounts.bySeverity.HIGH > 0) {
      await sendNotification(report, findingCounts);
    }
    
    return {
      statusCode: 200,
      body: JSON.stringify({
        message: 'Security findings aggregation completed successfully',
        reportLocation: `s3://${outputBucket}/${reportKey}`,
        findingCounts
      })
    };
  } catch (error) {
    console.error('Error in security findings aggregation:', error);
    throw error;
  }
};

// Collect security findings from multiple sources
async function collectSecurityFindings() {
  const findings = {
    inspector: await getInspectorFindings(),
    guardduty: await getGuardDutyFindings(),
    securityhub: await getSecurityHubFindings(),
    prowler: await getProwlerFindings()
  };
  
  return findings;
}

// Get findings from Amazon Inspector
async function getInspectorFindings() {
  try {
    const findings = [];
    let nextToken = null;
    
    // Filter for findings in the last 24 hours
    const yesterday = new Date();
    yesterday.setDate(yesterday.getDate() - 1);
    
    do {
      const params = {
        filterCriteria: {
          createdAt: [{
            startInclusive: yesterday,
            endInclusive: new Date()
          }]
        },
        maxResults: 100
      };
      
      if (nextToken) {
        params.nextToken = nextToken;
      }
      
      const response = await inspector.listFindings(params).promise();
      findings.push(...response.findings);
      nextToken = response.nextToken;
    } while (nextToken);
    
    return findings;
  } catch (error) {
    console.error('Error getting Inspector findings:', error);
    return [];
  }
}

// Get findings from GuardDuty
async function getGuardDutyFindings() {
  try {
    // Get GuardDuty detector ID
    const detectors = await guardduty.listDetectors().promise();
    if (!detectors.DetectorIds || detectors.DetectorIds.length === 0) {
      console.log('No GuardDuty detectors found');
      return [];
    }
    
    const detectorId = detectors.DetectorIds[0];
    const findings = [];
    let nextToken = null;
    
    // Filter for findings in the last 24 hours
    const yesterday = new Date();
    yesterday.setDate(yesterday.getDate() - 1);
    
    do {
      const params = {
        DetectorId: detectorId,
        FindingCriteria: {
          Criterion: {
            'updatedAt': {
              'GreaterThanOrEqual': yesterday.toISOString()
            }
          }
        },
        MaxResults: 50
      };
      
      if (nextToken) {
        params.NextToken = nextToken;
      }
      
      const response = await guardduty.listFindings(params).promise();
      
      if (response.FindingIds && response.FindingIds.length > 0) {
        const findingDetails = await guardduty.getFindings({
          DetectorId: detectorId,
          FindingIds: response.FindingIds
        }).promise();
        
        findings.push(...findingDetails.Findings);
      }
      
      nextToken = response.NextToken;
    } while (nextToken);
    
    return findings;
  } catch (error) {
    console.error('Error getting GuardDuty findings:', error);
    return [];
  }
}

// Get findings from Security Hub
async function getSecurityHubFindings() {
  try {
    const findings = [];
    let nextToken = null;
    
    // Filter for findings in the last 24 hours
    const yesterday = new Date();
    yesterday.setDate(yesterday.getDate() - 1);
    
    do {
      const params = {
        Filters: {
          UpdatedAt: [{
            Start: yesterday.toISOString(),
            End: new Date().toISOString()
          }]
        },
        MaxResults: 100
      };
      
      if (nextToken) {
        params.NextToken = nextToken;
      }
      
      const response = await securityhub.getFindings(params).promise();
      findings.push(...response.Findings);
      nextToken = response.NextToken;
    } while (nextToken);
    
    return findings;
  } catch (error) {
    console.error('Error getting Security Hub findings:', error);
    return [];
  }
}

// Get findings from Prowler (from S3)
async function getProwlerFindings() {
  try {
    // List the latest Prowler reports in S3
    const objects = await s3.listObjectsV2({
      Bucket: outputBucket,
      Prefix: `security-findings/prowler/`,
      MaxKeys: 10
    }).promise();
    
    if (!objects.Contents || objects.Contents.length === 0) {
      console.log('No Prowler findings found in S3');
      return [];
    }
    
    // Get the most recent Prowler report
    const sortedObjects = objects.Contents.sort((a, b) => 
      new Date(b.LastModified) - new Date(a.LastModified)
    );
    
    const latestReport = await s3.getObject({
      Bucket: outputBucket,
      Key: sortedObjects[0].Key
    }).promise();
    
    return JSON.parse(latestReport.Body.toString());
  } catch (error) {
    console.error('Error getting Prowler findings:', error);
    return [];
  }
}

// Process and normalize findings from different sources
function processFindings(allFindings, findingCounts) {
  const processedFindings = [];
  
  // Process Inspector findings
  if (allFindings.inspector && allFindings.inspector.length > 0) {
    allFindings.inspector.forEach(finding => {
      findingCounts.total++;
      findingCounts.bySource.Inspector++;
      
      const normalizedSeverity = severityMapping[finding.severity] || 'MEDIUM';
      findingCounts.bySeverity[normalizedSeverity]++;
      
      // Categorize finding
      if (finding.title.toLowerCase().includes('network') || 
          finding.title.toLowerCase().includes('firewall') ||
          finding.title.toLowerCase().includes('security group')) {
        findingCounts.byCategory.Network++;
      } else if (finding.title.toLowerCase().includes('iam') || 
                finding.title.toLowerCase().includes('permission') ||
                finding.title.toLowerCase().includes('role')) {
        findingCounts.byCategory.IAM++;
      } else if (finding.title.toLowerCase().includes('s3') || 
                finding.title.toLowerCase().includes('rds') ||
                finding.title.toLowerCase().includes('database')) {
        findingCounts.byCategory.Data++;
      } else if (finding.title.toLowerCase().includes('ec2') || 
                finding.title.toLowerCase().includes('container') ||
                finding.title.toLowerCase().includes('ecs') ||
                finding.title.toLowerCase().includes('kubernetes')) {
        findingCounts.byCategory.Compute++;
      } else {
        findingCounts.byCategory.Other++;
      }
      
      // Normalize finding format
      processedFindings.push({
        id: finding.findingArn,
        title: finding.title,
        description: finding.description,
        severity: normalizedSeverity,
        resource: finding.resources[0]?.id || 'Unknown',
        source: 'Amazon Inspector',
        createdAt: finding.createdAt,
        remediation: finding.remediation?.recommendation?.text || 'No specific remediation provided'
      });
    });
  }
  
  // Process GuardDuty findings
  if (allFindings.guardduty && allFindings.guardduty.length > 0) {
    allFindings.guardduty.forEach(finding => {
      findingCounts.total++;
      findingCounts.bySource.GuardDuty++;
      
      const normalizedSeverity = severityMapping[finding.Severity.Label] || 'MEDIUM';
      findingCounts.bySeverity[normalizedSeverity]++;
      
      // Categorize finding
      if (finding.Type.includes('UnauthorizedAccess') || 
          finding.Type.includes('Recon') ||
          finding.Type.includes('NetworkAnomaly')) {
        findingCounts.byCategory.Network++;
      } else if (finding.Type.includes('IAMUser') || 
                finding.Type.includes('CredentialAccess') ||
                finding.Type.includes('Stealth')) {
        findingCounts.byCategory.IAM++;
      } else if (finding.Type.includes('Discovery') || 
                finding.Type.includes('Exfiltration') ||
                finding.Type.includes('DataExfiltration')) {
        findingCounts.byCategory.Data++;
      } else if (finding.Type.includes('EC2') || 
                finding.Type.includes('Execution') ||
                finding.Type.includes('Backdoor')) {
        findingCounts.byCategory.Compute++;
      } else {
        findingCounts.byCategory.Other++;
      }
      
      // Normalize finding format
      processedFindings.push({
        id: finding.Id,
        title: finding.Title,
        description: finding.Description,
        severity: normalizedSeverity,
        resource: Object.values(finding.Resource || {})[0]?.Id || 'Unknown',
        source: 'Amazon GuardDuty',
        createdAt: finding.CreatedAt,
        remediation: finding.Service?.ActionDescription || 'No specific remediation provided'
      });
    });
  }
  
  // Process Security Hub findings (similarly to above)
  if (allFindings.securityhub && allFindings.securityhub.length > 0) {
    allFindings.securityhub.forEach(finding => {
      findingCounts.total++;
      findingCounts.bySource.SecurityHub++;
      
      const normalizedSeverity = severityMapping[finding.Severity.Label] || 'MEDIUM';
      findingCounts.bySeverity[normalizedSeverity]++;
      
      // Categorize finding
      if (finding.Types.some(t => t.includes('Network') || t.includes('Firewall'))) {
        findingCounts.byCategory.Network++;
      } else if (finding.Types.some(t => t.includes('IAM') || t.includes('Identity'))) {
        findingCounts.byCategory.IAM++;
      } else if (finding.Types.some(t => t.includes('Data') || t.includes('S3') || t.includes('Database'))) {
        findingCounts.byCategory.Data++;
      } else if (finding.Types.some(t => t.includes('EC2') || t.includes('Container') || t.includes('Compute'))) {
        findingCounts.byCategory.Compute++;
      } else {
        findingCounts.byCategory.Other++;
      }
      
      // Normalize finding format
      processedFindings.push({
        id: finding.Id,
        title: finding.Title,
        description: finding.Description,
        severity: normalizedSeverity,
        resource: finding.Resources[0]?.Id || 'Unknown',
        source: 'AWS Security Hub',
        createdAt: finding.CreatedAt,
        remediation: finding.Remediation?.Recommendation?.Text || 'No specific remediation provided'
      });
    });
  }
  
  // Process Prowler findings (if available and in the expected format)
  if (allFindings.prowler && allFindings.prowler.length > 0) {
    allFindings.prowler.forEach(finding => {
      findingCounts.total++;
      findingCounts.bySource.Prowler++;
      
      // Map Prowler severity to normalized severity
      let normalizedSeverity;
      if (finding.risk === 'Critical' || finding.risk === 'High') {
        normalizedSeverity = 'HIGH';
      } else if (finding.risk === 'Medium') {
        normalizedSeverity = 'MEDIUM';
      } else {
        normalizedSeverity = 'LOW';
      }
      
      findingCounts.bySeverity[normalizedSeverity]++;
      
      // Categorize finding based on Prowler check
      if (finding.check_id.includes('network') || finding.check_id.includes('vpc') || finding.check_id.includes('sg')) {
        findingCounts.byCategory.Network++;
      } else if (finding.check_id.includes('iam') || finding.check_id.includes('role') || finding.check_id.includes('user')) {
        findingCounts.byCategory.IAM++;
      } else if (finding.check_id.includes('s3') || finding.check_id.includes('rds') || finding.check_id.includes('data')) {
        findingCounts.byCategory.Data++;
      } else if (finding.check_id.includes('ec2') || finding.check_id.includes('ecs') || finding.check_id.includes('eks')) {
        findingCounts.byCategory.Compute++;
      } else {
        findingCounts.byCategory.Other++;
      }
      
      // Normalize finding format
      processedFindings.push({
        id: finding.check_id,
        title: finding.check_title,
        description: finding.check_description,
        severity: normalizedSeverity,
        resource: finding.resource_id || 'Unknown',
        source: 'Prowler',
        createdAt: finding.timestamp || new Date().toISOString(),
        remediation: finding.remediation || 'No specific remediation provided'
      });
    });
  }
  
  return processedFindings;
}

// Generate a comprehensive security report
function generateSecurityReport(findings, findingCounts) {
  // Calculate the security score based on findings
  const securityScore = calculateSecurityScore(findingCounts);
  
  // Generate remediation recommendations
  const recommendations = generateRecommendations(findings);
  
  // Create the comprehensive report
  const report = {
    reportGeneratedAt: new Date().toISOString(),
    projectName,
    environment,
    summary: {
      totalFindings: findingCounts.total,
      findingsBySeverity: findingCounts.bySeverity,
      findingsBySource: findingCounts.bySource,
      findingsByCategory: findingCounts.byCategory,
      securityScore
    },
    criticalAndHighFindings: findings.filter(f => 
      ['CRITICAL', 'HIGH'].includes(f.severity)
    ),
    recommendations,
    allFindings: findings
  };
  
  return report;
}

// Calculate a security score based on findings
function calculateSecurityScore(findingCounts) {
  // Base score starts at 100
  let score = 100;
  
  // Deduct points based on finding severity and count
  // Critical findings have the most impact
  score -= findingCounts.bySeverity.CRITICAL * 10;
  score -= findingCounts.bySeverity.HIGH * 5;
  score -= findingCounts.bySeverity.MEDIUM * 2;
  score -= findingCounts.bySeverity.LOW * 0.5;
  
  // Ensure score stays within 0-100 range
  return Math.max(0, Math.min(100, score));
}

// Generate prioritized remediation recommendations
function generateRecommendations(findings) {
  const recommendations = [];
  
  // Prioritize Critical and High severity findings
  const priorityFindings = findings
    .filter(f => ['CRITICAL', 'HIGH'].includes(f.severity))
    .sort((a, b) => {
      // Sort by severity (CRITICAL before HIGH)
      if (a.severity !== b.severity) {
        return a.severity === 'CRITICAL' ? -1 : 1;
      }
      // Then by source (with a preferred order)
      const sourceOrder = { 'Amazon Inspector': 1, 'Amazon GuardDuty': 2, 'AWS Security Hub': 3, 'Prowler': 4 };
      return (sourceOrder[a.source] || 5) - (sourceOrder[b.source] || 5);
    });
  
  // Group similar findings
  const groupedFindings = {};
  priorityFindings.forEach(finding => {
    // Create a simple key based on title
    const key = finding.title.replace(/[^a-zA-Z0-9]/g, '').toLowerCase();
    if (!groupedFindings[key]) {
      groupedFindings[key] = [];
    }
    groupedFindings[key].push(finding);
  });
  
  // Generate recommendations for each group
  Object.values(groupedFindings).forEach(group => {
    if (group.length > 0) {
      const primaryFinding = group[0];
      
      recommendations.push({
        title: primaryFinding.title,
        severity: primaryFinding.severity,
        affectedResources: group.map(f => f.resource).filter((v, i, a) => a.indexOf(v) === i), // Unique resources
        recommendedAction: primaryFinding.remediation,
        source: primaryFinding.source,
        count: group.length
      });
    }
  });
  
  return recommendations;
}

// Publish metrics to CloudWatch
async function publishMetrics(findingCounts) {
  try {
    const timestamp = new Date();
    const metricData = [
      {
        MetricName: 'TotalFindings',
        Dimensions: [
          { Name: 'Project', Value: projectName },
          { Name: 'Environment', Value: environment }
        ],
        Value: findingCounts.total,
        Unit: 'Count',
        Timestamp: timestamp
      },
      {
        MetricName: 'CriticalFindings',
        Dimensions: [
          { Name: 'Project', Value: projectName },
          { Name: 'Environment', Value: environment }
        ],
        Value: findingCounts.bySeverity.CRITICAL,
        Unit: 'Count',
        Timestamp: timestamp
      },
      {
        MetricName: 'HighFindings',
        Dimensions: [
          { Name: 'Project', Value: projectName },
          { Name: 'Environment', Value: environment }
        ],
        Value: findingCounts.bySeverity.HIGH,
        Unit: 'Count',
        Timestamp: timestamp
      },
      {
        MetricName: 'MediumFindings',
        Dimensions: [
          { Name: 'Project', Value: projectName },
          { Name: 'Environment', Value: environment }
        ],
        Value: findingCounts.bySeverity.MEDIUM,
        Unit: 'Count',
        Timestamp: timestamp
      },
      {
        MetricName: 'LowFindings',
        Dimensions: [
          { Name: 'Project', Value: projectName },
          { Name: 'Environment', Value: environment }
        ],
        Value: findingCounts.bySeverity.LOW,
        Unit: 'Count',
        Timestamp: timestamp
      },
      {
        MetricName: 'InspectorFindings',
        Dimensions: [
          { Name: 'Project', Value: projectName },
          { Name: 'Environment', Value: environment }
        ],
        Value: findingCounts.bySource.Inspector,
        Unit: 'Count',
        Timestamp: timestamp
      },
      {
        MetricName: 'GuardDutyFindings',
        Dimensions: [
          { Name: 'Project', Value: projectName },
          { Name: 'Environment', Value: environment }
        ],
        Value: findingCounts.bySource.GuardDuty,
        Unit: 'Count',
        Timestamp: timestamp
      },
      {
        MetricName: 'SecurityHubFindings',
        Dimensions: [
          { Name: 'Project', Value: projectName },
          { Name: 'Environment', Value: environment }
        ],
        Value: findingCounts.bySource.SecurityHub,
        Unit: 'Count',
        Timestamp: timestamp
      },
      {
        MetricName: 'ProwlerFindings',
        Dimensions: [
          { Name: 'Project', Value: projectName },
          { Name: 'Environment', Value: environment }
        ],
        Value: findingCounts.bySource.Prowler,
        Unit: 'Count',
        Timestamp: timestamp
      },
      {
        MetricName: 'NetworkFindings',
        Dimensions: [
          { Name: 'Project', Value: projectName },
          { Name: 'Environment', Value: environment }
        ],
        Value: findingCounts.byCategory.Network,
        Unit: 'Count',
        Timestamp: timestamp
      },
      {
        MetricName: 'IAMFindings',
        Dimensions: [
          { Name: 'Project', Value: projectName },
          { Name: 'Environment', Value: environment }
        ],
        Value: findingCounts.byCategory.IAM,
        Unit: 'Count',
        Timestamp: timestamp
      },
      {
        MetricName: 'DataFindings',
        Dimensions: [
          { Name: 'Project', Value: projectName },
          { Name: 'Environment', Value: environment }
        ],
        Value: findingCounts.byCategory.Data,
        Unit: 'Count',
        Timestamp: timestamp
      },
      {
        MetricName: 'ComputeFindings',
        Dimensions: [
          { Name: 'Project', Value: projectName },
          { Name: 'Environment', Value: environment }
        ],
        Value: findingCounts.byCategory.Compute,
        Unit: 'Count',
        Timestamp: timestamp
      },
      {
        MetricName: 'SecurityScore',
        Dimensions: [
          { Name: 'Project', Value: projectName },
          { Name: 'Environment', Value: environment }
        ],
        Value: calculateSecurityScore(findingCounts),
        Unit: 'None',
        Timestamp: timestamp
      }
    ];
    
    // CloudWatch allows up to 20 metrics per request
    for (let i = 0; i < metricData.length; i += 20) {
      const batch = metricData.slice(i, i + 20);
      
      await cloudwatch.putMetricData({
        Namespace: `${projectName}/${environment}`,
        MetricData: batch
      }).promise();
    }
    
    console.log(`Published ${metricData.length} metrics to CloudWatch`);
  } catch (error) {
    console.error('Error publishing metrics to CloudWatch:', error);
  }
}

// Send notification for critical and high findings
async function sendNotification(report, findingCounts) {
  try {
    // Generate a summary message
    const criticalCount = findingCounts.bySeverity.CRITICAL;
    const highCount = findingCounts.bySeverity.HIGH;
    
    const message = `
SECURITY ALERT: ${criticalCount} Critical and ${highCount} High severity findings detected

Project: ${projectName}
Environment: ${environment}
Security Score: ${calculateSecurityScore(findingCounts)}/100
Report Time: ${new Date().toISOString()}

Top Recommendations:
${report.recommendations.slice(0, 5).map(rec => 
  `- ${rec.severity} [${rec.source}]: ${rec.title} (${rec.count} finding${rec.count > 1 ? 's' : ''})`
).join('\n')}

Total Findings by Severity:
- Critical: ${criticalCount}
- High: ${highCount}
- Medium: ${findingCounts.bySeverity.MEDIUM}
- Low: ${findingCounts.bySeverity.LOW}
- Info: ${findingCounts.bySeverity.INFO}

Total Findings by Category:
- Network: ${findingCounts.byCategory.Network}
- IAM: ${findingCounts.byCategory.IAM}
- Data: ${findingCounts.byCategory.Data}
- Compute: ${findingCounts.byCategory.Compute}
- Other: ${findingCounts.byCategory.Other}

A detailed report has been uploaded to:
s3://${outputBucket}/${reportsPrefix}/security-report-${new Date().toISOString().replace(/[:.]/g, '-')}.json
`;
    
    // Send SNS notification
    await sns.publish({
      TopicArn: snsTopicArn,
      Subject: `[${environment.toUpperCase()}] Security Alert - ${criticalCount} Critical, ${highCount} High Findings`,
      Message: message
    }).promise();
    
    console.log('Security notification sent successfully');
  } catch (error) {
    console.error('Error sending security notification:', error);
  }
}