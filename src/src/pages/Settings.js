import React from 'react';
import { Box, Typography, Paper, Grid, List, ListItem, ListItemText, Switch, FormControlLabel, Divider } from '@mui/material';

function Settings() {
  return (
    <Box className="page-container">
      <Typography variant="h4" component="h1" gutterBottom>
        Settings
      </Typography>
      <Paper sx={{ p: 3, mb: 3 }}>
        <Typography variant="h6" gutterBottom>
          Application Preferences
        </Typography>
        <List>
          <ListItem>
            <ListItemText 
              primary="Theme" 
              secondary="Global theme setting can be managed from any page using the theme toggle button" 
            />
            <FormControlLabel 
              control={<Switch checked={localStorage.getItem('theme') === 'dark'} />} 
              label="Dark Mode" 
              disabled
            />
          </ListItem>
          <Divider />
          <ListItem>
            <ListItemText 
              primary="Dashboard Widgets" 
              secondary="Manage your dashboard widgets and layouts from the Dashboard page" 
            />
          </ListItem>
          <Divider />
          <ListItem>
            <ListItemText 
              primary="Notifications" 
              secondary="Notification settings will be available soon" 
            />
            <FormControlLabel 
              control={<Switch disabled />} 
              label="Enabled" 
              disabled
            />
          </ListItem>
        </List>
      </Paper>
    </Box>
  );
}

export default Settings;