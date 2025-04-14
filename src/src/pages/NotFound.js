import React from 'react';
import { Box, Typography, Button, Paper } from '@mui/material';
import { Home } from '@mui/icons-material';
import { useNavigate } from 'react-router-dom';

function NotFound() {
  const navigate = useNavigate();

  return (
    <Box
      sx={{
        display: 'flex',
        flexDirection: 'column',
        alignItems: 'center',
        justifyContent: 'center',
        minHeight: 'calc(100vh - 150px)',
        px: 3,
      }}
    >
      <Paper
        sx={{
          py: 5,
          px: 4,
          display: 'flex',
          flexDirection: 'column',
          alignItems: 'center',
          maxWidth: 500,
          width: '100%',
        }}
      >
        <Typography variant="h1" color="primary" sx={{ fontSize: 120, fontWeight: 'bold' }}>
          404
        </Typography>
        <Typography variant="h5" gutterBottom align="center">
          Page Not Found
        </Typography>
        <Typography variant="body1" color="textSecondary" align="center" sx={{ mb: 4 }}>
          The page you are looking for might have been removed, had its name changed, or is temporarily unavailable.
        </Typography>
        <Button
          variant="contained"
          color="primary"
          startIcon={<Home />}
          onClick={() => navigate('/')}
        >
          Back to Dashboard
        </Button>
      </Paper>
    </Box>
  );
}

export default NotFound;