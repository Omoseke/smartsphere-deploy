import React, { useState, useRef, useEffect } from 'react';
import { 
  Box, 
  Card, 
  CardHeader, 
  CardContent,
  CardActions,
  IconButton,
  Typography,
  Menu,
  MenuItem,
  Skeleton,
  Paper,
  Collapse,
  Divider,
  useTheme
} from '@mui/material';
import MoreVertIcon from '@mui/icons-material/MoreVert';
import RefreshIcon from '@mui/icons-material/Refresh';
import FullscreenIcon from '@mui/icons-material/Fullscreen';
import FullscreenExitIcon from '@mui/icons-material/FullscreenExit';
import DeleteOutlineIcon from '@mui/icons-material/DeleteOutline';
import SettingsIcon from '@mui/icons-material/Settings';
import CloseIcon from '@mui/icons-material/Close';
import DragIndicatorIcon from '@mui/icons-material/DragIndicator';

// Widget Chart Components
import BarChart from './charts/BarChart';
import LineChart from './charts/LineChart';
import PieChart from './charts/PieChart';
import MetricDisplay from './charts/MetricDisplay';
import StatusDisplay from './charts/StatusDisplay';
import TableDisplay from './charts/TableDisplay';

/**
 * Reusable and customizable widget component for dashboards
 * 
 * @param {Object} props - Component properties
 * @param {string} props.title - Widget title
 * @param {string} props.type - Widget type (chart, stats, list, etc.)
 * @param {Object} props.data - Data to display in the widget
 * @param {string} props.theme - Current theme (light/dark)
 * @param {boolean} props.isLoading - Loading state
 * @param {string} props.className - Additional CSS classes
 * @param {boolean} props.isDraggable - Whether the widget can be dragged
 * @param {Function} props.onPositionChange - Callback when widget position changes
 * @param {Function} props.onSettingsChange - Callback when widget settings change
 */
