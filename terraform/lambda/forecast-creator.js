// AWS Lambda function for creating AWS Forecast resources
const AWS = require('aws-sdk');
const forecast = new AWS.ForecastService();
const s3 = new AWS.S3();

// Get environment variables
const dataBucket = process.env.DATA_BUCKET;
const dataPrefix = process.env.DATA_PREFIX;
const forecastPrefix = process.env.FORECAST_PREFIX;
const forecastHorizon = parseInt(process.env.FORECAST_HORIZON || '90', 10);
const trainingWindow = parseInt(process.env.TRAINING_WINDOW || '366', 10);
const projectName = process.env.PROJECT_NAME;
const environment = process.env.ENVIRONMENT;
const iamRoleArn = process.env.IAM_ROLE_ARN;

// Generate unique IDs for forecast resources
const uniqueId = Date.now().toString();
const datasetGroupName = `${projectName}-${environment}-cost-dsg-${uniqueId}`;
const datasetName = `${projectName}-${environment}-cost-ds-${uniqueId}`;
const importJobName = `${projectName}-${environment}-cost-import-${uniqueId}`;
const predictorName = `${projectName}-${environment}-cost-predictor-${uniqueId}`;
const forecastName = `${projectName}-${environment}-cost-forecast-${uniqueId}`;
const exportJobName = `${projectName}-${environment}-cost-export-${uniqueId}`;

