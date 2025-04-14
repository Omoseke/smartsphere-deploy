import React, { useState } from 'react';
import {
  Box,
  Typography,
  Paper,
  Tabs,
  Tab,
  Grid,
  Card,
  CardContent,
  CardHeader,
  List,
  ListItem,
  ListItemIcon,
  ListItemText,
  Button,
  Chip,
  Divider,
} from '@mui/material';
import {
  Storage,
  CloudQueue,
  Dns,
  Security,
  Database,
  NetworkCheck,
  CloudDownload,
  Cached,
  Code,
} from '@mui/icons-material';

// Infrastructure visualization placeholder
// In a real app, this would be a component that renders an interactive
// visualization of the infrastructure using a library like vis.js
const InfrastructureVisualization = () => (
  <Paper
    sx={{
      height: 500,
      p: 2,
      display: 'flex',
      flexDirection: 'column',
      justifyContent: 'center',
      alignItems: 'center',
      backgroundColor: '#f8f9fa',
    }}
  >
    <Typography variant="h6" color="textSecondary" gutterBottom>
      Infrastructure Topology Visualization
    </Typography>
    <Typography variant="body2" color="textSecondary" align="center">
      Interactive visualization of your cloud infrastructure would appear here.
      <br />
      Built with Terraform and rendered using vis.js for network visualization.
    </Typography>
    <Box
      sx={{
        mt: 2,
        display: 'flex',
        flexWrap: 'wrap',
        justifyContent: 'center',
        gap: 1,
      }}
    >
      <Chip icon={<CloudQueue />} label="VPC" />
      <Chip icon={<Storage />} label="EC2" />
      <Chip icon={<Database />} label="RDS" />
      <Chip icon={<CloudDownload />} label="S3" />
      <Chip icon={<Dns />} label="Route53" />
      <Chip icon={<NetworkCheck />} label="ELB" />
      <Chip icon={<Security />} label="Security Groups" />
    </Box>
  </Paper>
);

