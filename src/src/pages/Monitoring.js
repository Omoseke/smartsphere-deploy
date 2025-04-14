import React, { useState } from 'react';
import {
  Box,
  Typography,
  Paper,
  Grid,
  Card,
  CardContent,
  CardHeader,
  FormControl,
  InputLabel,
  Select,
  MenuItem,
  Button,
  Tabs,
  Tab,
  List,
  ListItem,
  ListItemText,
  Divider,
  Chip,
} from '@mui/material';
import {
  Timeline,
  Speed,
  Memory,
  Storage,
  Public,
  Warning,
  NotificationsActive,
  CloudQueue,
  Refresh,
} from '@mui/icons-material';

// Charts would be implemented with Chart.js or similar library
// This is a placeholder component
const ChartPlaceholder = ({ title, height = 300 }) => (
  <Paper
    sx={{
      height,
      p: 2,
      display: 'flex',
      flexDirection: 'column',
      justifyContent: 'center',
      alignItems: 'center',
      backgroundColor: '#f8f9fa',
    }}
  >
    <Typography variant="body1" color="textSecondary" gutterBottom>
      {title}
    </Typography>
    <Typography variant="body2" color="textSecondary" align="center">
      Charts would be implemented using Chart.js
      <br />
      Real-time metrics would be displayed here
    </Typography>
  </Paper>
);

