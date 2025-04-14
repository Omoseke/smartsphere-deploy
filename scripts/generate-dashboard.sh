#!/bin/bash
# Deployment Health Dashboard Generator

set -e

# Configuration
OUTPUT_DIR="./dashboard"
CLOUDWATCH_METRICS_FILE="metrics.json"
HTML_DASHBOARD_FILE="deployment-health.html"
DATA_REFRESH_INTERVAL=300 # in seconds

# Colors and styles
SUCCESS_COLOR="#28a745"
WARNING_COLOR="#ffc107"
ERROR_COLOR="#dc3545"
INFO_COLOR="#17a2b8"

echo "SmartSphere Deployment Health Dashboard Generator"
echo "================================================"
echo

# Create output directory if it doesn't exist
mkdir -p ${OUTPUT_DIR}

# Check if required AWS CLI is installed
if ! command -v aws &> /dev/null; then
    echo "Error: AWS CLI is not installed"
    exit 1
fi

echo "Generating deployment health dashboard..."

# Collect service health metrics
echo "Collecting service health metrics..."

# Function to collect CloudWatch metrics for service health
collect_service_metrics() {
    local service_name=$1
    local namespace=$2
    local metric_name=$3
    local stat=$4
    local period=$5
    local dimensions=$6
    
    # Determine time range (last hour)
    local end_time=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    local start_time=$(date -u -d "1 hour ago" +"%Y-%m-%dT%H:%M:%SZ")
    
    # Get metrics using AWS CLI
    aws cloudwatch get-metric-statistics \
        --namespace "${namespace}" \
        --metric-name "${metric_name}" \
        --dimensions ${dimensions} \
        --start-time "${start_time}" \
        --end-time "${end_time}" \
        --period ${period} \
        --statistics "${stat}" \
        --output json > "${OUTPUT_DIR}/${service_name}_${metric_name}.json" || echo "Warning: Could not collect metrics for ${service_name}"
}

# Sample metrics to collect (these would be real services in a production environment)
echo "  - Collecting ECS service metrics..."
collect_service_metrics "ecs" "AWS/ECS" "CPUUtilization" "Average" 60 "Name=ClusterName,Value=smartsphere-cluster Name=ServiceName,Value=smartsphere-service"

echo "  - Collecting ALB metrics..."
collect_service_metrics "alb" "AWS/ApplicationELB" "TargetResponseTime" "Average" 60 "Name=LoadBalancer,Value=smartsphere-alb"

echo "  - Collecting RDS metrics..."
collect_service_metrics "rds" "AWS/RDS" "CPUUtilization" "Average" 60 "Name=DBInstanceIdentifier,Value=smartsphere-db"

echo "  - Collecting Lambda metrics..."
collect_service_metrics "lambda" "AWS/Lambda" "Duration" "Average" 60 "Name=FunctionName,Value=smartsphere-function"

# Create combined metrics file
echo "{\"timestamp\": \"$(date -u +"%Y-%m-%dT%H:%M:%SZ")\"," > "${OUTPUT_DIR}/${CLOUDWATCH_METRICS_FILE}"
echo "\"services\": [" >> "${OUTPUT_DIR}/${CLOUDWATCH_METRICS_FILE}"

# Add ECS metrics
ecs_cpu=$(jq '.Datapoints[-1].Average // 0' "${OUTPUT_DIR}/ecs_CPUUtilization.json" 2>/dev/null || echo 0)
ecs_status="healthy"
ecs_color="${SUCCESS_COLOR}"
if (( $(echo "${ecs_cpu} > 80" | bc -l) )); then
    ecs_status="warning"
    ecs_color="${WARNING_COLOR}"
fi
if (( $(echo "${ecs_cpu} > 90" | bc -l) )); then
    ecs_status="critical"
    ecs_color="${ERROR_COLOR}"
fi

echo "{\"name\": \"ECS Service\", \"status\": \"${ecs_status}\", \"color\": \"${ecs_color}\", \"metrics\": {\"CPU\": ${ecs_cpu}}}," >> "${OUTPUT_DIR}/${CLOUDWATCH_METRICS_FILE}"

