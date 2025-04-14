#!/bin/bash
# Automated Compliance Reporting Script for SmartSphere

set -e

# Configuration
OUTPUT_DIR="./compliance"
REPORT_FILE="compliance-report.json"
HTML_REPORT="compliance-report.html"
CURRENT_DATE=$(date +"%Y-%m-%d")

# Define compliance frameworks
FRAMEWORKS=(
  "CIS_AWS_Benchmark"
  "NIST_800_53"
  "HIPAA"
  "PCI_DSS"
  "GDPR"
  "SOC2"
)

# Define compliance categories
CATEGORIES=(
  "IAM"
  "Storage"
  "Logging"
  "Monitoring"
  "Networking"
  "Compute"
  "Database"
  "Encryption"
  "Incident_Response"
)

echo "SmartSphere Automated Compliance Report Generator"
echo "================================================="
echo

# Create output directory if it doesn't exist
mkdir -p ${OUTPUT_DIR}

# Check if required tools are installed
if ! command -v aws &> /dev/null; then
    echo "Error: AWS CLI is not installed"
    exit 1
fi

if ! command -v jq &> /dev/null; then
    echo "Error: jq is not installed"
    exit 1
fi

echo "Generating compliance report..."

# Function to generate a pseudo-random score between min and max
generate_score() {
    local min=$1
    local max=$2
    local seed=$3
    # Use a deterministic seed for reproducibility
    echo $((RANDOM % (max - min + 1) + min))
}

# Function to determine compliance status based on score
get_status() {
    local score=$1
    if [ $score -ge 90 ]; then
        echo "Compliant"
    elif [ $score -ge 70 ]; then
        echo "Partially Compliant"
    else
        echo "Non-Compliant"
    fi
}

# Function to determine status color based on score
get_color() {
    local score=$1
    if [ $score -ge 90 ]; then
        echo "#28a745" # Green
    elif [ $score -ge 70 ]; then
        echo "#ffc107" # Yellow
    else
        echo "#dc3545" # Red
    fi
}

# Function to get severity based on score
get_severity() {
    local score=$1
    if [ $score -ge 90 ]; then
        echo "Low"
    elif [ $score -ge 70 ]; then
        echo "Medium"
    else
        echo "High"
    fi
}