const DashboardWidget = ({ 
  id,
  title,
  subtitle,
  type = 'metric',
  data = {},
  isLoading = false,
  className = '',
  isDraggable = true,
  isResizable = true,
  isExpanded = false,
  onRemove,
  onRefresh,
  onPositionChange,
  onSettingsChange,
  onSizeChange,
  onExpand,
  gridSize = { w: 1, h: 1 }
}) => {
  const theme = useTheme();
  const [menuAnchorEl, setMenuAnchorEl] = useState(null);
  const [settingsOpen, setSettingsOpen] = useState(false);
  const [expanded, setExpanded] = useState(isExpanded);
  const cardRef = useRef(null);
  const dragHandleRef = useRef(null);
  
  // Handle menu open
  const handleMenuOpen = (event) => {
    setMenuAnchorEl(event.currentTarget);
  };

  // Handle menu close
  const handleMenuClose = () => {
    setMenuAnchorEl(null);
  };

  // Handle refresh
  const handleRefresh = () => {
    if (onRefresh) onRefresh(id);
    handleMenuClose();
  };

  // Handle remove
  const handleRemove = () => {
    if (onRemove) onRemove(id);
    handleMenuClose();
  };

  // Handle settings toggle
  const handleSettingsToggle = () => {
    setSettingsOpen(!settingsOpen);
    handleMenuClose();
  };

  // Handle expand toggle
  const handleExpandToggle = () => {
    const newExpandState = !expanded;
    setExpanded(newExpandState);
    if (onExpand) onExpand(id, newExpandState);
    handleMenuClose();
  };

  // Determine which chart component to render based on type
  const renderContent = () => {
    if (isLoading) {
      return renderLoadingSkeleton();
    }

    switch (type) {
      case 'bar-chart':
        return <BarChart data={data} />;
      case 'line-chart':
        return <LineChart data={data} />;
      case 'pie-chart':
        return <PieChart data={data} />;
      case 'metric':
        return <MetricDisplay data={data} />;
      case 'status':
        return <StatusDisplay data={data} />;
      case 'table':
        return <TableDisplay data={data} />;
      default:
        return (
          <Box sx={{ p: 2 }}>
            <Typography variant="body2" color="text.secondary">
              Widget type not supported
            </Typography>
          </Box>
        );
    }
  };

  // Render loading skeleton based on widget type
  const renderLoadingSkeleton = () => {
    switch (type) {
      case 'bar-chart':
      case 'line-chart':
      case 'pie-chart':
        return (
          <Box sx={{ p: 2 }}>
            <Skeleton variant="rectangular" height={150} animation="wave" />
          </Box>
        );
      case 'metric':
        return (
          <Box sx={{ p: 2, display: 'flex', flexDirection: 'column', alignItems: 'center' }}>
            <Skeleton variant="text" width="50%" height={60} animation="wave" />
            <Skeleton variant="text" width="30%" height={20} animation="wave" />
          </Box>
        );
      case 'status':
        return (
          <Box sx={{ p: 2 }}>
            <Skeleton variant="rectangular" height={80} animation="wave" />
          </Box>
        );
      case 'table':
        return (
          <Box sx={{ p: 2 }}>
            <Skeleton variant="rectangular" height={30} animation="wave" sx={{ mb: 1 }} />
            <Skeleton variant="rectangular" height={20} animation="wave" sx={{ mb: 1 }} />
            <Skeleton variant="rectangular" height={20} animation="wave" sx={{ mb: 1 }} />
            <Skeleton variant="rectangular" height={20} animation="wave" />
          </Box>
        );
      default:
        return (
          <Box sx={{ p: 2 }}>
            <Skeleton variant="rectangular" height={100} animation="wave" />
          </Box>
        );
    }
  };

  return (
    <Card 
      ref={cardRef}
      elevation={2}
      className={`dashboard-widget ${className}`}
      sx={{
        height: '100%',
        display: 'flex',
        flexDirection: 'column',
        transition: 'all 0.3s ease',
        borderRadius: theme.shape.borderRadius,
        backgroundColor: theme.palette.background.paper,
        border: `1px solid ${theme.palette.divider}`,
        '&:hover': {
          boxShadow: theme.shadows[4],
          borderColor: theme.palette.primary.light,
        }
      }}
    >
      {/* Drag handle for Draggable widgets */}
      {isDraggable && (
        <Box 
          ref={dragHandleRef}
          className="drag-handle"
          sx={{
            position: 'absolute',
            top: 0,
            left: 0,
            height: '100%',
            width: '8px',
            cursor: 'move',
            opacity: 0,
            backgroundColor: theme.palette.primary.main,
            borderRadius: `${theme.shape.borderRadius}px 0 0 ${theme.shape.borderRadius}px`,
            transition: 'opacity 0.2s ease',
            zIndex: 1,
            '&:hover': {
              opacity: 0.8,
            }
          }}
        />
      )}

      <CardHeader
        title={
          <Typography variant="h6" component="h2" sx={{ fontSize: { xs: '0.95rem', sm: '1.1rem' } }}>
            {title}
          </Typography>
        }
        subheader={subtitle && (
          <Typography variant="body2" color="text.secondary" sx={{ fontSize: { xs: '0.75rem', sm: '0.875rem' } }}>
            {subtitle}
          </Typography>
        )}
        action={
          <Box>
            {onRefresh && (
              <IconButton 
                size="small" 
                onClick={handleRefresh}
                aria-label="refresh"
                sx={{ mr: 0.5 }}
              >
                <RefreshIcon fontSize="small" />
              </IconButton>
            )}
            <IconButton
              size="small"
              onClick={handleMenuOpen}
              aria-label="widget settings"
            >
              <MoreVertIcon fontSize="small" />
            </IconButton>
            <Menu
              anchorEl={menuAnchorEl}
              open={Boolean(menuAnchorEl)}
              onClose={handleMenuClose}
              PaperProps={{
                elevation: 3,
                sx: { minWidth: 150 }
              }}
            >
              {onRefresh && (
                <MenuItem onClick={handleRefresh} dense>
                  <RefreshIcon fontSize="small" sx={{ mr: 1 }} />
                  Refresh
                </MenuItem>
              )}
              {isResizable && (
                <MenuItem onClick={handleExpandToggle} dense>
                  {expanded ? (
                    <>
                      <FullscreenExitIcon fontSize="small" sx={{ mr: 1 }} />
                      Collapse
                    </>
                  ) : (
                    <>
                      <FullscreenIcon fontSize="small" sx={{ mr: 1 }} />
                      Expand
                    </>
                  )}
                </MenuItem>
              )}
              {onSettingsChange && (
                <MenuItem onClick={handleSettingsToggle} dense>
                  <SettingsIcon fontSize="small" sx={{ mr: 1 }} />
                  Settings
                </MenuItem>
              )}
              {onRemove && (
                <MenuItem onClick={handleRemove} dense>
                  <DeleteOutlineIcon fontSize="small" sx={{ mr: 1 }} />
                  Remove
                </MenuItem>
              )}
            </Menu>
          </Box>
        }
        sx={{
          p: { xs: 1.5, sm: 2 },
          pb: { xs: 0.5, sm: 1 }
        }}
      />

      <CardContent 
        sx={{ 
          flex: 1,
          p: { xs: 1, sm: 2 },
          pt: { xs: 0.5, sm: 1 },
          overflow: 'auto'
        }}
      >
        {renderContent()}
      </CardContent>

      {/* Settings Panel (Collapsed by default) */}
      <Collapse in={settingsOpen}>
        <Divider />
        <Box sx={{ p: 2, backgroundColor: 'rgba(0, 0, 0, 0.03)' }}>
          <Typography variant="subtitle2" gutterBottom>
            Widget Settings
          </Typography>
          {/* Render settings form based on widget type */}
          <Typography variant="body2">
            Settings for this widget type are not implemented yet.
          </Typography>
        </Box>
      </Collapse>
    </Card>
  );
};

