// AWS Lambda function for sending notifications when forecast export is complete
const AWS = require('aws-sdk');
const s3 = new AWS.S3();
const sns = new AWS.SNS();
const cloudwatch = new AWS.CloudWatch();

// Get environment variables
const snsTopicArn = process.env.SNS_TOPIC_ARN;
const projectName = process.env.PROJECT_NAME;
const environment = process.env.ENVIRONMENT;

exports.handler = async (event) => {
    try {
        console.log('Processing forecast export completion');
        console.log('Event:', JSON.stringify(event, null, 2));
        
        // Extract the S3 bucket and object key from the event
        const bucket = event.Records[0].s3.bucket.name;
        const key = event.Records[0].s3.object.key;
        
        console.log(`Processing forecast file: s3://${bucket}/${key}`);
        
        // Download the forecast data
        const s3Response = await s3.getObject({
            Bucket: bucket,
            Key: key
        }).promise();
        
        // Parse the CSV data
        const forecastData = parseCSV(s3Response.Body.toString());
        
        // Calculate forecast metrics
        const metrics = calculateMetrics(forecastData);
        
        // Generate forecast summary
        const summary = generateSummary(forecastData, metrics);
        
        // Publish metrics to CloudWatch
        await publishMetrics(metrics);
        
        // Send notification
        await sendNotification(summary);
        
        return {
            statusCode: 200,
            body: JSON.stringify({
                message: 'Forecast notification processed successfully',
                metrics
            })
        };
    } catch (error) {
        console.error('Error in forecast notification:', error);
        throw error;
    }
};

// Parse CSV data
function parseCSV(csvData) {
    const lines = csvData.split('\n');
    const headers = lines[0].split(',');
    
    const results = [];
    for (let i = 1; i < lines.length; i++) {
        if (lines[i].trim() === '') continue;
        
        const values = lines[i].split(',');
        const row = {};
        
        for (let j = 0; j < headers.length; j++) {
            row[headers[j]] = values[j];
        }
        
        results.push(row);
    }
    
    return results;
}

// Calculate forecast metrics
function calculateMetrics(forecastData) {
    // Extract forecasted values
    const p10Values = forecastData
        .filter(item => item.type === 'p10')
        .map(item => ({ date: item.date, value: parseFloat(item.value) }));
    
    const p50Values = forecastData
        .filter(item => item.type === 'p50')
        .map(item => ({ date: item.date, value: parseFloat(item.value) }));
    
    const p90Values = forecastData
        .filter(item => item.type === 'p90')
        .map(item => ({ date: item.date, value: parseFloat(item.value) }));
    
    // Calculate total forecasted cost (p50)
    const totalForecastedCost = p50Values.reduce((sum, item) => sum + item.value, 0);
    
    // Calculate average daily cost
    const avgDailyCost = totalForecastedCost / p50Values.length;
    
    // Find peak day
    const peakDay = p50Values.reduce((max, item) => 
        item.value > max.value ? item : max, p50Values[0]);
    
    // Calculate growth rate (comparing last day to first day)
    const growthRate = p50Values.length > 1 
        ? ((p50Values[p50Values.length - 1].value / p50Values[0].value) - 1) * 100
        : 0;
    
    return {
        totalForecastedCost,
        avgDailyCost,
        peakDay,
        growthRate,
        forecastPeriodDays: p50Values.length,
        p10Values,
        p50Values,
        p90Values
    };
}

// Generate human-readable summary
function generateSummary(forecastData, metrics) {
    return `
AI-Powered Cost Forecast Summary for ${projectName} - ${environment}

Forecast Period: ${metrics.forecastPeriodDays} days
Total Forecasted Cost: $${metrics.totalForecastedCost.toFixed(2)}
Average Daily Cost: $${metrics.avgDailyCost.toFixed(2)}
Peak Cost Day: ${metrics.peakDay.date} at $${metrics.peakDay.value.toFixed(2)}
Forecast Growth Rate: ${metrics.growthRate.toFixed(2)}%

Confidence Intervals:
- Lower Bound (P10): $${metrics.p10Values.reduce((sum, item) => sum + item.value, 0).toFixed(2)}
- Median Forecast (P50): $${metrics.p50Values.reduce((sum, item) => sum + item.value, 0).toFixed(2)}
- Upper Bound (P90): $${metrics.p90Values.reduce((sum, item) => sum + item.value, 0).toFixed(2)}

The forecast data is available in the S3 bucket.

Recommendations:
${generateRecommendations(metrics)}
    `;
}