# Add ALB metrics
alb_response=$(jq '.Datapoints[-1].Average // 0' "${OUTPUT_DIR}/alb_TargetResponseTime.json" 2>/dev/null || echo 0)
alb_status="healthy"
alb_color="${SUCCESS_COLOR}"
if (( $(echo "${alb_response} > 0.5" | bc -l) )); then
    alb_status="warning"
    alb_color="${WARNING_COLOR}"
fi
if (( $(echo "${alb_response} > 1.0" | bc -l) )); then
    alb_status="critical"
    alb_color="${ERROR_COLOR}"
fi

echo "{\"name\": \"Load Balancer\", \"status\": \"${alb_status}\", \"color\": \"${alb_color}\", \"metrics\": {\"Response Time\": ${alb_response}}}," >> "${OUTPUT_DIR}/${CLOUDWATCH_METRICS_FILE}"

# Add RDS metrics
rds_cpu=$(jq '.Datapoints[-1].Average // 0' "${OUTPUT_DIR}/rds_CPUUtilization.json" 2>/dev/null || echo 0)
rds_status="healthy"
rds_color="${SUCCESS_COLOR}"
if (( $(echo "${rds_cpu} > 70" | bc -l) )); then
    rds_status="warning"
    rds_color="${WARNING_COLOR}"
fi
if (( $(echo "${rds_cpu} > 85" | bc -l) )); then
    rds_status="critical"
    rds_color="${ERROR_COLOR}"
fi

echo "{\"name\": \"Database\", \"status\": \"${rds_status}\", \"color\": \"${rds_color}\", \"metrics\": {\"CPU\": ${rds_cpu}}}," >> "${OUTPUT_DIR}/${CLOUDWATCH_METRICS_FILE}"

# Add Lambda metrics
lambda_duration=$(jq '.Datapoints[-1].Average // 0' "${OUTPUT_DIR}/lambda_Duration.json" 2>/dev/null || echo 0)
lambda_status="healthy"
lambda_color="${SUCCESS_COLOR}"
if (( $(echo "${lambda_duration} > 1000" | bc -l) )); then
    lambda_status="warning"
    lambda_color="${WARNING_COLOR}"
fi
if (( $(echo "${lambda_duration} > 2000" | bc -l) )); then
    lambda_status="critical"
    lambda_color="${ERROR_COLOR}"
fi

echo "{\"name\": \"Lambda Functions\", \"status\": \"${lambda_status}\", \"color\": \"${lambda_color}\", \"metrics\": {\"Duration\": ${lambda_duration}}}" >> "${OUTPUT_DIR}/${CLOUDWATCH_METRICS_FILE}"

# Close the services array
echo "]," >> "${OUTPUT_DIR}/${CLOUDWATCH_METRICS_FILE}"

# Add deployment information
echo "\"deployments\": [" >> "${OUTPUT_DIR}/${CLOUDWATCH_METRICS_FILE}"
echo "{\"id\": \"deploy-123\", \"time\": \"$(date -u -d '30 minutes ago' +"%Y-%m-%dT%H:%M:%SZ")\", \"status\": \"success\", \"color\": \"${SUCCESS_COLOR}\", \"version\": \"v1.2.3\", \"user\": \"ci-system\"}," >> "${OUTPUT_DIR}/${CLOUDWATCH_METRICS_FILE}"
echo "{\"id\": \"deploy-122\", \"time\": \"$(date -u -d '2 hours ago' +"%Y-%m-%dT%H:%M:%SZ")\", \"status\": \"success\", \"color\": \"${SUCCESS_COLOR}\", \"version\": \"v1.2.2\", \"user\": \"ci-system\"}," >> "${OUTPUT_DIR}/${CLOUDWATCH_METRICS_FILE}"
echo "{\"id\": \"deploy-121\", \"time\": \"$(date -u -d '1 day ago' +"%Y-%m-%dT%H:%M:%SZ")\", \"status\": \"failed\", \"color\": \"${ERROR_COLOR}\", \"version\": \"v1.2.1\", \"user\": \"ci-system\"}" >> "${OUTPUT_DIR}/${CLOUDWATCH_METRICS_FILE}"
echo "]," >> "${OUTPUT_DIR}/${CLOUDWATCH_METRICS_FILE}"