exports.handler = async (event) => {
    try {
        console.log('Starting AWS Forecast resource creation');
        console.log('Event:', JSON.stringify(event, null, 2));
        
        // Extract the S3 object key from the event
        const s3Key = event.Records[0].s3.object.key;
        console.log(`Triggered by S3 upload: ${s3Key}`);
        
        // Check if this is a cost data CSV file
        if (!s3Key.startsWith(dataPrefix) || !s3Key.endsWith('.csv')) {
            console.log('Not a cost data CSV file, skipping');
            return {
                statusCode: 200,
                body: 'Not a cost data CSV file, skipping'
            };
        }
        
        // Create dataset group
        console.log(`Creating dataset group: ${datasetGroupName}`);
        await forecast.createDatasetGroup({
            DatasetGroupName: datasetGroupName,
            Domain: 'CUSTOM',
            Tags: [
                { Key: 'Project', Value: projectName },
                { Key: 'Environment', Value: environment }
            ]
        }).promise();
        
        // Create dataset
        console.log(`Creating dataset: ${datasetName}`);
        await forecast.createDataset({
            DatasetName: datasetName,
            DatasetType: 'TARGET_TIME_SERIES',
            Domain: 'CUSTOM',
            Schema: {
                Attributes: [
                    { AttributeName: 'date', AttributeType: 'timestamp' },
                    { AttributeName: 'service', AttributeType: 'string' },
                    { AttributeName: 'cost', AttributeType: 'float' },
                    { AttributeName: 'currency', AttributeType: 'string' }
                ]
            }
        }).promise();
        
        // Add dataset to group
        console.log('Adding dataset to group');
        await forecast.updateDatasetGroup({
            DatasetGroupName: datasetGroupName,
            DatasetArns: [(await forecast.describeDataset({ DatasetName: datasetName }).promise()).DatasetArn]
        }).promise();
        
        // Create dataset import job
        console.log(`Creating dataset import job: ${importJobName}`);
        await forecast.createDatasetImportJob({
            DatasetImportJobName: importJobName,
            DatasetArn: (await forecast.describeDataset({ DatasetName: datasetName }).promise()).DatasetArn,
            DataSource: {
                S3Config: {
                    Path: `s3://${dataBucket}/${s3Key}`,
                    RoleArn: iamRoleArn
                }
            },
            TimestampFormat: 'yyyy-MM-dd'
        }).promise();
        
        // Wait for import job to complete (this might take a while)
        console.log('Waiting for import job to complete...');
        let importStatus = 'CREATING';
        let importJobArn = (await forecast.describeDatasetImportJob({ 
            DatasetImportJobArn: (await forecast.describeDatasetImportJob({ 
                DatasetImportJobName: importJobName 
            }).promise()).DatasetImportJobArn 
        }).promise()).DatasetImportJobArn;
        
        // Poll for status in a non-blocking way (the function will timeout and be restarted)
        // In a real implementation, you would use a Step Function for orchestration
        while (importStatus === 'CREATING') {
            await sleep(30000); // 30 second wait
            
            const importResponse = await forecast.describeDatasetImportJob({
                DatasetImportJobArn: importJobArn
            }).promise();
            
            importStatus = importResponse.Status;
            console.log(`Import job status: ${importStatus}`);
            
            if (importStatus === 'ACTIVE') {
                console.log('Import job completed successfully');
                break;
            } else if (importStatus === 'CREATE_FAILED') {
                throw new Error(`Import job failed: ${importResponse.Message}`);
            }
        }
        
        // Create predictor
        console.log(`Creating predictor: ${predictorName}`);
        await forecast.createPredictor({
            PredictorName: predictorName,
            ForecastHorizon: forecastHorizon,
            InputDataConfig: {
                DatasetGroupArn: (await forecast.describeDatasetGroup({ 
                    DatasetGroupName: datasetGroupName 
                }).promise()).DatasetGroupArn
            },
            FeaturizationConfig: {
                ForecastFrequency: 'D', // Daily forecasts
                ForecastDimensions: ['service']
            },
            OptimizationMetric: 'MAPE' // Mean Absolute Percentage Error
        }).promise();
        
        // Wait for predictor to be created
        console.log('Waiting for predictor to complete...');
        let predictorStatus = 'CREATING';
        let predictorArn = (await forecast.describePredictor({ 
            PredictorArn: (await forecast.describePredictor({ 
                PredictorName: predictorName 
            }).promise()).PredictorArn 
        }).promise()).PredictorArn;
        
        // Poll for status
        while (predictorStatus === 'CREATING') {
            await sleep(30000); // 30 second wait
            
            const predictorResponse = await forecast.describePredictor({
                PredictorArn: predictorArn
            }).promise();
            
            predictorStatus = predictorResponse.Status;
            console.log(`Predictor status: ${predictorStatus}`);
            
            if (predictorStatus === 'ACTIVE') {
                console.log('Predictor created successfully');
                break;
            } else if (predictorStatus === 'CREATE_FAILED') {
                throw new Error(`Predictor creation failed: ${predictorResponse.Message}`);
            }
        }
        
        // Create forecast
        console.log(`Creating forecast: ${forecastName}`);
        await forecast.createForecast({
            ForecastName: forecastName,
            PredictorArn: predictorArn
        }).promise();
        
        // Wait for forecast to be created
        console.log('Waiting for forecast to complete...');
        let forecastStatus = 'CREATING';
        let forecastArn = (await forecast.describeForecast({ 
            ForecastArn: (await forecast.describeForecast({ 
                ForecastName: forecastName 
            }).promise()).ForecastArn 
        }).promise()).ForecastArn;
        
        // Poll for status
        while (forecastStatus === 'CREATING') {
            await sleep(30000); // 30 second wait
            
            const forecastResponse = await forecast.describeForecast({
                ForecastArn: forecastArn
            }).promise();
            
            forecastStatus = forecastResponse.Status;
            console.log(`Forecast status: ${forecastStatus}`);
            
            if (forecastStatus === 'ACTIVE') {
                console.log('Forecast created successfully');
                break;
            } else if (forecastStatus === 'CREATE_FAILED') {
                throw new Error(`Forecast creation failed: ${forecastResponse.Message}`);
            }
        }
        
        // Export forecast
        console.log(`Exporting forecast: ${exportJobName}`);
        await forecast.createForecastExportJob({
            ForecastExportJobName: exportJobName,
            ForecastArn: forecastArn,
            Destination: {
                S3Config: {
                    Path: `s3://${dataBucket}/${forecastPrefix}/`,
                    RoleArn: iamRoleArn
                }
            }
        }).promise();
        
        console.log('Forecast process initiated successfully');
        
        return {
            statusCode: 200,
            body: JSON.stringify({
                message: 'Forecast process initiated successfully',
                datasetGroupName,
                datasetName,
                predictorName,
                forecastName,
                exportJobName
            })
        };
    } catch (error) {
        console.error('Error in forecast creation:', error);
        throw error;
    }
};

// Helper function to pause execution
function sleep(ms) {
    return new Promise(resolve => setTimeout(resolve, ms));
}