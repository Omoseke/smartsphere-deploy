import React from 'react';
import { Box, Typography } from '@mui/material';

const MetricDisplay = ({ data }) => {
  return (
    <Box sx={{ textAlign: 'center', py: 2 }}>
      <Typography variant="h3" color="primary" fontWeight="bold">
        {data.value || '0'}
      </Typography>
      <Typography variant="body2" color="text.secondary">
        {data.label || 'Metric'}
      </Typography>
    </Box>
  );
};

export default MetricDisplay;