# Add alerts
echo "\"alerts\": [" >> "${OUTPUT_DIR}/${CLOUDWATCH_METRICS_FILE}"
if [[ "${ecs_status}" == "critical" || "${alb_status}" == "critical" || "${rds_status}" == "critical" || "${lambda_status}" == "critical" ]]; then
    echo "{\"level\": \"critical\", \"message\": \"One or more services are in critical state\", \"color\": \"${ERROR_COLOR}\"}," >> "${OUTPUT_DIR}/${CLOUDWATCH_METRICS_FILE}"
fi
if [[ "${ecs_status}" == "warning" || "${alb_status}" == "warning" || "${rds_status}" == "warning" || "${lambda_status}" == "warning" ]]; then
    echo "{\"level\": \"warning\", \"message\": \"One or more services need attention\", \"color\": \"${WARNING_COLOR}\"}," >> "${OUTPUT_DIR}/${CLOUDWATCH_METRICS_FILE}"
fi
echo "{\"level\": \"info\", \"message\": \"Dashboard refreshed at $(date)\", \"color\": \"${INFO_COLOR}\"}" >> "${OUTPUT_DIR}/${CLOUDWATCH_METRICS_FILE}"
echo "]" >> "${OUTPUT_DIR}/${CLOUDWATCH_METRICS_FILE}"

# Close the main JSON object
echo "}" >> "${OUTPUT_DIR}/${CLOUDWATCH_METRICS_FILE}"

# Generate HTML dashboard
echo "Generating HTML dashboard..."