function Monitoring() {
  const [timeRange, setTimeRange] = useState('24h');
  const [environment, setEnvironment] = useState('production');
  const [tabValue, setTabValue] = useState(0);

  const handleTabChange = (event, newValue) => {
    setTabValue(newValue);
  };

  // Mock alerts data
  const alerts = [
    {
      id: 'alert-001',
      severity: 'critical',
      title: 'High CPU Usage',
      resource: 'ECS Cluster - Web Services',
      timestamp: '2025-04-14 10:23:45',
      status: 'active',
    },
    {
      id: 'alert-002',
      severity: 'warning',
      title: 'Elevated Error Rate',
      resource: 'API Gateway - /payments',
      timestamp: '2025-04-14 09:15:22',
      status: 'active',
    },
    {
      id: 'alert-003',
      severity: 'info',
      title: 'Deployment Completed',
      resource: 'CI/CD Pipeline',
      timestamp: '2025-04-14 08:05:11',
      status: 'resolved',
    },
    {
      id: 'alert-004',
      severity: 'warning',
      title: 'Database Connection Spike',
      resource: 'RDS - Main',
      timestamp: '2025-04-14 07:45:33',
      status: 'resolved',
    },
  ];

  // Helper function for alert severity color
  const getSeverityColor = (severity) => {
    switch (severity.toLowerCase()) {
      case 'critical':
        return 'error';
      case 'warning':
        return 'warning';
      case 'info':
        return 'info';
      default:
        return 'default';
    }
  };

  // Helper function for alert status color
  const getStatusColor = (status) => {
    switch (status.toLowerCase()) {
      case 'active':
        return 'error';
      case 'resolved':
        return 'success';
      default:
        return 'default';
    }
  };

  return (
    <Box className="page-container">
      <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 3 }}>
        <Typography variant="h4" component="h1" gutterBottom>
          Monitoring
        </Typography>
        <Button variant="outlined" startIcon={<Refresh />}>
          Refresh
        </Button>
      </Box>

      {/* Filter Controls */}
      <Paper sx={{ p: 2, mb: 3 }}>
        <Grid container spacing={2} alignItems="center">
          <Grid item xs={12} sm={4}>
            <FormControl fullWidth size="small">
              <InputLabel id="time-range-label">Time Range</InputLabel>
              <Select
                labelId="time-range-label"
                value={timeRange}
                label="Time Range"
                onChange={(e) => setTimeRange(e.target.value)}
              >
                <MenuItem value="1h">Last Hour</MenuItem>
                <MenuItem value="6h">Last 6 Hours</MenuItem>
                <MenuItem value="24h">Last 24 Hours</MenuItem>
                <MenuItem value="7d">Last 7 Days</MenuItem>
                <MenuItem value="30d">Last 30 Days</MenuItem>
              </Select>
            </FormControl>
          </Grid>
          <Grid item xs={12} sm={4}>
            <FormControl fullWidth size="small">
              <InputLabel id="environment-label">Environment</InputLabel>
              <Select
                labelId="environment-label"
                value={environment}
                label="Environment"
                onChange={(e) => setEnvironment(e.target.value)}
              >
                <MenuItem value="development">Development</MenuItem>
                <MenuItem value="staging">Staging</MenuItem>
                <MenuItem value="production">Production</MenuItem>
              </Select>
            </FormControl>
          </Grid>
          <Grid item xs={12} sm={4}>
            <Box sx={{ display: 'flex', justifyContent: 'flex-end' }}>
              <Button
                variant="outlined"
                color="primary"
              >
                Apply Filters
              </Button>
            </Box>
          </Grid>
        </Grid>
      </Paper>

      {/* Tabs for different metric categories */}
      <Tabs
        value={tabValue}
        onChange={handleTabChange}
        indicatorColor="primary"
        textColor="primary"
        variant="scrollable"
        scrollButtons="auto"
        sx={{ mb: 3 }}
      >
        <Tab icon={<Speed />} label="Performance" />
        <Tab icon={<Memory />} label="Resources" />
        <Tab icon={<Public />} label="Endpoints" />
        <Tab icon={<Storage />} label="Database" />
        <Tab icon={<CloudQueue />} label="Services" />
        <Tab icon={<Warning />} label="Alerts" />
      </Tabs>

      {/* Performance Metrics */}
      {tabValue === 0 && (
        <Grid container spacing={3}>
          <Grid item xs={12} md={6}>
            <ChartPlaceholder title="API Response Time (ms)" />
          </Grid>
          <Grid item xs={12} md={6}>
            <ChartPlaceholder title="Request Throughput (req/s)" />
          </Grid>
          <Grid item xs={12} md={6}>
            <ChartPlaceholder title="Error Rate (%)" />
          </Grid>
          <Grid item xs={12} md={6}>
            <ChartPlaceholder title="Page Load Time (ms)" />
          </Grid>
        </Grid>
      )}

      {/* Resource Metrics */}
      {tabValue === 1 && (
        <Grid container spacing={3}>
          <Grid item xs={12} md={6}>
            <ChartPlaceholder title="CPU Usage (%)" />
          </Grid>
          <Grid item xs={12} md={6}>
            <ChartPlaceholder title="Memory Usage (%)" />
          </Grid>
          <Grid item xs={12} md={6}>
            <ChartPlaceholder title="Disk I/O (ops/s)" />
          </Grid>
          <Grid item xs={12} md={6}>
            <ChartPlaceholder title="Network Traffic (MB/s)" />
          </Grid>
        </Grid>
      )}

      {/* Endpoint Metrics */}
      {tabValue === 2 && (
        <Grid container spacing={3}>
          <Grid item xs={12} md={6}>
            <ChartPlaceholder title="Endpoint Response Times (ms)" />
          </Grid>
          <Grid item xs={12} md={6}>
            <ChartPlaceholder title="Endpoint Error Rates (%)" />
          </Grid>
          <Grid item xs={12}>
            <Paper sx={{ p: 2 }}>
              <Typography variant="h6" gutterBottom>
                Top 5 Slowest Endpoints
              </Typography>
              <Box sx={{ height: 300, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                <Typography variant="body2" color="textSecondary">
                  Endpoint performance data would be displayed here
                </Typography>
              </Box>
            </Paper>
          </Grid>
        </Grid>
      )}

      {/* Database Metrics */}
      {tabValue === 3 && (
        <Grid container spacing={3}>
          <Grid item xs={12} md={6}>
            <ChartPlaceholder title="Database Query Execution Time (ms)" />
          </Grid>
          <Grid item xs={12} md={6}>
            <ChartPlaceholder title="Database Connections" />
          </Grid>
          <Grid item xs={12} md={6}>
            <ChartPlaceholder title="Database CPU Usage (%)" />
          </Grid>
          <Grid item xs={12} md={6}>
            <ChartPlaceholder title="Database Storage Usage (%)" />
          </Grid>
        </Grid>
      )}

      {/* Services Metrics */}
      {tabValue === 4 && (
        <Grid container spacing={3}>
          <Grid item xs={12} md={6}>
            <ChartPlaceholder title="Service Health Status" />
          </Grid>
          <Grid item xs={12} md={6}>
            <ChartPlaceholder title="Service Response Times (ms)" />
          </Grid>
          <Grid item xs={12}>
            <Paper sx={{ p: 2 }}>
              <Typography variant="h6" gutterBottom>
                Service Dependencies
              </Typography>
              <Box sx={{ height: 300, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                <Typography variant="body2" color="textSecondary">
                  Service dependency visualization would be displayed here
                </Typography>
              </Box>
            </Paper>
          </Grid>
        </Grid>
      )}

      {/* Alerts Tab */}
      {tabValue === 5 && (
        <Grid container spacing={3}>
          <Grid item xs={12}>
            <Paper>
              <List>
                {alerts.map((alert, index) => (
                  <React.Fragment key={alert.id}>
                    <ListItem
                      secondaryAction={
                        <Chip
                          size="small"
                          label={alert.status}
                          color={getStatusColor(alert.status)}
                        />
                      }
                    >
                      <ListItemText
                        primary={
                          <Box sx={{ display: 'flex', alignItems: 'center' }}>
                            <Chip
                              size="small"
                              label={alert.severity}
                              color={getSeverityColor(alert.severity)}
                              sx={{ mr: 1 }}
                            />
                            <Typography variant="subtitle1">{alert.title}</Typography>
                          </Box>
                        }
                        secondary={
                          <>
                            <Typography component="span" variant="body2" color="text.primary">
                              {alert.resource}
                            </Typography>
                            {` - ${alert.timestamp}`}
                          </>
                        }
                      />
                    </ListItem>
                    {index < alerts.length - 1 && <Divider />}
                  </React.Fragment>
                ))}
              </List>
            </Paper>
          </Grid>
          <Grid item xs={12}>
            <Card>
              <CardHeader
                title="Alert Statistics"
                action={
                  <Button
                    size="small"
                    startIcon={<NotificationsActive />}
                    color="primary"
                  >
                    Configure Alerts
                  </Button>
                }
              />
              <CardContent>
                <Grid container spacing={2}>
                  <Grid item xs={6} md={3}>
                    <Box sx={{ textAlign: 'center' }}>
                      <Typography variant="h4" color="error">
                        1
                      </Typography>
                      <Typography variant="body2" color="textSecondary">
                        Critical
                      </Typography>
                    </Box>
                  </Grid>
                  <Grid item xs={6} md={3}>
                    <Box sx={{ textAlign: 'center' }}>
                      <Typography variant="h4" color="warning.main">
                        1
                      </Typography>
                      <Typography variant="body2" color="textSecondary">
                        Warning
                      </Typography>
                    </Box>
                  </Grid>
                  <Grid item xs={6} md={3}>
                    <Box sx={{ textAlign: 'center' }}>
                      <Typography variant="h4" color="info.main">
                        1
                      </Typography>
                      <Typography variant="body2" color="textSecondary">
                        Info
                      </Typography>
                    </Box>
                  </Grid>
                  <Grid item xs={6} md={3}>
                    <Box sx={{ textAlign: 'center' }}>
                      <Typography variant="h4" color="success.main">
                        2
                      </Typography>
                      <Typography variant="body2" color="textSecondary">
                        Resolved
                      </Typography>
                    </Box>
                  </Grid>
                </Grid>
              </CardContent>
            </Card>
          </Grid>
        </Grid>
      )}

      {/* Anomaly Detection Card */}
      <Paper sx={{ p: 2, mt: 3 }}>
        <Box sx={{ display: 'flex', alignItems: 'center', mb: 2 }}>
          <Timeline color="primary" sx={{ mr: 1 }} />
          <Typography variant="h6">Anomaly Detection</Typography>
        </Box>
        <Typography variant="body2" paragraph>
          AI-powered anomaly detection is actively monitoring your systems and will alert you to unusual patterns or behaviors.
        </Typography>
        <Grid container spacing={2}>
          <Grid item xs={12} md={4}>
            <Card variant="outlined">
              <CardContent>
                <Typography variant="subtitle1" gutterBottom>
                  Last Anomaly Detected
                </Typography>
                <Typography variant="body2" color="textSecondary">
                  Unusual spike in API errors
                </Typography>
                <Typography variant="body2">
                  2025-04-13 15:42:18
                </Typography>
              </CardContent>
            </Card>
          </Grid>
          <Grid item xs={12} md={4}>
            <Card variant="outlined">
              <CardContent>
                <Typography variant="subtitle1" gutterBottom>
                  Baseline Confidence
                </Typography>
                <Typography variant="h5" color="primary">
                  97.8%
                </Typography>
                <Typography variant="body2" color="textSecondary">
                  Based on 30 days of data
                </Typography>
              </CardContent>
            </Card>
          </Grid>
          <Grid item xs={12} md={4}>
            <Card variant="outlined">
              <CardContent>
                <Typography variant="subtitle1" gutterBottom>
                  Detection Sensitivity
                </Typography>
                <Typography variant="body1">
                  Medium
                </Typography>
                <Button size="small" sx={{ mt: 1 }}>
                  Adjust Settings
                </Button>
              </CardContent>
            </Card>
          </Grid>
        </Grid>
      </Paper>
    </Box>
  );
}

export default Monitoring;