import React, { useState } from 'react';
import {
  Box,
  Typography,
  Paper,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  Chip,
  Button,
  Dialog,
  DialogActions,
  DialogContent,
  DialogContentText,
  DialogTitle,
  TextField,
  FormControl,
  InputLabel,
  Select,
  MenuItem,
  Grid,
  Card,
  CardContent,
  CardHeader,
  Divider,
  useMediaQuery,
  useTheme,
} from '@mui/material';
import {
  RefreshOutlined,
  AddCircleOutline,
  PlayArrow,
  Pause,
  Replay,
  History,
} from '@mui/icons-material';

function Deployments() {
  const [openNewDialog, setOpenNewDialog] = useState(false);
  const [openRollbackDialog, setOpenRollbackDialog] = useState(false);
  const [selectedDeployment, setSelectedDeployment] = useState(null);
  
  // Mock data for the table
  const deployments = [
    {
      id: 'dep-12345',
      version: 'v1.2.3',
      environment: 'Production',
      status: 'Deployed',
      type: 'Blue-Green',
      timestamp: '2025-04-12 14:30:25',
      deployed_by: 'CI/CD Pipeline',
      commit: 'a1b2c3d',
    },
    {
      id: 'dep-12344',
      version: 'v1.2.2',
      environment: 'Production',
      status: 'Inactive',
      type: 'Blue-Green',
      timestamp: '2025-04-10 10:15:30',
      deployed_by: 'CI/CD Pipeline',
      commit: 'e4f5g6h',
    },
    {
      id: 'dep-12343',
      version: 'v1.2.3',
      environment: 'Staging',
      status: 'Deployed',
      type: 'Regular',
      timestamp: '2025-04-11 09:45:22',
      deployed_by: 'CI/CD Pipeline',
      commit: 'a1b2c3d',
    },
    {
      id: 'dep-12342',
      version: 'v1.2.3',
      environment: 'Development',
      status: 'Deployed',
      type: 'Regular',
      timestamp: '2025-04-10 13:20:15',
      deployed_by: 'CI/CD Pipeline',
      commit: 'a1b2c3d',
    },
    {
      id: 'dep-12341',
      version: 'v1.2.1',
      environment: 'Production',
      status: 'Archived',
      type: 'Regular',
      timestamp: '2025-04-05 08:30:10',
      deployed_by: 'Manual',
      commit: 'i7j8k9l',
    },
  ];

  // Deployments statistics
  const statistics = {
    total: 128,
    successful: 118,
    failed: 7,
    inProgress: 3,
    averageDeployTime: '4m 12s',
    deploymentFrequency: '3.2 / day',
  };

  // Open rollback dialog and set the selected deployment
  const handleRollback = (deployment) => {
    setSelectedDeployment(deployment);
    setOpenRollbackDialog(true);
  };

  const handleCloseRollbackDialog = () => {
    setOpenRollbackDialog(false);
    setSelectedDeployment(null);
  };

  // Helper function for status chip color
  const getStatusColor = (status) => {
    switch (status.toLowerCase()) {
      case 'deployed':
        return 'success';
      case 'inactive':
        return 'default';
      case 'failed':
        return 'error';
      case 'in progress':
        return 'info';
      case 'archived':
        return 'default';
      default:
        return 'default';
    }
  };

  // Use useMediaQuery for responsive column visibility
  const isXs = useMediaQuery((theme) => theme.breakpoints.down('sm'));
  const isSm = useMediaQuery((theme) => theme.breakpoints.between('sm', 'md'));
  
  // Define visible columns based on screen size
  const visibleColumns = React.useMemo(() => {
    // For mobile view
    if (isXs) {
      return {
        id: false,
        version: true,
        environment: true,
        status: true,
        type: false,
        timestamp: false,
        deployed_by: false,
        commit: false,
        actions: true,
      };
    }
    
    // For tablet view
    if (isSm) {
      return {
        id: false,
        version: true,
        environment: true,
        status: true,
        type: true,
        timestamp: true,
        deployed_by: false,
        commit: false,
        actions: true,
      };
    }
    
    // For desktop, show all columns
    return {
      id: true,
      version: true,
      environment: true,
      status: true,
      type: true,
      timestamp: true,
      deployed_by: true,
      commit: true,
      actions: true,
    };
  }, [isXs, isSm]);

  return (
    <Box className="page-container">
      <Box sx={{ 
        display: 'flex', 
        flexDirection: { xs: 'column', sm: 'row' },
        justifyContent: 'space-between', 
        alignItems: { xs: 'stretch', sm: 'center' }, 
        mb: 3,
        gap: { xs: 2, sm: 0 }
      }}>
        <Typography variant="h4" component="h1" gutterBottom sx={{ mb: { xs: 0, sm: 2 } }}>
          Deployments
        </Typography>
        <Box sx={{ 
          display: 'flex', 
          flexDirection: { xs: 'row' }, 
          justifyContent: { xs: 'flex-end' },
          width: { xs: '100%', sm: 'auto' },
          gap: 1
        }}>
          <Button 
            variant="outlined" 
            startIcon={<RefreshOutlined />}
            size="small"
          >
            Refresh
          </Button>
          <Button 
            variant="contained" 
            color="primary" 
            startIcon={<AddCircleOutline />}
            onClick={() => setOpenNewDialog(true)}
            size="small"
          >
            New
          </Button>
        </Box>
      </Box>
      
      {/* Statistics Cards */}
      <Grid container spacing={{ xs: 2, sm: 3 }} sx={{ mb: 3 }} className="responsive-grid">
        <Grid item xs={6} md={6} lg={3}>
          <Card elevation={2} sx={{ height: '100%' }}>
            <CardContent sx={{ p: { xs: 1.5, sm: 2 } }}>
              <Typography color="textSecondary" gutterBottom sx={{ fontSize: { xs: '0.75rem', sm: '0.875rem' } }}>
                Total Deployments
              </Typography>
              <Typography variant="h4" sx={{ fontSize: { xs: '1.5rem', sm: '2rem' } }}>
                {statistics.total}
              </Typography>
            </CardContent>
          </Card>
        </Grid>
        <Grid item xs={6} md={6} lg={3}>
          <Card elevation={2} sx={{ height: '100%' }}>
            <CardContent sx={{ p: { xs: 1.5, sm: 2 } }}>
              <Typography color="textSecondary" gutterBottom sx={{ fontSize: { xs: '0.75rem', sm: '0.875rem' } }}>
                Success Rate
              </Typography>
              <Typography variant="h4" sx={{ fontSize: { xs: '1.5rem', sm: '2rem' } }}>
                {Math.round((statistics.successful / statistics.total) * 100)}%
              </Typography>
            </CardContent>
          </Card>
        </Grid>
        <Grid item xs={6} md={6} lg={3}>
          <Card elevation={2} sx={{ height: '100%' }}>
            <CardContent sx={{ p: { xs: 1.5, sm: 2 } }}>
              <Typography color="textSecondary" gutterBottom sx={{ fontSize: { xs: '0.75rem', sm: '0.875rem' } }}>
                Avg. Deploy Time
              </Typography>
              <Typography variant="h4" sx={{ fontSize: { xs: '1.5rem', sm: '2rem' } }}>
                {statistics.averageDeployTime}
              </Typography>
            </CardContent>
          </Card>
        </Grid>
        <Grid item xs={6} md={6} lg={3}>
          <Card elevation={2} sx={{ height: '100%' }}>
            <CardContent sx={{ p: { xs: 1.5, sm: 2 } }}>
              <Typography color="textSecondary" gutterBottom sx={{ fontSize: { xs: '0.75rem', sm: '0.875rem' } }}>
                Frequency
              </Typography>
              <Typography variant="h4" sx={{ fontSize: { xs: '1.5rem', sm: '2rem' } }}>
                {statistics.deploymentFrequency}
              </Typography>
            </CardContent>
          </Card>
        </Grid>
      </Grid>

      {/* Deployments Table with Responsive Design */}
      <Paper elevation={2} sx={{ borderRadius: '8px', overflow: 'hidden' }}>
        <TableContainer className="table-container">
          <Table sx={{ minWidth: { xs: 300, sm: 650 } }} aria-label="deployments table" size="small">
            <TableHead>
              <TableRow>
                {visibleColumns.id && <TableCell>ID</TableCell>}
                {visibleColumns.version && <TableCell>Version</TableCell>}
                {visibleColumns.environment && <TableCell>Environment</TableCell>}
                {visibleColumns.status && <TableCell>Status</TableCell>}
                {visibleColumns.type && <TableCell>Type</TableCell>}
                {visibleColumns.timestamp && <TableCell>Timestamp</TableCell>}
                {visibleColumns.deployed_by && <TableCell>Deployed By</TableCell>}
                {visibleColumns.commit && <TableCell>Commit</TableCell>}
                {visibleColumns.actions && <TableCell align="right">Actions</TableCell>}
              </TableRow>
            </TableHead>
            <TableBody>
              {deployments.map((row) => (
                <TableRow
                  key={row.id}
                  sx={{ 
                    '&:last-child td, &:last-child th': { border: 0 },
                    '&:hover': { backgroundColor: 'rgba(0, 0, 0, 0.04)' }
                  }}
                >
                  {visibleColumns.id && (
                    <TableCell component="th" scope="row" sx={{ 
                      fontSize: { xs: '0.75rem', sm: '0.875rem' },
                      py: { xs: 1, sm: 1.5 }
                    }}>
                      {row.id}
                    </TableCell>
                  )}
                  
                  {visibleColumns.version && (
                    <TableCell sx={{ 
                      fontSize: { xs: '0.75rem', sm: '0.875rem' },
                      py: { xs: 1, sm: 1.5 }
                    }}>
                      {row.version}
                    </TableCell>
                  )}
                  
                  {visibleColumns.environment && (
                    <TableCell sx={{ 
                      fontSize: { xs: '0.75rem', sm: '0.875rem' },
                      py: { xs: 1, sm: 1.5 }
                    }}>
                      {row.environment}
                    </TableCell>
                  )}
                  
                  {visibleColumns.status && (
                    <TableCell sx={{ py: { xs: 1, sm: 1.5 } }}>
                      <Chip 
                        label={row.status} 
                        color={getStatusColor(row.status)} 
                        size="small" 
                        sx={{ 
                          fontSize: { xs: '0.7rem', sm: '0.75rem' },
                          height: { xs: 22, sm: 24 }
                        }}
                      />
                    </TableCell>
                  )}
                  
                  {visibleColumns.type && (
                    <TableCell sx={{ 
                      fontSize: { xs: '0.75rem', sm: '0.875rem' },
                      py: { xs: 1, sm: 1.5 }
                    }}>
                      {row.type}
                    </TableCell>
                  )}
                  
                  {visibleColumns.timestamp && (
                    <TableCell sx={{ 
                      fontSize: { xs: '0.75rem', sm: '0.875rem' },
                      py: { xs: 1, sm: 1.5 }
                    }}>
                      {row.timestamp}
                    </TableCell>
                  )}
                  
                  {visibleColumns.deployed_by && (
                    <TableCell sx={{ 
                      fontSize: { xs: '0.75rem', sm: '0.875rem' },
                      py: { xs: 1, sm: 1.5 }
                    }}>
                      {row.deployed_by}
                    </TableCell>
                  )}
                  
                  {visibleColumns.commit && (
                    <TableCell sx={{ 
                      fontSize: { xs: '0.75rem', sm: '0.875rem' },
                      py: { xs: 1, sm: 1.5 }
                    }}>
                      {row.commit}
                    </TableCell>
                  )}
                  
                  {visibleColumns.actions && (
                    <TableCell align="right" sx={{ py: { xs: 1, sm: 1.5 } }}>
                      <Button
                        size="small"
                        startIcon={<History />}
                        onClick={() => handleRollback(row)}
                        disabled={row.status !== 'Inactive' && row.status !== 'Archived'}
                        sx={{ 
                          fontSize: { xs: '0.7rem', sm: '0.75rem' },
                          py: { xs: 0.5, sm: 0.75 },
                          minWidth: { xs: 'auto', sm: '80px' }
                        }}
                      >
                        {isXs ? '' : 'Rollback'}
                      </Button>
                    </TableCell>
                  )}
                </TableRow>
              ))}
            </TableBody>
          </Table>
        </TableContainer>
      </Paper>

      {/* New Deployment Dialog - Mobile Responsive */}
      <Dialog 
        open={openNewDialog} 
        onClose={() => setOpenNewDialog(false)}
        fullScreen={isXs}
        maxWidth="sm"
        fullWidth
      >
        <DialogTitle sx={{ 
          pb: 1,
          fontSize: { xs: '1.25rem', sm: '1.5rem' }
        }}>
          New Deployment
        </DialogTitle>
        <DialogContent sx={{ pt: { xs: 1, sm: 2 } }}>
          <DialogContentText sx={{ mb: 2, fontSize: { xs: '0.875rem', sm: '1rem' } }}>
            Fill in the details to create a new deployment.
          </DialogContentText>
          <Grid container spacing={{ xs: 1, sm: 2 }}>
            <Grid item xs={12} sm={6}>
              <FormControl fullWidth margin="normal" size="small">
                <InputLabel id="environment-label">Environment</InputLabel>
                <Select
                  labelId="environment-label"
                  label="Environment"
                  defaultValue="development"
                  sx={{ fontSize: { xs: '0.875rem', sm: '1rem' } }}
                >
                  <MenuItem value="development">Development</MenuItem>
                  <MenuItem value="staging">Staging</MenuItem>
                  <MenuItem value="production">Production</MenuItem>
                </Select>
              </FormControl>
            </Grid>
            <Grid item xs={12} sm={6}>
              <FormControl fullWidth margin="normal" size="small">
                <InputLabel id="deployment-type-label">Deployment Type</InputLabel>
                <Select
                  labelId="deployment-type-label"
                  label="Deployment Type"
                  defaultValue="regular"
                  sx={{ fontSize: { xs: '0.875rem', sm: '1rem' } }}
                >
                  <MenuItem value="regular">Regular</MenuItem>
                  <MenuItem value="blue-green">Blue-Green</MenuItem>
                  <MenuItem value="canary">Canary</MenuItem>
                </Select>
              </FormControl>
            </Grid>
            <Grid item xs={12}>
              <TextField
                fullWidth
                margin="normal"
                label="Version"
                variant="outlined"
                size="small"
                placeholder="e.g., v1.2.3"
                sx={{ fontSize: { xs: '0.875rem', sm: '1rem' } }}
                InputProps={{
                  style: { fontSize: '0.875rem' }
                }}
                InputLabelProps={{
                  style: { fontSize: '0.875rem' }
                }}
              />
            </Grid>
            <Grid item xs={12}>
              <TextField
                fullWidth
                margin="normal"
                label="Commit Hash"
                variant="outlined"
                size="small"
                placeholder="e.g., a1b2c3d"
                sx={{ fontSize: { xs: '0.875rem', sm: '1rem' } }}
                InputProps={{
                  style: { fontSize: '0.875rem' }
                }}
                InputLabelProps={{
                  style: { fontSize: '0.875rem' }
                }}
              />
            </Grid>
          </Grid>
        </DialogContent>
        <DialogActions sx={{ px: { xs: 2, sm: 3 }, pb: { xs: 2, sm: 2 } }}>
          <Button 
            onClick={() => setOpenNewDialog(false)}
            size="small"
            sx={{ fontSize: { xs: '0.8rem', sm: '0.875rem' } }}
          >
            Cancel
          </Button>
          <Button 
            variant="contained" 
            color="primary" 
            onClick={() => setOpenNewDialog(false)}
            size="small"
            sx={{ fontSize: { xs: '0.8rem', sm: '0.875rem' } }}
          >
            Deploy
          </Button>
        </DialogActions>
      </Dialog>

      {/* Rollback Dialog - Mobile Responsive */}
      <Dialog 
        open={openRollbackDialog} 
        onClose={handleCloseRollbackDialog}
        fullScreen={isXs}
        maxWidth="sm"
        fullWidth
      >
        <DialogTitle sx={{ 
          pb: 1,
          fontSize: { xs: '1.25rem', sm: '1.5rem' } 
        }}>
          Rollback Confirmation
        </DialogTitle>
        <DialogContent sx={{ pt: { xs: 1, sm: 2 } }}>
          <DialogContentText sx={{ fontSize: { xs: '0.875rem', sm: '1rem' } }}>
            Are you sure you want to rollback to <strong>{selectedDeployment?.version}</strong> in <strong>{selectedDeployment?.environment}</strong>?
            <br /><br />
            This action will replace the current active deployment.
          </DialogContentText>
        </DialogContent>
        <DialogActions sx={{ px: { xs: 2, sm: 3 }, pb: { xs: 2, sm: 2 } }}>
          <Button 
            onClick={handleCloseRollbackDialog}
            size="small"
            sx={{ fontSize: { xs: '0.8rem', sm: '0.875rem' } }}
          >
            Cancel
          </Button>
          <Button
            variant="contained"
            color="secondary"
            onClick={handleCloseRollbackDialog}
            size="small"
            sx={{ fontSize: { xs: '0.8rem', sm: '0.875rem' } }}
          >
            Confirm Rollback
          </Button>
        </DialogActions>
      </Dialog>
    </Box>
  );
}

export default Deployments;