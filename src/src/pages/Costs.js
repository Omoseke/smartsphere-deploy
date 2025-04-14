import React from 'react';
import { Box, Typography, Paper, Grid } from '@mui/material';

function Costs() {
  return (
    <Box className="page-container">
      <Typography variant="h4" component="h1" gutterBottom>
        Cost Management
      </Typography>
      <Paper sx={{ p: 3, mb: 3 }}>
        <Typography variant="body1">
          Cost dashboard page is coming soon. The personalized dashboard feature is available now with cost widgets.
        </Typography>
      </Paper>
    </Box>
  );
}

export default Costs;