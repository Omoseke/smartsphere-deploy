const synthetics = require('Synthetics');
const log = require('SyntheticsLogger');
const syntheticsConfiguration = synthetics.getConfiguration();

// Set request timeout
syntheticsConfiguration.setRequestTimeout(30000);

// Configure retry strategy
syntheticsConfiguration.setHarFile(true);
syntheticsConfiguration.setDisableStepScreenshots(false);
syntheticsConfiguration.setStepScreenshotRequestsOnly(false);
syntheticsConfiguration.setFailedCanaryMetric(true);

const apiCanaryBlueprint = async function() {
  // Initialize performance measurements
  const performanceData = {
    responseTimeMs: [],
    successCount: 0,
    failureCount: 0,
    totalRequests: 0
  };
  
  // Configure API endpoints to test
  const endpoints = [
    { 
      name: 'Health Check',
      url: '${API_ENDPOINT}/health',
      method: 'GET'
    },
    { 
      name: 'API Info',
      url: '${API_ENDPOINT}/api/info',
      method: 'GET'
    },
    { 
      name: 'Get Users',
      url: '${API_ENDPOINT}/api/users?limit=10',
      method: 'GET',
      headers: { 'Content-Type': 'application/json' }
    },
    { 
      name: 'Get Products',
      url: '${API_ENDPOINT}/api/products',
      method: 'GET',
      headers: { 'Content-Type': 'application/json' }
    }
  ];
  
  // Execute API tests
  for (const endpoint of endpoints) {
    const stepName = `API Performance Test: ${endpoint.name}`;
    
    await synthetics.executeStep(stepName, async () => {
      const startTime = new Date().getTime();
      
      try {
        performanceData.totalRequests++;
        
        // Make the request
        const requestOptions = {
          hostname: new URL(endpoint.url).hostname,
          port: new URL(endpoint.url).port || (endpoint.url.startsWith('https') ? 443 : 80),
          protocol: new URL(endpoint.url).protocol,
          path: new URL(endpoint.url).pathname + (new URL(endpoint.url).search || ''),
          method: endpoint.method,
          headers: endpoint.headers || {}
        };
        
        // Log request details
        log.info(`Making ${endpoint.method} request to ${endpoint.url}`);
        
        // Send request using Synthetics dependency
        const response = await synthetics.getPage({
          url: endpoint.url,
          includeRequestHeaders: true,
          includeResponseHeaders: true,
          includeStatusCode: true
        });
        
        // Calculate response time
        const endTime = new Date().getTime();
        const responseTime = endTime - startTime;
        
        // Log response time
        log.info(`Response time for ${endpoint.name}: ${responseTime}ms`);
        performanceData.responseTimeMs.push(responseTime);
        
        // Check response status
        if (response.statusCode >= 200 && response.statusCode < 300) {
          log.info(`Successfully received response from ${endpoint.url} with status code ${response.statusCode}`);
          performanceData.successCount++;
        } else {
          log.error(`Received error response from ${endpoint.url} with status code ${response.statusCode}`);
          performanceData.failureCount++;
          throw new Error(`Failed to get successful response: ${response.statusCode}`);
        }
      } catch (error) {
        performanceData.failureCount++;
        log.error(`Error calling ${endpoint.url}: ${error.message}`);
        throw error;
      }
    });
  }
  
  // Calculate performance metrics
  const totalResponseTime = performanceData.responseTimeMs.reduce((acc, time) => acc + time, 0);
  const avgResponseTime = totalResponseTime / performanceData.responseTimeMs.length;
  const maxResponseTime = Math.max(...performanceData.responseTimeMs);
  const successRate = (performanceData.successCount / performanceData.totalRequests) * 100;
  
  // Log metrics
  log.info('Performance Test Results:');
  log.info(`Average Response Time: ${avgResponseTime.toFixed(2)}ms`);
  log.info(`Maximum Response Time: ${maxResponseTime}ms`);
  log.info(`Success Rate: ${successRate.toFixed(2)}%`);
  
  // Publish custom metrics to CloudWatch
  synthetics.publishMetric('ResponseTime', 'Average', avgResponseTime);
  synthetics.publishMetric('ResponseTime', 'Maximum', maxResponseTime);
  synthetics.publishMetric('SuccessRate', 'Average', successRate);
  
  return 'Performance testing complete';
};

// Export the handler
exports.handler = async () => {
  return await apiCanaryBlueprint();
};