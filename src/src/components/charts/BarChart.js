import React from 'react';
import { Box, Typography, Paper } from '@mui/material';

const BarChart = ({ data }) => {
  return (
    <Paper elevation={0} variant="outlined" sx={{ p: 2, height: 150, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
      <Typography variant="body2">Bar Chart Placeholder (Would show real chart in production)</Typography>
    </Paper>
  );
};

export default BarChart;