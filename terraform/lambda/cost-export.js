// AWS Lambda function for exporting cost data to S3
const AWS = require('aws-sdk');
const costexplorer = new AWS.CostExplorer();
const s3 = new AWS.S3();

exports.handler = async (event) => {
    try {
        console.log('Starting cost data export process');
        
        // Get environment variables
        const outputBucket = process.env.OUTPUT_BUCKET;
        const outputPrefix = process.env.OUTPUT_PREFIX;
        const projectTag = process.env.PROJECT_TAG;
        const environment = process.env.ENVIRONMENT;
        
        if (!outputBucket || !outputPrefix) {
            throw new Error('Missing required environment variables');
        }
        
        // Calculate date ranges
        const now = new Date();
        
        // Get last 12 months of data (for training)
        const endDate = formatDate(now);
        const startDate = formatDate(new Date(now.setFullYear(now.getFullYear() - 1)));
        
        console.log(`Fetching cost data from ${startDate} to ${endDate}`);
        
        // Fetch cost data by month with daily granularity
        const costData = await getCostAndUsageData(startDate, endDate, projectTag, environment);
        
        // Prepare CSV data
        const csvData = convertToCSV(costData);
        
        // Generate a filename with timestamp
        const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
        const key = `${outputPrefix}/cost-data-${timestamp}.csv`;
        
        // Upload to S3
        await uploadToS3(outputBucket, key, csvData);
        
        console.log(`Successfully exported cost data to s3://${outputBucket}/${key}`);
        
        return {
            statusCode: 200,
            body: JSON.stringify({
                message: 'Cost data export completed successfully',
                bucket: outputBucket,
                key: key
            })
        };
    } catch (error) {
        console.error('Error in cost data export:', error);
        throw error;
    }
};

// Format date as YYYY-MM-DD
function formatDate(date) {
    return date.toISOString().split('T')[0];
}

// Get cost and usage data from AWS Cost Explorer
async function getCostAndUsageData(startDate, endDate, projectTag, environment) {
    const costItems = [];
    let nextPageToken = null;
    
    do {
        // Set up the request parameters
        const params = {
            TimePeriod: {
                Start: startDate,
                End: endDate
            },
            Granularity: 'DAILY',
            Metrics: ['UnblendedCost'],
            GroupBy: [
                {
                    Type: 'DIMENSION',
                    Key: 'SERVICE'
                }
            ],
            Filter: {
                And: [
                    {
                        Tags: {
                            Key: 'Project',
                            Values: [projectTag]
                        }
                    },
                    {
                        Tags: {
                            Key: 'Environment',
                            Values: [environment]
                        }
                    }
                ]
            }
        };
        
        // Include the next page token if we have one
        if (nextPageToken) {
            params.NextPageToken = nextPageToken;
        }
        
        // Make the API call
        const response = await costexplorer.getCostAndUsage(params).promise();
        
        // Process the results
        response.ResultsByTime.forEach(result => {
            const date = result.TimePeriod.Start;
            
            // Process each service group
            result.Groups.forEach(group => {
                const service = group.Keys[0];
                const cost = parseFloat(group.Metrics.UnblendedCost.Amount);
                const currency = group.Metrics.UnblendedCost.Unit;
                
                costItems.push({
                    date,
                    service,
                    cost,
                    currency
                });
            });
            
            // Also add the total
            if (result.Total && result.Total.UnblendedCost) {
                const totalCost = parseFloat(result.Total.UnblendedCost.Amount);
                const currency = result.Total.UnblendedCost.Unit;
                
                costItems.push({
                    date,
                    service: 'Total',
                    cost: totalCost,
                    currency
                });
            }
        });
        
        // Update the next page token
        nextPageToken = response.NextPageToken;
        
    } while (nextPageToken);
    
    return costItems;
}

// Convert cost data to CSV format
function convertToCSV(costData) {
    // Define CSV header
    let csv = 'date,service,cost,currency\n';
    
    // Add each row of data
    costData.forEach(item => {
        csv += `${item.date},${item.service.replace(/,/g, ' ')},${item.cost},${item.currency}\n`;
    });
    
    return csv;
}

// Upload data to S3
async function uploadToS3(bucket, key, data) {
    const params = {
        Bucket: bucket,
        Key: key,
        Body: data,
        ContentType: 'text/csv'
    };
    
    return await s3.putObject(params).promise();
}