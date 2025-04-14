import React, { useState, useEffect, useRef } from 'react';
import {
  Box,
  Typography,
  Button,
  IconButton,
  Drawer,
  List,
  ListItem,
  ListItemIcon,
  ListItemText,
  Divider,
  Switch,
  FormControlLabel,
  Grid,
  Paper,
  Card,
  CardContent,
  CardHeader,
  Chip,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  Snackbar,
  Alert,
  useTheme,
  Fab,
  Tooltip
} from '@mui/material';
import {
  Timeline,
  CheckCircle,
  Warning,
  Error,
  Refresh,
  ArrowUpward,
  ArrowDownward,
  Settings,
  Add,
  Edit,
  Save,
  Close,
  CloudUpload,
  CloudDownload,
  DragIndicator,
  Delete,
  Visibility,
  VisibilityOff,
  LightMode,
  DarkMode,
  Help
} from '@mui/icons-material';

// Import our custom components
import DashboardWidget from '../components/DashboardWidget';
import EmojiReaction from '../components/EmojiReaction';
import OnboardingTour from '../components/OnboardingTour';

// Import styles
import '../styles/Dashboard.css';

function Dashboard() {
  const muiTheme = useTheme();
  
  // State for theme toggle (light/dark)
  const [theme, setTheme] = useState('light');
  
  // State for dashboard settings and widgets
  const [isSettingsOpen, setIsSettingsOpen] = useState(false);
  const [isAddWidgetDialogOpen, setIsAddWidgetDialogOpen] = useState(false);
  const [isSavingLayout, setIsSavingLayout] = useState(false);
  const [notification, setNotification] = useState({ open: false, message: '', severity: 'info' });
  const [widgets, setWidgets] = useState([]);
  const [availableWidgets, setAvailableWidgets] = useState([]);
  
  // State for onboarding tour
  const [tourOpen, setTourOpen] = useState(false);
  const dashboardHeaderRef = useRef(null);
  const customizeButtonRef = useRef(null);
  const widgetsContainerRef = useRef(null);
  
  // State for emoji reactions
  const [dashboardFeedback, setDashboardFeedback] = useState({ 
    likes: 0, 
    loves: 0 
  });
  
  // Mock data for demonstration (would come from APIs in real implementation)
  const deploymentStatus = {
    production: 'Healthy',
    staging: 'Healthy',
    development: 'Healthy',
  };

  const infraHealth = {
    compute: 'Healthy',
    database: 'Healthy',
    storage: 'Healthy',
    network: 'Healthy',
  };

  const costMetrics = {
    monthToDate: '$12,345.67',
    forecastedThisMonth: '$15,890.23',
    compared: 'up',
    comparedValue: '8.2%',
  };

  const securityStatus = {
    totalFindings: 5,
    critical: 0,
    high: 1,
    medium: 2,
    low: 2,
  };

  const recentActivities = [
    { id: 1, action: 'Deployment to production', timestamp: '2 hours ago', actor: 'CI/CD Pipeline' },
    { id: 2, action: 'Database backup completed', timestamp: '5 hours ago', actor: 'System' },
    { id: 3, action: 'Cost optimization recommendations generated', timestamp: '8 hours ago', actor: 'Cost Analyzer' },
    { id: 4, action: 'Security scan completed', timestamp: '1 day ago', actor: 'Security Scanner' },
  ];

  // Initialize widgets and available widgets
  useEffect(() => {
    // Load saved widgets from localStorage or use default ones
    const savedWidgets = localStorage.getItem('dashboardWidgets');
    
    if (savedWidgets) {
      try {
        setWidgets(JSON.parse(savedWidgets));
      } catch (error) {
        console.error('Error loading saved widgets:', error);
        initializeDefaultWidgets();
      }
    } else {
      initializeDefaultWidgets();
    }
    
    // Load theme preference
    const savedTheme = localStorage.getItem('theme');
    if (savedTheme === 'dark' || (savedTheme === null && window.matchMedia('(prefers-color-scheme: dark)').matches)) {
      setTheme('dark');
    }
    
    // Set up available widget types
    setAvailableWidgets([
      { 
        id: 'deployment', 
        title: 'Deployments', 
        type: 'list',
        data: { 
          items: Object.entries(deploymentStatus).map(([env, status]) => ({
            title: env,
            value: status
          }))
        }
      },
      { 
        id: 'infrastructure', 
        title: 'Infrastructure', 
        type: 'list',
        data: { 
          items: Object.entries(infraHealth).map(([component, status]) => ({
            title: component,
            value: status
          }))
        }
      },
      { 
        id: 'cost', 
        title: 'Cost Overview', 
        type: 'stats',
        data: { 
          value: costMetrics.monthToDate,
          description: `Forecasted: ${costMetrics.forecastedThisMonth}`,
          change: parseFloat(costMetrics.comparedValue),
          unit: ''
        }
      },
      { 
        id: 'security', 
        title: 'Security Status', 
        type: 'stats',
        data: { 
          value: securityStatus.totalFindings,
          description: `${securityStatus.critical} critical, ${securityStatus.high} high`,
          unit: 'findings'
        }
      },
      { 
        id: 'activity', 
        title: 'Recent Activity', 
        type: 'list',
        data: { 
          items: recentActivities.map(activity => ({
            title: activity.action,
            value: `${activity.actor} - ${activity.timestamp}`
          }))
        }
      },
      { 
        id: 'performance', 
        title: 'System Performance', 
        type: 'stats',
        data: { 
          value: '98.7',
          change: 2.5,
          description: 'Uptime last 30 days',
          unit: '%'
        }
      },
    ]);
  }, []);

  // Helper to initialize default widgets
  const initializeDefaultWidgets = () => {
    setWidgets([
      {
        id: 'widget-1',
        widgetType: 'deployment',
        title: 'Deployments',
        type: 'list',
        position: { order: 1 },
        settings: {
          refreshInterval: 5,
          color: '#6950dc',
          showBorder: true,
          showTitle: true
        },
        data: { 
          items: Object.entries(deploymentStatus).map(([env, status]) => ({
            title: env,
            value: status
          }))
        }
      },
      {
        id: 'widget-2',
        widgetType: 'infrastructure',
        title: 'Infrastructure',
        type: 'list',
        position: { order: 2 },
        settings: {
          refreshInterval: 10,
          color: '#35a77c',
          showBorder: true,
          showTitle: true
        },
        data: { 
          items: Object.entries(infraHealth).map(([component, status]) => ({
            title: component,
            value: status
          }))
        }
      },
      {
        id: 'widget-3',
        widgetType: 'cost',
        title: 'Cost Overview',
        type: 'stats',
        position: { order: 3 },
        settings: {
          refreshInterval: 60,
          color: '#e74c3c',
          showBorder: true,
          showTitle: true
        },
        data: { 
          value: costMetrics.monthToDate,
          description: `Forecasted: ${costMetrics.forecastedThisMonth}`,
          change: parseFloat(costMetrics.comparedValue),
          unit: ''
        }
      },
      {
        id: 'widget-4',
        widgetType: 'security',
        title: 'Security Status',
        type: 'stats',
        position: { order: 4 },
        settings: {
          refreshInterval: 15,
          color: '#f39c12',
          showBorder: true,
          showTitle: true
        },
        data: { 
          value: securityStatus.totalFindings,
          description: `${securityStatus.critical} critical, ${securityStatus.high} high`,
          unit: 'findings'
        }
      }
    ]);
  };

  // Helper function for status indicator color
  const getStatusColor = (status) => {
    switch (status.toLowerCase()) {
      case 'healthy':
        return 'success';
      case 'warning':
        return 'warning';
      case 'error':
        return 'error';
      default:
        return 'info';
    }
  };

  // Helper function for status icon
  const getStatusIcon = (status) => {
    switch (status.toLowerCase()) {
      case 'healthy':
        return <CheckCircle fontSize="small" />;
      case 'warning':
        return <Warning fontSize="small" />;
      case 'error':
        return <Error fontSize="small" />;
      default:
        return null;
    }
  };

  // Toggle theme
  const toggleTheme = () => {
    const newTheme = theme === 'light' ? 'dark' : 'light';
    setTheme(newTheme);
    localStorage.setItem('theme', newTheme);
    document.body.classList.toggle('dark-mode', newTheme === 'dark');
  };

  // Toggle settings drawer
  const toggleSettings = () => {
    setIsSettingsOpen(!isSettingsOpen);
  };

  // Add widget dialog
  const openAddWidgetDialog = () => {
    setIsAddWidgetDialogOpen(true);
  };

  const closeAddWidgetDialog = () => {
    setIsAddWidgetDialogOpen(false);
  };

  // Add new widget
  const addWidget = (widgetType) => {
    const widgetTemplate = availableWidgets.find(w => w.id === widgetType);
    
    if (!widgetTemplate) return;
    
    const newWidget = {
      id: `widget-${Date.now()}`,
      widgetType,
      title: widgetTemplate.title,
      type: widgetTemplate.type,
      position: { order: widgets.length + 1 },
      settings: {
        refreshInterval: 5,
        color: '#6950dc',
        showBorder: true,
        showTitle: true
      },
      data: widgetTemplate.data
    };
    
    const updatedWidgets = [...widgets, newWidget];
    setWidgets(updatedWidgets);
    saveWidgetsToLocalStorage(updatedWidgets);
    
    setNotification({
      open: true,
      message: `Added new ${widgetTemplate.title} widget`,
      severity: 'success'
    });
    
    closeAddWidgetDialog();
  };

  // Remove widget
  const removeWidget = (widgetId) => {
    const updatedWidgets = widgets.filter(widget => widget.id !== widgetId);
    setWidgets(updatedWidgets);
    saveWidgetsToLocalStorage(updatedWidgets);
    
    setNotification({
      open: true,
      message: 'Widget removed',
      severity: 'info'
    });
  };

  // Save widget settings
  const saveWidgetSettings = (widgetId, newSettings) => {
    const updatedWidgets = widgets.map(widget => {
      if (widget.id === widgetId) {
        return { ...widget, settings: { ...widget.settings, ...newSettings } };
      }
      return widget;
    });
    
    setWidgets(updatedWidgets);
    saveWidgetsToLocalStorage(updatedWidgets);
  };

  // Save widget position
  const saveWidgetPosition = (widgetId, position) => {
    const updatedWidgets = widgets.map(widget => {
      if (widget.id === widgetId) {
        return { ...widget, position };
      }
      return widget;
    });
    
    setWidgets(updatedWidgets);
    saveWidgetsToLocalStorage(updatedWidgets);
  };

  // Reset to default layout
  const resetToDefaultLayout = () => {
    initializeDefaultWidgets();
    
    setNotification({
      open: true,
      message: 'Dashboard reset to default layout',
      severity: 'success'
    });
  };

  // Save widgets to localStorage
  const saveWidgetsToLocalStorage = (updatedWidgets) => {
    try {
      localStorage.setItem('dashboardWidgets', JSON.stringify(updatedWidgets));
    } catch (error) {
      console.error('Error saving widget layout:', error);
      setNotification({
        open: true,
        message: 'Failed to save dashboard layout',
        severity: 'error'
      });
    }
  };

  // Save current layout
  const saveCurrentLayout = () => {
    setIsSavingLayout(true);
    
    try {
      saveWidgetsToLocalStorage(widgets);
      setNotification({
        open: true,
        message: 'Dashboard layout saved',
        severity: 'success'
      });
    } catch (error) {
      console.error('Error saving widget layout:', error);
      setNotification({
        open: true,
        message: 'Failed to save dashboard layout',
        severity: 'error'
      });
    } finally {
      setIsSavingLayout(false);
    }
  };

  // Handle notification close
  const handleNotificationClose = () => {
    setNotification({ ...notification, open: false });
  };
  
  // Handle tour open
  const startTour = () => {
    setTourOpen(true);
  };
  
  // Handle tour close
  const endTour = (reason) => {
    setTourOpen(false);
    
    if (reason === 'completed') {
      setNotification({
        open: true,
        message: 'Tour completed! You are now ready to use all dashboard features.',
        severity: 'success'
      });
    }
  };
  
  // Handle emoji reaction
  const handleReaction = (reactionType, isAdd, counts) => {
    console.log(`${isAdd ? 'Added' : 'Removed'} reaction: ${reactionType}`, counts);
    
    // In a real app, we would send this to the server
    setDashboardFeedback({
      ...dashboardFeedback,
      [reactionType]: counts[reactionType] || 0
    });
  };

  // Render settings drawer
  const renderSettingsDrawer = () => (
    <Drawer
      anchor="right"
      open={isSettingsOpen}
      onClose={toggleSettings}
    >
      <Box sx={{ width: 280, p: 2 }}>
        <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 2 }}>
          <Typography variant="h6">Dashboard Settings</Typography>
          <IconButton onClick={toggleSettings} size="small">
            <Close />
          </IconButton>
        </Box>
        
        <Divider sx={{ mb: 2 }} />
        
        <Typography variant="subtitle1" gutterBottom>Theme</Typography>
        <FormControlLabel
          control={
            <Switch
              checked={theme === 'dark'}
              onChange={toggleTheme}
              color="primary"
            />
          }
          label={theme === 'dark' ? 'Dark Mode' : 'Light Mode'}
          sx={{ mb: 2 }}
        />
        
        <Divider sx={{ my: 2 }} />
        
        <Typography variant="subtitle1" gutterBottom>Widgets</Typography>
        <List dense>
          {widgets.map((widget) => (
            <ListItem key={widget.id} sx={{ px: 0 }}>
              <ListItemIcon sx={{ minWidth: 36 }}>
                <DragIndicator fontSize="small" />
              </ListItemIcon>
              <ListItemText primary={widget.title} />
              <IconButton size="small" onClick={() => removeWidget(widget.id)}>
                <Delete fontSize="small" />
              </IconButton>
            </ListItem>
          ))}
        </List>
        
        <Button
          variant="outlined"
          startIcon={<Add />}
          onClick={openAddWidgetDialog}
          fullWidth
          sx={{ mt: 2 }}
        >
          Add Widget
        </Button>
        
        <Divider sx={{ my: 2 }} />
        
        <Typography variant="subtitle1" gutterBottom>Layout</Typography>
        <Button
          variant="contained"
          startIcon={<Save />}
          onClick={saveCurrentLayout}
          disabled={isSavingLayout}
          fullWidth
          sx={{ mb: 1 }}
        >
          Save Layout
        </Button>
        <Button
          variant="outlined"
          onClick={resetToDefaultLayout}
          fullWidth
        >
          Reset to Default
        </Button>
      </Box>
    </Drawer>
  );

  // Render add widget dialog
  const renderAddWidgetDialog = () => (
    <Dialog open={isAddWidgetDialogOpen} onClose={closeAddWidgetDialog} maxWidth="xs" fullWidth>
      <DialogTitle>
        Add Widget
        <IconButton
          aria-label="close"
          onClick={closeAddWidgetDialog}
          sx={{ position: 'absolute', right: 8, top: 8 }}
        >
          <Close />
        </IconButton>
      </DialogTitle>
      <DialogContent>
        <List>
          {availableWidgets.map((widget) => (
            <ListItem 
              button
              key={widget.id}
              onClick={() => addWidget(widget.id)}
            >
              <ListItemText 
                primary={widget.title} 
                secondary={`Type: ${widget.type.charAt(0).toUpperCase() + widget.type.slice(1)}`} 
              />
            </ListItem>
          ))}
        </List>
      </DialogContent>
      <DialogActions>
        <Button onClick={closeAddWidgetDialog}>Cancel</Button>
      </DialogActions>
    </Dialog>
  );

  return (
    <Box className="page-container" sx={{ pb: 4 }}>
      <Box 
        ref={dashboardHeaderRef}
        sx={{ 
          display: 'flex', 
          flexDirection: { xs: 'column', sm: 'row' }, 
          justifyContent: 'space-between', 
          alignItems: { xs: 'flex-start', sm: 'center' }, 
          mb: 3,
          gap: { xs: 2, sm: 0 }
        }}>
        <Typography variant="h4" component="h1" gutterBottom sx={{ mb: { xs: 0, sm: 2 } }}>
          Personalized Dashboard
        </Typography>
        <Box sx={{ display: 'flex', gap: 1 }}>
          <Button 
            variant="outlined"
            startIcon={<Refresh />}
            size="small"
          >
            Refresh
          </Button>
          <Button
            ref={customizeButtonRef}
            variant="contained"
            startIcon={<Settings />}
            size="small"
            onClick={toggleSettings}
          >
            Customize
          </Button>
          <IconButton onClick={toggleTheme} color="inherit" size="small">
            {theme === 'dark' ? <LightMode /> : <DarkMode />}
          </IconButton>
        </Box>
      </Box>

      {/* Dashboard Widgets */}
      <div className="widget-grid" ref={widgetsContainerRef}>
        {widgets.map((widget) => (
          <div 
            key={widget.id}
            className={`widget-${widget.type === 'list' ? 'medium' : 'small'}`}
          >
            <DashboardWidget
              id={widget.id}
              title={widget.title}
              subtitle={widget.subtitle || null}
              type={widget.type === 'stats' ? 'metric' : widget.type === 'list' ? 'table' : widget.type}
              data={widget.data}
              isLoading={false}
              isDraggable={true}
              isResizable={true}
              onRemove={() => removeWidget(widget.id)}
              onPositionChange={(position) => saveWidgetPosition(widget.id, position)}
              onSettingsChange={(settings) => saveWidgetSettings(widget.id, settings)}
              onRefresh={() => console.log(`Refreshing widget: ${widget.id}`)}
              className={widget.type === 'stats' ? 'widget-stats' : ''}
            />
          </div>
        ))}
        
        {widgets.length === 0 && (
          <Paper sx={{ p: 4, textAlign: 'center', width: '100%' }}>
            <Typography variant="h6" color="text.secondary" gutterBottom>
              No widgets added
            </Typography>
            <Button
              variant="contained"
              startIcon={<Add />}
              onClick={openAddWidgetDialog}
              sx={{ mt: 2 }}
            >
              Add Widget
            </Button>
          </Paper>
        )}
      </div>

      {/* Settings Drawer */}
      {renderSettingsDrawer()}
      
      {/* Add Widget Dialog */}
      {renderAddWidgetDialog()}
      
      {/* Dashboard Feedback */}
      <Box 
        sx={{ 
          mt: 4, 
          textAlign: 'center',
          display: 'flex',
          flexDirection: 'column',
          alignItems: 'center'
        }}
      >
        <Typography variant="subtitle1" gutterBottom color="text.secondary">
          How do you like your dashboard?
        </Typography>
        <EmojiReaction 
          id="dashboard-feedback"
          onReaction={handleReaction}
          position="bottom"
          initialCounts={{
            like: Math.floor(Math.random() * 15) + 5,
            love: Math.floor(Math.random() * 10) + 3,
            celebrate: Math.floor(Math.random() * 5),
            smile: Math.floor(Math.random() * 8),
            sad: Math.floor(Math.random() * 3),
            dislike: Math.floor(Math.random() * 2)
          }}
        />
      </Box>
      
      {/* Help Button with Tour */}
      <Tooltip title="Get a tour of the dashboard">
        <Fab
          color="secondary"
          aria-label="help"
          onClick={startTour}
          sx={{
            position: 'fixed',
            bottom: 20,
            right: 20,
            zIndex: 1000
          }}
        >
          <Help />
        </Fab>
      </Tooltip>
      
      {/* Onboarding Tour */}
      <OnboardingTour
        open={tourOpen}
        onClose={endTour}
        tourId="dashboard-tour"
        steps={[
          {
            title: 'Welcome to your Dashboard',
            content: 'This personalized dashboard provides a quick overview of your cloud infrastructure and deployments.',
            target: '.page-container',
            placement: 'bottom'
          },
          {
            title: 'Dashboard Widgets',
            content: 'Each widget shows important information about your infrastructure. You can add, remove, and rearrange widgets.',
            target: '.widget-grid',
            placement: 'top'
          },
          {
            title: 'Customize Your Dashboard',
            content: 'Click here to add new widgets, change the layout, or adjust settings to match your preferences.',
            target: 'button:contains("Customize")',
            placement: 'left'
          },
          {
            title: 'Theme Toggle',
            content: 'Switch between light and dark modes for different lighting conditions and personal preference.',
            target: 'button[aria-label="toggle theme"]',
            placement: 'bottom'
          },
          {
            title: 'Give Feedback',
            content: 'Let us know what you think about the dashboard by using these emoji reactions.',
            target: '.emoji-reaction',
            placement: 'top'
          }
        ]}
      />
      
      {/* Notification Snackbar */}
      <Snackbar
        open={notification.open}
        autoHideDuration={4000}
        onClose={handleNotificationClose}
        anchorOrigin={{ vertical: 'bottom', horizontal: 'right' }}
      >
        <Alert 
          onClose={handleNotificationClose} 
          severity={notification.severity}
          variant="filled"
          sx={{ width: '100%' }}
        >
          {notification.message}
        </Alert>
      </Snackbar>
    </Box>
  );
}

export default Dashboard;