import React from 'react';
import { Box, Typography, Paper, Grid } from '@mui/material';

function Security() {
  return (
    <Box className="page-container">
      <Typography variant="h4" component="h1" gutterBottom>
        Security
      </Typography>
      <Paper sx={{ p: 3, mb: 3 }}>
        <Typography variant="body1">
          Security dashboard page is coming soon. The personalized dashboard feature is available now.
        </Typography>
      </Paper>
    </Box>
  );
}

export default Security;