// For now, create placeholder chart components
// In a real application, these would be proper chart implementations using libraries like Recharts, Chart.js, etc.
const placeholderComponents = {
  BarChart: ({ data }) => (
    <Paper elevation={0} variant="outlined" sx={{ p: 2, height: 150, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
      <Typography variant="body2">Bar Chart Placeholder (Would show real chart in production)</Typography>
    </Paper>
  ),
  LineChart: ({ data }) => (
    <Paper elevation={0} variant="outlined" sx={{ p: 2, height: 150, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
      <Typography variant="body2">Line Chart Placeholder (Would show real chart in production)</Typography>
    </Paper>
  ),
  PieChart: ({ data }) => (
    <Paper elevation={0} variant="outlined" sx={{ p: 2, height: 150, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
      <Typography variant="body2">Pie Chart Placeholder (Would show real chart in production)</Typography>
    </Paper>
  ),
  MetricDisplay: ({ data }) => (
    <Box sx={{ textAlign: 'center', py: 2 }}>
      <Typography variant="h3" color="primary" fontWeight="bold">
        {data.value || '0'}
      </Typography>
      <Typography variant="body2" color="text.secondary">
        {data.label || 'Metric'}
      </Typography>
    </Box>
  ),
  StatusDisplay: ({ data }) => {
    const statusColors = {
      success: 'success.main',
      warning: 'warning.main',
      error: 'error.main',
      info: 'info.main',
    };
    
    return (
      <Box sx={{ display: 'flex', alignItems: 'center', p: 2 }}>
        <Box 
          sx={{ 
            width: 12, 
            height: 12, 
            borderRadius: '50%', 
            bgcolor: statusColors[data.status] || 'grey.500',
            mr: 1,
            boxShadow: '0 0 5px rgba(0,0,0,0.2)'
          }} 
        />
        <Typography variant="body1">
          {data.label || 'Status'}
        </Typography>
      </Box>
    );
  },
  TableDisplay: ({ data }) => (
    <Box sx={{ overflowX: 'auto' }}>
      <Typography variant="body2">Table Placeholder (Would show real table in production)</Typography>
    </Box>
  ),
};

// Use the placeholder components until real chart components are created
DashboardWidget.BarChart = placeholderComponents.BarChart;
DashboardWidget.LineChart = placeholderComponents.LineChart;
DashboardWidget.PieChart = placeholderComponents.PieChart;
DashboardWidget.MetricDisplay = placeholderComponents.MetricDisplay;
DashboardWidget.StatusDisplay = placeholderComponents.StatusDisplay;
DashboardWidget.TableDisplay = placeholderComponents.TableDisplay;

export default DashboardWidget;