function Infrastructure() {
  const [tabValue, setTabValue] = useState(0);

  const handleTabChange = (event, newValue) => {
    setTabValue(newValue);
  };

  // Mock data for infrastructure components
  const infrastructureComponents = {
    compute: [
      { name: 'ECS Cluster', status: 'Healthy', region: 'us-east-1', type: 'Fargate', instances: 4 },
      { name: 'ECS Cluster', status: 'Healthy', region: 'us-west-2', type: 'Fargate', instances: 4 },
    ],
    database: [
      { name: 'RDS PostgreSQL', status: 'Healthy', region: 'us-east-1', type: 'db.t3.medium', storage: '50 GB' },
      { name: 'RDS PostgreSQL', status: 'Healthy', region: 'us-west-2', type: 'db.t3.medium', storage: '50 GB' },
    ],
    storage: [
      { name: 'S3 Bucket - Assets', status: 'Healthy', region: 'us-east-1', objects: '2,345', size: '5.2 GB' },
      { name: 'S3 Bucket - Logs', status: 'Healthy', region: 'us-east-1', objects: '18,902', size: '8.7 GB' },
      { name: 'S3 Bucket - Backups', status: 'Healthy', region: 'us-east-1', objects: '128', size: '45.1 GB' },
    ],
    network: [
      { name: 'VPC - Primary', status: 'Healthy', region: 'us-east-1', cidr: '10.1.0.0/16', subnets: 9 },
      { name: 'VPC - Secondary', status: 'Healthy', region: 'us-west-2', cidr: '10.2.0.0/16', subnets: 9 },
      { name: 'ALB - Primary', status: 'Healthy', region: 'us-east-1', type: 'Application', targets: 4 },
      { name: 'ALB - Secondary', status: 'Healthy', region: 'us-west-2', type: 'Application', targets: 4 },
      { name: 'CloudFront', status: 'Healthy', distribution: 'Global', origins: 2 },
    ],
    security: [
      { name: 'WAF', status: 'Healthy', region: 'Global', rules: 8 },
      { name: 'Security Groups', status: 'Healthy', region: 'us-east-1', count: 12 },
      { name: 'Security Groups', status: 'Healthy', region: 'us-west-2', count: 12 },
      { name: 'IAM Roles', status: 'Healthy', count: 15 },
    ],
  };

  // Helper function to render infrastructure component list
  const renderComponentList = (components) => (
    <List>
      {components.map((component, index) => (
        <React.Fragment key={index}>
          <ListItem>
            <ListItemIcon>
              {getComponentIcon(component.name)}
            </ListItemIcon>
            <ListItemText
              primary={component.name}
              secondary={
                <Box sx={{ display: 'flex', flexWrap: 'wrap', gap: 1, mt: 0.5 }}>
                  <Chip
                    size="small"
                    label={component.status}
                    color={getStatusColor(component.status)}
                  />
                  <Chip size="small" label={`Region: ${component.region}`} variant="outlined" />
                  {Object.entries(component)
                    .filter(([key]) => !['name', 'status', 'region'].includes(key))
                    .map(([key, value]) => (
                      <Chip
                        key={key}
                        size="small"
                        label={`${key.charAt(0).toUpperCase() + key.slice(1)}: ${value}`}
                        variant="outlined"
                      />
                    ))}
                </Box>
              }
            />
          </ListItem>
          {index < components.length - 1 && <Divider variant="inset" component="li" />}
        </React.Fragment>
      ))}
    </List>
  );

  // Helper function for status color
  const getStatusColor = (status) => {
    switch (status.toLowerCase()) {
      case 'healthy':
        return 'success';
      case 'warning':
        return 'warning';
      case 'error':
        return 'error';
      default:
        return 'default';
    }
  };

  // Helper function to get icon for component
  const getComponentIcon = (componentName) => {
    if (componentName.includes('ECS')) return <Storage />;
    if (componentName.includes('RDS')) return <Database />;
    if (componentName.includes('S3')) return <CloudDownload />;
    if (componentName.includes('VPC')) return <NetworkCheck />;
    if (componentName.includes('ALB')) return <Dns />;
    if (componentName.includes('CloudFront')) return <CloudQueue />;
    if (componentName.includes('WAF') || componentName.includes('Security')) return <Security />;
    if (componentName.includes('IAM')) return <Code />;
    return <Cached />;
  };

  return (
    <Box className="page-container">
      <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 3 }}>
        <Typography variant="h4" component="h1" gutterBottom>
          Infrastructure
        </Typography>
        <Button variant="outlined" startIcon={<Cached />}>
          Refresh
        </Button>
      </Box>

      <Tabs
        value={tabValue}
        onChange={handleTabChange}
        indicatorColor="primary"
        textColor="primary"
        variant="scrollable"
        scrollButtons="auto"
        sx={{ mb: 3 }}
      >
        <Tab label="Topology" />
        <Tab label="Compute" />
        <Tab label="Database" />
        <Tab label="Storage" />
        <Tab label="Network" />
        <Tab label="Security" />
      </Tabs>

      {tabValue === 0 && (
        <InfrastructureVisualization />
      )}

      {tabValue === 1 && (
        <Paper sx={{ p: 2 }}>
          <Typography variant="h6" gutterBottom>
            Compute Resources
          </Typography>
          {renderComponentList(infrastructureComponents.compute)}
        </Paper>
      )}

      {tabValue === 2 && (
        <Paper sx={{ p: 2 }}>
          <Typography variant="h6" gutterBottom>
            Database Resources
          </Typography>
          {renderComponentList(infrastructureComponents.database)}
        </Paper>
      )}

      {tabValue === 3 && (
        <Paper sx={{ p: 2 }}>
          <Typography variant="h6" gutterBottom>
            Storage Resources
          </Typography>
          {renderComponentList(infrastructureComponents.storage)}
        </Paper>
      )}

      {tabValue === 4 && (
        <Paper sx={{ p: 2 }}>
          <Typography variant="h6" gutterBottom>
            Network Resources
          </Typography>
          {renderComponentList(infrastructureComponents.network)}
        </Paper>
      )}

      {tabValue === 5 && (
        <Paper sx={{ p: 2 }}>
          <Typography variant="h6" gutterBottom>
            Security Resources
          </Typography>
          {renderComponentList(infrastructureComponents.security)}
        </Paper>
      )}

      {/* Statistics Cards */}
      <Grid container spacing={3} sx={{ mt: 3 }}>
        <Grid item xs={12} md={4}>
          <Card>
            <CardHeader title="Resource Summary" />
            <CardContent>
              <Box sx={{ display: 'flex', justifyContent: 'space-between', mb: 1 }}>
                <Typography>Total Resources:</Typography>
                <Typography fontWeight="bold">42</Typography>
              </Box>
              <Box sx={{ display: 'flex', justifyContent: 'space-between', mb: 1 }}>
                <Typography>Regions:</Typography>
                <Typography fontWeight="bold">2</Typography>
              </Box>
              <Box sx={{ display: 'flex', justifyContent: 'space-between', mb: 1 }}>
                <Typography>Health Status:</Typography>
                <Chip size="small" label="All Healthy" color="success" />
              </Box>
            </CardContent>
          </Card>
        </Grid>
        <Grid item xs={12} md={4}>
          <Card>
            <CardHeader title="Multi-Region Status" />
            <CardContent>
              <Box sx={{ display: 'flex', justifyContent: 'space-between', mb: 1 }}>
                <Typography>Primary (us-east-1):</Typography>
                <Chip size="small" label="Active" color="success" />
              </Box>
              <Box sx={{ display: 'flex', justifyContent: 'space-between', mb: 1 }}>
                <Typography>Secondary (us-west-2):</Typography>
                <Chip size="small" label="Standby" color="info" />
              </Box>
              <Box sx={{ display: 'flex', justifyContent: 'space-between', mb: 1 }}>
                <Typography>Last Failover Test:</Typography>
                <Typography>2025-03-15</Typography>
              </Box>
            </CardContent>
          </Card>
        </Grid>
        <Grid item xs={12} md={4}>
          <Card>
            <CardHeader title="Last Infrastructure Update" />
            <CardContent>
              <Box sx={{ display: 'flex', justifyContent: 'space-between', mb: 1 }}>
                <Typography>Timestamp:</Typography>
                <Typography>2025-04-10 08:45:22</Typography>
              </Box>
              <Box sx={{ display: 'flex', justifyContent: 'space-between', mb: 1 }}>
                <Typography>Terraform Version:</Typography>
                <Typography>1.8.0</Typography>
              </Box>
              <Box sx={{ display: 'flex', justifyContent: 'space-between', mb: 1 }}>
                <Typography>Applied By:</Typography>
                <Typography>CI/CD Pipeline</Typography>
              </Box>
            </CardContent>
          </Card>
        </Grid>
      </Grid>
    </Box>
  );
}

export default Infrastructure;