cat > "${OUTPUT_DIR}/${HTML_DASHBOARD_FILE}" << EOL
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>SmartSphere Deployment Health Dashboard</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.1.3/dist/css/bootstrap.min.css" rel="stylesheet">
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.8.1/font/bootstrap-icons.css">
    <script src="https://cdn.jsdelivr.net/npm/chart.js@3.7.1/dist/chart.min.js"></script>
    <style>
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background-color: #f8f9fa;
            padding-top: 20px;
        }
        .dashboard-header {
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
        .status-badge {
            float: right;
            text-transform: capitalize;
            font-weight: normal;
        }
        .metric-value {
            font-size: 2rem;
            font-weight: 300;
        }
        .metric-label {
            font-size: 0.875rem;
            color: #6c757d;
        }
        .service-icon {
            font-size: 1.5rem;
            margin-right: 10px;
        }
        .alert-container {
            position: fixed;
            top: 20px;
            right: 20px;
            z-index: 1050;
            width: 350px;
        }
        .deployment-item {
            border-left: 4px solid #ddd;
            padding: 10px 15px;
            margin-bottom: 10px;
            background-color: #f8f9fa;
        }
        .deployment-time {
            color: #6c757d;
            font-size: 0.875rem;
        }
        .deployment-version {
            font-weight: 600;
        }
        .deployment-user {
            font-style: italic;
            color: #6c757d;
        }
        .chart-container {
            position: relative;
            height: 200px;
            width: 100%;
        }
        .metrics-table td {
            padding: 8px 0;
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
        <div class="dashboard-header">
            <div class="row align-items-center">
                <div class="col-md-6">
                    <h1 class="h3">SmartSphere Deployment Health Dashboard</h1>
                    <p class="text-muted">Real-time infrastructure and application monitoring</p>
                </div>
                <div class="col-md-6 text-end">
                    <div class="btn-group" role="group">
                        <button type="button" class="btn btn-outline-secondary" id="refresh-btn">
                            <i class="bi bi-arrow-clockwise"></i> Refresh
                        </button>
                        <div class="btn-group" role="group">
                            <button type="button" class="btn btn-outline-secondary dropdown-toggle" data-bs-toggle="dropdown">
                                <i class="bi bi-gear"></i> Settings
                            </button>
                            <ul class="dropdown-menu dropdown-menu-end">
                                <li><a class="dropdown-item" href="#" id="auto-refresh-toggle">Auto Refresh: On</a></li>
                                <li><hr class="dropdown-divider"></li>
                                <li><a class="dropdown-item" href="#" data-refresh-interval="60">Refresh: 1 minute</a></li>
                                <li><a class="dropdown-item" href="#" data-refresh-interval="300">Refresh: 5 minutes</a></li>
                                <li><a class="dropdown-item" href="#" data-refresh-interval="600">Refresh: 10 minutes</a></li>
                            </ul>
                        </div>
                    </div>
                </div>
            </div>
        </div>
        
        <div class="row" id="alert-row"></div>
        
        <div class="row" id="services-row"></div>
        
        <div class="row">
            <div class="col-md-7">
                <div class="card">
                    <div class="card-header bg-white">
                        <i class="bi bi-graph-up service-icon"></i> Performance Metrics
                    </div>
                    <div class="card-body">
                        <div class="chart-container">
                            <canvas id="performanceChart"></canvas>
                        </div>
                    </div>
                </div>
            </div>
            <div class="col-md-5">
                <div class="card">
                    <div class="card-header bg-white">
                        <i class="bi bi-clock-history service-icon"></i> Recent Deployments
                    </div>
                    <div class="card-body" id="deployments-container">
                        <!-- Deployments will be loaded here -->
                    </div>
                </div>
            </div>
        </div>
        
        <div class="alert-container" id="notification-container"></div>
        
        <div class="last-updated" id="last-updated"></div>
    </div>
    
    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.1.3/dist/js/bootstrap.bundle.min.js"></script>
    <script>
        // Dashboard configuration
        const config = {
            dataUrl: '${CLOUDWATCH_METRICS_FILE}',
            refreshInterval: ${DATA_REFRESH_INTERVAL} * 1000,
            autoRefresh: true
        };
        
        // Service icons mapping
        const serviceIcons = {
            'ECS Service': 'bi-boxes',
            'Load Balancer': 'bi-diagram-3',
            'Database': 'bi-database',
            'Lambda Functions': 'bi-code-square',
            'API Gateway': 'bi-shuffle',
            'S3 Storage': 'bi-bucket'
        };
        
        // Charts
        let performanceChart;
        
        // Auto refresh timer
        let refreshTimer;
        
        // Initialize dashboard
        document.addEventListener('DOMContentLoaded', function() {
            // Initial load
            loadDashboardData();
            
            // Set up auto refresh
            startAutoRefresh();
            
            // Set up event listeners
            document.getElementById('refresh-btn').addEventListener('click', loadDashboardData);
            
            document.getElementById('auto-refresh-toggle').addEventListener('click', function(e) {
                e.preventDefault();
                config.autoRefresh = !config.autoRefresh;
                this.textContent = 'Auto Refresh: ' + (config.autoRefresh ? 'On' : 'Off');
                
                if (config.autoRefresh) {
                    startAutoRefresh();
                } else {
                    stopAutoRefresh();
                }
            });
            
            document.querySelectorAll('[data-refresh-interval]').forEach(item => {
                item.addEventListener('click', function(e) {
                    e.preventDefault();
                    const interval = parseInt(this.getAttribute('data-refresh-interval'));
                    config.refreshInterval = interval * 1000;
                    
                    // Restart the timer with new interval
                    if (config.autoRefresh) {
                        stopAutoRefresh();
                        startAutoRefresh();
                    }
                    
                    // Show notification
                    showNotification('Refresh interval set to ' + interval + ' seconds', 'info');
                });
            });
        });
        
        // Start auto refresh timer
        function startAutoRefresh() {
            refreshTimer = setInterval(loadDashboardData, config.refreshInterval);
        }
        
        // Stop auto refresh timer
        function stopAutoRefresh() {
            clearInterval(refreshTimer);
        }
        
        // Load dashboard data
        function loadDashboardData() {
            fetch(config.dataUrl)
                .then(response => response.json())
                .then(data => {
                    // Update timestamp
                    document.getElementById('last-updated').textContent = 'Last updated: ' + new Date(data.timestamp).toLocaleString();
                    
                    // Render alerts
                    renderAlerts(data.alerts);
                    
                    // Render services
                    renderServices(data.services);
                    
                    // Render deployments
                    renderDeployments(data.deployments);
                    
                    // Update performance chart
                    updatePerformanceChart(data.services);
                })
                .catch(error => {
                    console.error('Error loading dashboard data:', error);
                    showNotification('Failed to load dashboard data', 'danger');
                });
        }
        
        // Render service cards
        function renderServices(services) {
            const servicesRow = document.getElementById('services-row');
            servicesRow.innerHTML = '';
            
            services.forEach(service => {
                const col = document.createElement('div');
                col.className = 'col-md-3';
                
                const card = document.createElement('div');
                card.className = 'card h-100';
                
                const cardHeader = document.createElement('div');
                cardHeader.className = 'card-header bg-white';
                cardHeader.innerHTML = \`
                    <i class="bi \${serviceIcons[service.name] || 'bi-gear'} service-icon"></i>
                    \${service.name}
                    <span class="badge rounded-pill status-badge" style="background-color: \${service.color}">
                        \${service.status}
                    </span>
                \`;
                
                const cardBody = document.createElement('div');
                cardBody.className = 'card-body';
                
                // Add metrics
                const metricsTable = document.createElement('table');
                metricsTable.className = 'metrics-table w-100';
                
                for (const [metricName, metricValue] of Object.entries(service.metrics)) {
                    const row = document.createElement('tr');
                    
                    const nameCell = document.createElement('td');
                    nameCell.className = 'metric-label';
                    nameCell.textContent = metricName;
                    
                    const valueCell = document.createElement('td');
                    valueCell.className = 'metric-value text-end';
                    valueCell.textContent = formatMetricValue(metricName, metricValue);
                    
                    row.appendChild(nameCell);
                    row.appendChild(valueCell);
                    metricsTable.appendChild(row);
                }
                
                cardBody.appendChild(metricsTable);
                
                card.appendChild(cardHeader);
                card.appendChild(cardBody);
                col.appendChild(card);
                servicesRow.appendChild(col);
            });
        }
        
        // Format metric value based on type
        function formatMetricValue(metricName, value) {
            if (metricName === 'CPU') {
                return value.toFixed(1) + '%';
            } else if (metricName === 'Response Time') {
                return value.toFixed(3) + 's';
            } else if (metricName === 'Duration') {
                return value.toFixed(0) + 'ms';
            } else {
                return value.toString();
            }
        }
        
        // Render deployments
        function renderDeployments(deployments) {
            const container = document.getElementById('deployments-container');
            container.innerHTML = '';
            
            deployments.forEach(deployment => {
                const item = document.createElement('div');
                item.className = 'deployment-item';
                item.style.borderLeftColor = deployment.color;
                
                item.innerHTML = \`
                    <div class="deployment-time">\${formatDate(deployment.time)}</div>
                    <div class="deployment-version">\${deployment.version}</div>
                    <div>
                        <span class="badge rounded-pill" style="background-color: \${deployment.color}">\${deployment.status}</span>
                        <span class="deployment-user">by \${deployment.user}</span>
                    </div>
                \`;
                
                container.appendChild(item);
            });
        }
        
        // Render alerts
        function renderAlerts(alerts) {
            const alertRow = document.getElementById('alert-row');
            alertRow.innerHTML = '';
            
            alerts.forEach(alert => {
                if (alert.level === 'info') return; // Skip info alerts in the main banner
                
                const col = document.createElement('div');
                col.className = 'col-12 mb-4';
                
                const alertDiv = document.createElement('div');
                alertDiv.className = 'alert';
                alertDiv.style.backgroundColor = alert.color;
                alertDiv.style.color = '#fff';
                alertDiv.innerHTML = \`
                    <i class="bi \${alert.level === 'critical' ? 'bi-exclamation-triangle-fill' : 'bi-exclamation-circle-fill'} me-2"></i>
                    <strong>\${alert.level.toUpperCase()}:</strong> \${alert.message}
                \`;
                
                col.appendChild(alertDiv);
                alertRow.appendChild(col);
            });
        }
        
        // Update performance chart
        function updatePerformanceChart(services) {
            const ctx = document.getElementById('performanceChart').getContext('2d');
            
            // Destroy existing chart if exists
            if (performanceChart) {
                performanceChart.destroy();
            }
            
            // Prepare data
            const labels = [];
            const cpuData = [];
            const responseTimeData = [];
            
            services.forEach(service => {
                if (service.metrics.CPU) {
                    labels.push(service.name);
                    cpuData.push(service.metrics.CPU);
                }
                
                if (service.metrics['Response Time']) {
                    if (!labels.includes(service.name)) {
                        labels.push(service.name);
                    }
                    responseTimeData.push(service.metrics['Response Time'] * 1000); // Convert to ms
                }
            });
            
            // Create new chart
            performanceChart = new Chart(ctx, {
                type: 'bar',
                data: {
                    labels: labels,
                    datasets: [
                        {
                            label: 'CPU Utilization (%)',
                            data: cpuData,
                            backgroundColor: 'rgba(54, 162, 235, 0.5)',
                            borderColor: 'rgba(54, 162, 235, 1)',
                            borderWidth: 1,
                            yAxisID: 'y'
                        },
                        {
                            label: 'Response Time (ms)',
                            data: responseTimeData,
                            backgroundColor: 'rgba(255, 99, 132, 0.5)',
                            borderColor: 'rgba(255, 99, 132, 1)',
                            borderWidth: 1,
                            yAxisID: 'y1'
                        }
                    ]
                },
                options: {
                    responsive: true,
                    maintainAspectRatio: false,
                    scales: {
                        y: {
                            type: 'linear',
                            display: true,
                            position: 'left',
                            title: {
                                display: true,
                                text: 'CPU Utilization (%)'
                            },
                            min: 0,
                            max: 100
                        },
                        y1: {
                            type: 'linear',
                            display: true,
                            position: 'right',
                            title: {
                                display: true,
                                text: 'Response Time (ms)'
                            },
                            min: 0,
                            grid: {
                                drawOnChartArea: false
                            }
                        }
                    }
                }
            });
        }
        
        // Show notification
        function showNotification(message, type) {
            const container = document.getElementById('notification-container');
            
            const notification = document.createElement('div');
            notification.className = \`alert alert-\${type} alert-dismissible fade show\`;
            notification.innerHTML = \`
                \${message}
                <button type="button" class="btn-close" data-bs-dismiss="alert" aria-label="Close"></button>
            \`;
            
            container.appendChild(notification);
            
            // Auto remove after 5 seconds
            setTimeout(() => {
                notification.classList.remove('show');
                setTimeout(() => notification.remove(), 150);
            }, 5000);
        }
        
        // Format date
        function formatDate(dateStr) {
            const date = new Date(dateStr);
            return date.toLocaleString();
        }
    </script>
</body>
</html>
EOL

# Clean up temporary files
rm -f ${OUTPUT_DIR}/*_*.json 2>/dev/null

echo "Done! Deployment health dashboard generated at:"
echo "- Metrics data: ${OUTPUT_DIR}/${CLOUDWATCH_METRICS_FILE}"
echo "- Interactive dashboard: ${OUTPUT_DIR}/${HTML_DASHBOARD_FILE}"
echo
echo "To view the dashboard, open: ${OUTPUT_DIR}/${HTML_DASHBOARD_FILE}"
echo