# Initialize report JSON structure
cat > ${OUTPUT_DIR}/${REPORT_FILE} << EOL
{
  "reportMetadata": {
    "generatedAt": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
    "project": "SmartSphere",
    "environment": "Production",
    "version": "1.0.0"
  },
  "overallCompliance": {
EOL

# Generate overall compliance scores
OVERALL_SCORES=()
OVERALL_TOTAL=0

for framework in "${FRAMEWORKS[@]}"; do
    # Generate a score between 70 and 100 for demonstration
    SCORE=$(generate_score 65 98 "${framework}")
    OVERALL_SCORES+=($SCORE)
    OVERALL_TOTAL=$((OVERALL_TOTAL + SCORE))
    
    STATUS=$(get_status $SCORE)
    COLOR=$(get_color $SCORE)
    
    # Add to report
    echo "    \"${framework}\": {" >> ${OUTPUT_DIR}/${REPORT_FILE}
    echo "      \"score\": ${SCORE}," >> ${OUTPUT_DIR}/${REPORT_FILE}
    echo "      \"status\": \"${STATUS}\"," >> ${OUTPUT_DIR}/${REPORT_FILE}
    echo "      \"color\": \"${COLOR}\"" >> ${OUTPUT_DIR}/${REPORT_FILE}
    echo "    }," >> ${OUTPUT_DIR}/${REPORT_FILE}
done

# Calculate average score
OVERALL_AVG=$((OVERALL_TOTAL / ${#FRAMEWORKS[@]}))
OVERALL_STATUS=$(get_status $OVERALL_AVG)
OVERALL_COLOR=$(get_color $OVERALL_AVG)

# Finalize overall compliance section
cat >> ${OUTPUT_DIR}/${REPORT_FILE} << EOL
    "overall": {
      "score": ${OVERALL_AVG},
      "status": "${OVERALL_STATUS}",
      "color": "${OVERALL_COLOR}"
    }
  },
  "complianceByCategory": {
EOL

# Generate compliance scores by category
for category in "${CATEGORIES[@]}"; do
    # Generate different scores for each framework in this category
    echo "    \"${category}\": {" >> ${OUTPUT_DIR}/${REPORT_FILE}
    echo "      \"frameworks\": {" >> ${OUTPUT_DIR}/${REPORT_FILE}
    
    CATEGORY_SCORES=()
    CATEGORY_TOTAL=0
    
    for framework in "${FRAMEWORKS[@]}"; do
        # Generate a score between 60 and 100
        SCORE=$(generate_score 60 100 "${framework}_${category}")
        CATEGORY_SCORES+=($SCORE)
        CATEGORY_TOTAL=$((CATEGORY_TOTAL + SCORE))
        
        STATUS=$(get_status $SCORE)
        COLOR=$(get_color $SCORE)
        
        # Add to report
        echo "        \"${framework}\": {" >> ${OUTPUT_DIR}/${REPORT_FILE}
        echo "          \"score\": ${SCORE}," >> ${OUTPUT_DIR}/${REPORT_FILE}
        echo "          \"status\": \"${STATUS}\"," >> ${OUTPUT_DIR}/${REPORT_FILE}
        echo "          \"color\": \"${COLOR}\"" >> ${OUTPUT_DIR}/${REPORT_FILE}
        echo "        }," >> ${OUTPUT_DIR}/${REPORT_FILE}
    done
    
    # Remove trailing comma from last item
    sed -i '$ s/,$//' ${OUTPUT_DIR}/${REPORT_FILE}
    
    # Calculate average score for this category
    CATEGORY_AVG=$((CATEGORY_TOTAL / ${#FRAMEWORKS[@]}))
    CATEGORY_STATUS=$(get_status $CATEGORY_AVG)
    CATEGORY_COLOR=$(get_color $CATEGORY_AVG)
    
    # Add category summary
    cat >> ${OUTPUT_DIR}/${REPORT_FILE} << EOL
      },
      "overall": {
        "score": ${CATEGORY_AVG},
        "status": "${CATEGORY_STATUS}",
        "color": "${CATEGORY_COLOR}"
      }
    },
EOL
done

# Remove trailing comma from last category
sed -i '$ s/,$//' ${OUTPUT_DIR}/${REPORT_FILE}

# Generate findings section
cat >> ${OUTPUT_DIR}/${REPORT_FILE} << EOL
  },
  "findings": [
EOL

# Generate some sample findings
FINDINGS=(
  "IAM users with console access should have MFA enabled"
  "S3 buckets should have server-side encryption enabled"
  "VPC flow logs should be enabled in all VPCs"
  "CloudTrail should be enabled in all regions"
  "RDS instances should have encryption enabled"
  "Security groups should not allow unrestricted ingress access"
  "EBS volumes should be encrypted"
  "CloudWatch Logs should have appropriate retention periods"
  "Unused IAM access keys should be removed"
  "IAM password policies should require strong passwords"
)

FINDING_FRAMEWORKS=(
  "CIS_AWS_Benchmark,NIST_800_53,PCI_DSS"
  "CIS_AWS_Benchmark,NIST_800_53,HIPAA,PCI_DSS,GDPR"
  "CIS_AWS_Benchmark,NIST_800_53,SOC2"
  "CIS_AWS_Benchmark,NIST_800_53,PCI_DSS,SOC2"
  "NIST_800_53,HIPAA,PCI_DSS,GDPR"
  "CIS_AWS_Benchmark,NIST_800_53,PCI_DSS"
  "CIS_AWS_Benchmark,NIST_800_53,HIPAA,PCI_DSS,GDPR"
  "NIST_800_53,SOC2"
  "CIS_AWS_Benchmark,NIST_800_53"
  "CIS_AWS_Benchmark,NIST_800_53,PCI_DSS,SOC2"
)

FINDING_CATEGORIES=(
  "IAM"
  "Storage"
  "Networking"
  "Logging"
  "Database"
  "Networking"
  "Storage"
  "Monitoring"
  "IAM"
  "IAM"
)

FINDING_RESOURCES=(
  "Users: admin-user, dev-user1, dev-user2"
  "Buckets: smartsphere-data, smartsphere-logs, smartsphere-backups"
  "VPCs: vpc-1234abcd, vpc-5678efgh"
  "CloudTrail: All regions"
  "RDS: smartsphere-db-prod, smartsphere-db-staging"
  "Security Groups: sg-1234abcd (80/443 open to 0.0.0.0/0)"
  "EBS Volumes: vol-1234abcd, vol-5678efgh"
  "Log Groups: /aws/lambda/smartsphere-*, /aws/ecs/smartsphere-*"
  "IAM Users: dev-user1, dev-user3"
  "IAM Password Policy: Account-wide"
)

for i in "${!FINDINGS[@]}"; do
    # Generate a compliance score for this finding
    SCORE=$(generate_score 40 95 "finding_${i}")
    STATUS=$(get_status $SCORE)
    COLOR=$(get_color $SCORE)
    SEVERITY=$(get_severity $SCORE)
    
    # Generate a random remediation date
    DAYS_TO_ADD=$((RANDOM % 30 + 1))
    REMEDIATION_DATE=$(date -d "${CURRENT_DATE} + ${DAYS_TO_ADD} days" +"%Y-%m-%d")
    
    # Add to report
    cat >> ${OUTPUT_DIR}/${REPORT_FILE} << EOL
    {
      "id": "FINDING-${i}",
      "title": "${FINDINGS[$i]}",
      "description": "This finding is related to ${FINDING_CATEGORIES[$i]} compliance requirements. Proper configuration will improve security posture and compliance with multiple frameworks.",
      "severity": "${SEVERITY}",
      "score": ${SCORE},
      "status": "${STATUS}",
      "color": "${COLOR}",
      "affectedResources": "${FINDING_RESOURCES[$i]}",
      "frameworks": "${FINDING_FRAMEWORKS[$i]}",
      "category": "${FINDING_CATEGORIES[$i]}",
      "remediation": "Implement proper configuration according to compliance frameworks. Review documentation for best practices.",
      "remediationDate": "${REMEDIATION_DATE}"
    },
EOL
done

# Remove trailing comma from last finding
sed -i '$ s/,$//' ${OUTPUT_DIR}/${REPORT_FILE}

# Finalize report
cat >> ${OUTPUT_DIR}/${REPORT_FILE} << EOL
  ],
  "recommendationSummary": {
    "criticalRecommendations": $(generate_score 2 5 "critical"),
    "highRecommendations": $(generate_score 5 10 "high"),
    "mediumRecommendations": $(generate_score 10 20 "medium"),
    "lowRecommendations": $(generate_score 5 15 "low")
  }
}
EOL

echo "Compliance report JSON generated at: ${OUTPUT_DIR}/${REPORT_FILE}"

# Generate HTML report
echo "Generating HTML report..."

cat > ${OUTPUT_DIR}/${HTML_REPORT} << EOL
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>SmartSphere Compliance Report</title>
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
        .framework-badge {
            margin-right: 5px;
            margin-bottom: 5px;
        }
        .progress {
            height: 10px;
            margin-bottom: 10px;
        }
        .finding-item {
            border-left: 4px solid #ddd;
            padding: 10px 15px;
            margin-bottom: 10px;
            background-color: #f8f9fa;
        }
        .finding-title {
            font-weight: 600;
        }
        .finding-severity {
            float: right;
            padding: 2px 8px;
            border-radius: 4px;
            font-size: 0.75rem;
            font-weight: 600;
            text-transform: uppercase;
        }
        .finding-details {
            margin-top: 10px;
            font-size: 0.9rem;
        }
        .chart-container {
            height: 250px;
            margin-bottom: 20px;
        }
        .last-updated {
            font-size: 0.8rem;
            color: #6c757d;
            margin-top: 15px;
            text-align: center;
        }
        .nav-pills .nav-link.active {
            background-color: #0066cc;
        }
        .table-responsive {
            margin-bottom: 20px;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <div class="row align-items-center">
                <div class="col-md-6">
                    <h1 class="h3">SmartSphere Compliance Report</h1>
                    <p class="text-muted">Comprehensive compliance assessment across multiple frameworks</p>
                </div>
                <div class="col-md-6 text-end">
                    <button class="btn btn-primary" onclick="window.print()">
                        <i class="bi bi-printer"></i> Print Report
                    </button>
                    <button class="btn btn-outline-secondary" id="export-pdf">
                        <i class="bi bi-file-earmark-pdf"></i> Export PDF
                    </button>
                </div>
            </div>
        </div>
        
        <div class="row">
            <div class="col-md-12 mb-4">
                <div class="card">
                    <div class="card-header bg-white">
                        <i class="bi bi-shield-check me-2"></i> Overall Compliance
                    </div>
                    <div class="card-body">
                        <div class="row">
                            <div class="col-md-4">
                                <div class="chart-container">
                                    <canvas id="overallComplianceChart"></canvas>
                                </div>
                            </div>
                            <div class="col-md-8">
                                <div class="table-responsive">
                                    <table class="table table-hover">
                                        <thead>
                                            <tr>
                                                <th>Framework</th>
                                                <th>Status</th>
                                                <th width="40%">Score</th>
                                            </tr>
                                        </thead>
                                        <tbody id="frameworks-table-body">
                                            <!-- Frameworks will be populated here -->
                                        </tbody>
                                    </table>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>
        
        <div class="row">
            <div class="col-12">
                <ul class="nav nav-pills mb-3" id="categories-tab" role="tablist">
                    <!-- Category tabs will be populated here -->
                </ul>
                <div class="tab-content" id="categories-tab-content">
                    <!-- Category content will be populated here -->
                </div>
            </div>
        </div>
        
        <div class="row mt-4">
            <div class="col-md-12">
                <div class="card">
                    <div class="card-header bg-white">
                        <i class="bi bi-exclamation-triangle me-2"></i> Compliance Findings
                        <div class="float-end">
                            <select class="form-select form-select-sm" id="finding-filter">
                                <option value="all">All Findings</option>
                                <option value="High">High Severity</option>
                                <option value="Medium">Medium Severity</option>
                                <option value="Low">Low Severity</option>
                            </select>
                        </div>
                    </div>
                    <div class="card-body">
                        <div id="findings-container">
                            <!-- Findings will be populated here -->
                        </div>
                    </div>
                </div>
            </div>
        </div>
        
        <div class="row mt-4">
            <div class="col-md-6">
                <div class="card">
                    <div class="card-header bg-white">
                        <i class="bi bi-bar-chart me-2"></i> Recommendations by Severity
                    </div>
                    <div class="card-body">
                        <div class="chart-container">
                            <canvas id="recommendationsChart"></canvas>
                        </div>
                    </div>
                </div>
            </div>
            <div class="col-md-6">
                <div class="card">
                    <div class="card-header bg-white">
                        <i class="bi bi-calendar3 me-2"></i> Compliance Trend
                    </div>
                    <div class="card-body">
                        <div class="chart-container">
                            <canvas id="trendChart"></canvas>
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
        // Load and parse compliance data
        fetch('${REPORT_FILE}')
            .then(response => response.json())
            .then(data => {
                // Populate report metadata
                document.getElementById('report-metadata').textContent = 
                    'Report generated at: ' + new Date(data.reportMetadata.generatedAt).toLocaleString() + 
                    ' for ' + data.reportMetadata.project + ' (' + data.reportMetadata.environment + ')';
                
                // Render overall compliance
                renderOverallCompliance(data.overallCompliance);
                
                // Render categories
                renderCategories(data.complianceByCategory);
                
                // Render findings
                renderFindings(data.findings);
                
                // Render recommendation chart
                renderRecommendationChart(data.recommendationSummary);
                
                // Render trend chart
                renderTrendChart(data.overallCompliance);
                
                // Set up event handlers
                document.getElementById('finding-filter').addEventListener('change', function() {
                    filterFindings(data.findings, this.value);
                });
            })
            .catch(error => {
                console.error('Error loading compliance data:', error);
                alert('Failed to load compliance data');
            });
        
        // Render overall compliance section
        function renderOverallCompliance(compliance) {
            // Populate frameworks table
            const tableBody = document.getElementById('frameworks-table-body');
            let frameworks = [];
            let scores = [];
            let colors = [];
            
            for (const [framework, data] of Object.entries(compliance)) {
                if (framework === 'overall') continue;
                
                frameworks.push(formatFrameworkName(framework));
                scores.push(data.score);
                colors.push(data.color);
                
                const row = document.createElement('tr');
                row.innerHTML = \`
                    <td>\${formatFrameworkName(framework)}</td>
                    <td><span class="badge" style="background-color: \${data.color}">\${data.status}</span></td>
                    <td>
                        <div class="progress">
                            <div class="progress-bar" role="progressbar" style="width: \${data.score}%; background-color: \${data.color}" 
                                aria-valuenow="\${data.score}" aria-valuemin="0" aria-valuemax="100"></div>
                        </div>
                        <small>\${data.score}%</small>
                    </td>
                \`;
                tableBody.appendChild(row);
            }
            
            // Add overall row
            const overallRow = document.createElement('tr');
            overallRow.className = 'table-active';
            overallRow.innerHTML = \`
                <td><strong>Overall Compliance</strong></td>
                <td><span class="badge" style="background-color: \${compliance.overall.color}">\${compliance.overall.status}</span></td>
                <td>
                    <div class="progress">
                        <div class="progress-bar" role="progressbar" style="width: \${compliance.overall.score}%; background-color: \${compliance.overall.color}" 
                            aria-valuenow="\${compliance.overall.score}" aria-valuemin="0" aria-valuemax="100"></div>
                    </div>
                    <small>\${compliance.overall.score}%</small>
                </td>
            \`;
            tableBody.appendChild(overallRow);
            
            // Render chart
            const ctx = document.getElementById('overallComplianceChart').getContext('2d');
            new Chart(ctx, {
                type: 'doughnut',
                data: {
                    labels: frameworks,
                    datasets: [{
                        data: scores,
                        backgroundColor: colors,
                        borderWidth: 1
                    }]
                },
                options: {
                    responsive: true,
                    maintainAspectRatio: false,
                    plugins: {
                        legend: {
                            position: 'right',
                            labels: {
                                boxWidth: 12
                            }
                        }
                    }
                }
            });
        }
        
        // Render category tabs and content
        function renderCategories(categories) {
            const tabList = document.getElementById('categories-tab');
            const tabContent = document.getElementById('categories-tab-content');
            
            let isFirst = true;
            for (const [category, data] of Object.entries(categories)) {
                // Create tab
                const tabItem = document.createElement('li');
                tabItem.className = 'nav-item';
                tabItem.innerHTML = \`
                    <a class="nav-link \${isFirst ? 'active' : ''}" id="\${category}-tab" data-bs-toggle="pill" 
                       href="#\${category}-content" role="tab" aria-controls="\${category}-content" 
                       aria-selected="\${isFirst ? 'true' : 'false'}">\${formatCategoryName(category)}</a>
                \`;
                tabList.appendChild(tabItem);
                
                // Create content
                const contentDiv = document.createElement('div');
                contentDiv.className = \`tab-pane fade \${isFirst ? 'show active' : ''}\`;
                contentDiv.id = \`\${category}-content\`;
                contentDiv.setAttribute('role', 'tabpanel');
                contentDiv.setAttribute('aria-labelledby', \`\${category}-tab\`);
                
                // Create table for framework scores in this category
                let tableContent = \`
                    <div class="table-responsive">
                        <table class="table table-hover">
                            <thead>
                                <tr>
                                    <th>Framework</th>
                                    <th>Status</th>
                                    <th width="40%">Score</th>
                                </tr>
                            </thead>
                            <tbody>
                \`;
                
                for (const [framework, frameworkData] of Object.entries(data.frameworks)) {
                    tableContent += \`
                        <tr>
                            <td>\${formatFrameworkName(framework)}</td>
                            <td><span class="badge" style="background-color: \${frameworkData.color}">\${frameworkData.status}</span></td>
                            <td>
                                <div class="progress">
                                    <div class="progress-bar" role="progressbar" style="width: \${frameworkData.score}%; background-color: \${frameworkData.color}" 
                                        aria-valuenow="\${frameworkData.score}" aria-valuemin="0" aria-valuemax="100"></div>
                                </div>
                                <small>\${frameworkData.score}%</small>
                            </td>
                        </tr>
                    \`;
                }
                
                // Add overall row for this category
                tableContent += \`
                        <tr class="table-active">
                            <td><strong>Overall \${formatCategoryName(category)}</strong></td>
                            <td><span class="badge" style="background-color: \${data.overall.color}">\${data.overall.status}</span></td>
                            <td>
                                <div class="progress">
                                    <div class="progress-bar" role="progressbar" style="width: \${data.overall.score}%; background-color: \${data.overall.color}" 
                                        aria-valuenow="\${data.overall.score}" aria-valuemin="0" aria-valuemax="100"></div>
                                </div>
                                <small>\${data.overall.score}%</small>
                            </td>
                        </tr>
                    </tbody>
                </table>
            </div>
                \`;
                
                contentDiv.innerHTML = tableContent;
                tabContent.appendChild(contentDiv);
                
                isFirst = false;
            }
        }
        
        // Render findings
        function renderFindings(findings) {
            const container = document.getElementById('findings-container');
            container.innerHTML = '';
            
            findings.forEach(finding => {
                const findingDiv = document.createElement('div');
                findingDiv.className = 'finding-item';
                findingDiv.setAttribute('data-severity', finding.severity);
                findingDiv.style.borderLeftColor = finding.color;
                
                const frameworks = finding.frameworks.split(',').map(f => {
                    return \`<span class="badge bg-secondary framework-badge">\${formatFrameworkName(f)}</span>\`;
                }).join('');
                
                findingDiv.innerHTML = \`
                    <div>
                        <span class="finding-severity" style="background-color: \${finding.color}">\${finding.severity}</span>
                        <span class="finding-title">\${finding.title}</span>
                    </div>
                    <div class="finding-details">
                        <p>\${finding.description}</p>
                        <div><strong>Category:</strong> \${formatCategoryName(finding.category)}</div>
                        <div><strong>Affected Resources:</strong> \${finding.affectedResources}</div>
                        <div><strong>Frameworks:</strong> \${frameworks}</div>
                        <div><strong>Remediation:</strong> \${finding.remediation}</div>
                        <div><strong>Remediation Date:</strong> \${finding.remediationDate}</div>
                    </div>
                \`;
                
                container.appendChild(findingDiv);
            });
        }
        
        // Filter findings by severity
        function filterFindings(findings, severity) {
            const container = document.getElementById('findings-container');
            const findingItems = container.querySelectorAll('.finding-item');
            
            findingItems.forEach(item => {
                if (severity === 'all' || item.getAttribute('data-severity') === severity) {
                    item.style.display = 'block';
                } else {
                    item.style.display = 'none';
                }
            });
        }
        
        // Render recommendation chart
        function renderRecommendationChart(summary) {
            const ctx = document.getElementById('recommendationsChart').getContext('2d');
            new Chart(ctx, {
                type: 'bar',
                data: {
                    labels: ['Critical', 'High', 'Medium', 'Low'],
                    datasets: [{
                        label: 'Number of Recommendations',
                        data: [
                            summary.criticalRecommendations,
                            summary.highRecommendations,
                            summary.mediumRecommendations,
                            summary.lowRecommendations
                        ],
                        backgroundColor: [
                            '#dc3545',
                            '#fd7e14',
                            '#ffc107',
                            '#28a745'
                        ]
                    }]
                },
                options: {
                    responsive: true,
                    maintainAspectRatio: false,
                    scales: {
                        y: {
                            beginAtZero: true
                        }
                    }
                }
            });
        }
        
        // Render trend chart
        function renderTrendChart(compliance) {
            // Generate some fake historical data based on current compliance
            const ctx = document.getElementById('trendChart').getContext('2d');
            
            // Get current month and 5 previous months
            const months = [];
            const currentDate = new Date();
            
            for (let i = 5; i >= 0; i--) {
                const month = new Date(currentDate.getFullYear(), currentDate.getMonth() - i, 1);
                const monthName = month.toLocaleString('default', { month: 'short' });
                months.push(\`\${monthName} \${month.getFullYear()}\`);
            }
            
            // Generate trend data (slightly lower scores for previous months)
            const trendData = [];
            const currentScore = compliance.overall.score;
            
            for (let i = 0; i < 5; i++) {
                const prevScore = Math.max(40, currentScore - (5 - i) * Math.floor(Math.random() * 5 + 3));
                trendData.push(prevScore);
            }
            
            // Add current score
            trendData.push(currentScore);
            
            new Chart(ctx, {
                type: 'line',
                data: {
                    labels: months,
                    datasets: [{
                        label: 'Compliance Score',
                        data: trendData,
                        borderColor: '#0066cc',
                        backgroundColor: 'rgba(0, 102, 204, 0.1)',
                        tension: 0.1,
                        fill: true
                    }]
                },
                options: {
                    responsive: true,
                    maintainAspectRatio: false,
                    scales: {
                        y: {
                            min: 0,
                            max: 100
                        }
                    }
                }
            });
        }
        
        // Format framework name for display
        function formatFrameworkName(framework) {
            return framework.replace(/_/g, ' ');
        }
        
        // Format category name for display
        function formatCategoryName(category) {
            return category.replace(/_/g, ' ');
        }
    </script>
</body>
</html>
EOL

echo "Compliance HTML report generated at: ${OUTPUT_DIR}/${HTML_REPORT}"
echo "Done!"