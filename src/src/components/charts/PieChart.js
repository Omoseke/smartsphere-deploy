import React from 'react';
import { Box, Typography, Paper } from '@mui/material';

const PieChart = ({ data }) => {
  return (
    <Paper elevation={0} variant="outlined" sx={{ p: 2, height: 150, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
      <Typography variant="body2">Pie Chart Placeholder (Would show real chart in production)</Typography>
    </Paper>
  );
};

export default PieChart;