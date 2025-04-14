import React from 'react';
import { Box, Typography, useTheme } from '@mui/material';

const StatusDisplay = ({ data }) => {
  const theme = useTheme();
  
  const statusColors = {
    success: theme.palette.success.main,
    warning: theme.palette.warning.main,
    error: theme.palette.error.main,
    info: theme.palette.info.main,
  };
  
  return (
    <Box sx={{ display: 'flex', alignItems: 'center', p: 2 }}>
      <Box 
        sx={{ 
          width: 12, 
          height: 12, 
          borderRadius: '50%', 
          bgcolor: statusColors[data.status] || theme.palette.grey[500],
          mr: 1,
          boxShadow: '0 0 5px rgba(0,0,0,0.2)'
        }} 
      />
      <Typography variant="body1">
        {data.label || 'Status'}
      </Typography>
    </Box>
  );
};

export default StatusDisplay;