// Generate cost optimization recommendations
function generateRecommendations(metrics) {
    const recommendations = [];
    
    if (metrics.growthRate > 10) {
        recommendations.push(`- Cost is growing at ${metrics.growthRate.toFixed(2)}%. Consider reviewing resource usage and identify optimization opportunities.`);
    }
    
    if (metrics.totalForecastedCost > 1000) {
        recommendations.push('- Consider using Savings Plans or Reserved Instances for predictable workloads to reduce costs.');
    }
    
    if (metrics.peakDay.value > metrics.avgDailyCost * 1.5) {
        recommendations.push(`- Significant cost spike detected on ${metrics.peakDay.date}. Investigate to prevent unexpected charges.`);
    }
    
    if (recommendations.length === 0) {
        recommendations.push('- No specific recommendations at this time. Cost trends appear to be within expected ranges.');
    }
    
    return recommendations.join('\n');
}

// Publish metrics to CloudWatch
async function publishMetrics(metrics) {
    const metricData = [
        {
            MetricName: 'ForecastedCostP50',
            Dimensions: [
                { Name: 'Project', Value: projectName },
                { Name: 'Environment', Value: environment }
            ],
            Unit: 'None',
            Value: metrics.totalForecastedCost
        },
        {
            MetricName: 'ForecastGrowthRate',
            Dimensions: [
                { Name: 'Project', Value: projectName },
                { Name: 'Environment', Value: environment }
            ],
            Unit: 'Percent',
            Value: metrics.growthRate
        },
        {
            MetricName: 'CostOptimizationScore',
            Dimensions: [
                { Name: 'Project', Value: projectName },
                { Name: 'Environment', Value: environment }
            ],
            Unit: 'None',
            // Simple example of a cost optimization score based on growth rate
            Value: Math.max(0, 100 - Math.abs(metrics.growthRate) * 2)
        }
    ];
    
    // Add daily forecast values
    metrics.p10Values.forEach(item => {
        metricData.push({
            MetricName: 'ForecastedCostP10',
            Dimensions: [
                { Name: 'Project', Value: projectName },
                { Name: 'Environment', Value: environment },
                { Name: 'Date', Value: item.date }
            ],
            Unit: 'None',
            Value: item.value,
            Timestamp: new Date(item.date)
        });
    });
    
    metrics.p50Values.forEach(item => {
        metricData.push({
            MetricName: 'ForecastedCostP50',
            Dimensions: [
                { Name: 'Project', Value: projectName },
                { Name: 'Environment', Value: environment },
                { Name: 'Date', Value: item.date }
            ],
            Unit: 'None',
            Value: item.value,
            Timestamp: new Date(item.date)
        });
    });
    
    metrics.p90Values.forEach(item => {
        metricData.push({
            MetricName: 'ForecastedCostP90',
            Dimensions: [
                { Name: 'Project', Value: projectName },
                { Name: 'Environment', Value: environment },
                { Name: 'Date', Value: item.date }
            ],
            Unit: 'None',
            Value: item.value,
            Timestamp: new Date(item.date)
        });
    });
    
    // CloudWatch allows up to 20 metrics per request
    for (let i = 0; i < metricData.length; i += 20) {
        const batch = metricData.slice(i, i + 20);
        
        await cloudwatch.putMetricData({
            Namespace: `${projectName}/${environment}`,
            MetricData: batch
        }).promise();
    }
    
    console.log(`Published ${metricData.length} metrics to CloudWatch`);
}

// Send notification via SNS
async function sendNotification(summary) {
    await sns.publish({
        TopicArn: snsTopicArn,
        Subject: `Cost Forecast Updated - ${projectName} ${environment}`,
        Message: summary
    }).promise();
    
    console.log('Notification sent successfully');
}