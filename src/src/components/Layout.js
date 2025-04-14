import React, { useState, useEffect } from 'react';
import { useLocation, useNavigate } from 'react-router-dom';
import {
  AppBar,
  Box,
  CssBaseline,
  Divider,
  Drawer,
  IconButton,
  List,
  ListItem,
  ListItemButton,
  ListItemIcon,
  ListItemText,
  Toolbar,
  Typography,
  Avatar,
  Menu,
  MenuItem,
  Badge,
  Tooltip,
  useMediaQuery,
  useTheme,
  SwipeableDrawer,
  Fab,
} from '@mui/material';
import MenuIcon from '@mui/icons-material/Menu';
import DashboardIcon from '@mui/icons-material/Dashboard';
import RocketLaunchIcon from '@mui/icons-material/RocketLaunch';
import StorageIcon from '@mui/icons-material/Storage';
import MonitorHeartIcon from '@mui/icons-material/MonitorHeart';
import SecurityIcon from '@mui/icons-material/Security';
import MonetizationOnIcon from '@mui/icons-material/MonetizationOn';
import SettingsIcon from '@mui/icons-material/Settings';
import AccountCircleIcon from '@mui/icons-material/AccountCircle';
import NotificationsIcon from '@mui/icons-material/Notifications';
import HelpIcon from '@mui/icons-material/Help';
import ArrowUpwardIcon from '@mui/icons-material/ArrowUpward';
import Brightness4Icon from '@mui/icons-material/Brightness4';
import Brightness7Icon from '@mui/icons-material/Brightness7';
import DarkModeIcon from '@mui/icons-material/DarkMode';
import LightModeIcon from '@mui/icons-material/LightMode';

const drawerWidth = 240;

const menuItems = [
  { text: 'Dashboard', icon: <DashboardIcon />, path: '/' },
  { text: 'Deployments', icon: <RocketLaunchIcon />, path: '/deployments' },
  { text: 'Infrastructure', icon: <StorageIcon />, path: '/infrastructure' },
  { text: 'Monitoring', icon: <MonitorHeartIcon />, path: '/monitoring' },
  { text: 'Security', icon: <SecurityIcon />, path: '/security' },
  { text: 'Costs', icon: <MonetizationOnIcon />, path: '/costs' },
  { text: 'Settings', icon: <SettingsIcon />, path: '/settings' },
];

function Layout({ children, darkMode, toggleTheme }) {
  const location = useLocation();
  const navigate = useNavigate();
  const theme = useTheme();
  const isMobile = useMediaQuery(theme.breakpoints.down('sm'));
  const isTablet = useMediaQuery(theme.breakpoints.between('sm', 'md'));
  
  const [mobileOpen, setMobileOpen] = useState(false);
  const [userMenuAnchorEl, setUserMenuAnchorEl] = useState(null);
  const [notificationsMenuAnchorEl, setNotificationsMenuAnchorEl] = useState(null);
  const [showScrollTop, setShowScrollTop] = useState(false);
  
  // Function to scroll to top
  const scrollToTop = () => {
    window.scrollTo({
      top: 0,
      behavior: 'smooth'
    });
  };
  
  // Initialize dark mode on component mount
  useEffect(() => {
    // Apply dark mode to body based on the state
    document.body.classList.toggle('dark-mode', darkMode);
  }, [darkMode]);
  
  // Show the scroll to top button when scrolled down
  useEffect(() => {
    const handleScroll = () => {
      if (window.scrollY > 300) {
        setShowScrollTop(true);
      } else {
        setShowScrollTop(false);
      }
    };
    
    window.addEventListener('scroll', handleScroll);
    
    return () => {
      window.removeEventListener('scroll', handleScroll);
    };
  }, []);

  const handleDrawerToggle = () => {
    setMobileOpen(!mobileOpen);
  };

  const handleUserMenuOpen = (event) => {
    setUserMenuAnchorEl(event.currentTarget);
  };

  const handleUserMenuClose = () => {
    setUserMenuAnchorEl(null);
  };
  
  const handleNotificationsMenuOpen = (event) => {
    setNotificationsMenuAnchorEl(event.currentTarget);
  };

  const handleNotificationsMenuClose = () => {
    setNotificationsMenuAnchorEl(null);
  };
  
  // No longer need this local toggle function as we're receiving it as a prop
  // and using the App-level state
  
  // Dynamic title based on screen size
  const getTitle = () => {
    const currentPage = menuItems.find((item) => item.path === location.pathname)?.text || 'Not Found';
    if (isMobile) {
      // For very small screens, abbreviate names to save space
      if (currentPage === 'Infrastructure') return 'Infra';
      if (currentPage === 'Deployments') return 'Deploy';
      if (currentPage === 'Monitoring') return 'Monitor';
      return currentPage;
    }
    return currentPage;
  };

  const drawer = (
    <div>
      <Toolbar sx={{ 
        display: 'flex', 
        justifyContent: 'space-between', 
        py: 1,
        minHeight: { xs: '56px', sm: '64px' }
      }}>
        <Typography variant="h6" noWrap component="div" sx={{ fontWeight: 'bold' }}>
          SmartSphere
        </Typography>
        {/* Theme toggle in drawer */}
        <Tooltip title={darkMode ? "Switch to Light Mode" : "Switch to Dark Mode"}>
          <IconButton 
            color="primary" 
            size="small"
            onClick={toggleTheme}
            aria-label="toggle theme in drawer"
            sx={{ 
              transition: 'all 0.3s ease-in-out',
              '&:hover': { 
                transform: 'rotate(30deg)',
                backgroundColor: darkMode ? 'rgba(255, 255, 255, 0.15)' : 'rgba(0, 0, 0, 0.08)'
              }
            }}
          >
            {darkMode ? <LightModeIcon fontSize="small" /> : <DarkModeIcon fontSize="small" />}
          </IconButton>
        </Tooltip>
      </Toolbar>
      <Divider />
      <List sx={{ 
        '& .MuiListItemButton-root': {
          py: { xs: 1, sm: 1.5 }
        }
      }}>
        {menuItems.map((item) => (
          <ListItem key={item.text} disablePadding>
            <ListItemButton
              selected={location.pathname === item.path}
              onClick={() => {
                navigate(item.path);
                setMobileOpen(false);
              }}
              sx={{ 
                borderRadius: '4px',
                mx: 1, 
                my: 0.5,
                '&.Mui-selected': {
                  backgroundColor: 'rgba(25, 118, 210, 0.12)',
                  '&:hover': {
                    backgroundColor: 'rgba(25, 118, 210, 0.20)',
                  }
                }
              }}
            >
              <ListItemIcon sx={{ minWidth: { xs: 40, sm: 56 } }}>
                {item.icon}
              </ListItemIcon>
              <ListItemText 
                primary={item.text} 
                primaryTypographyProps={{
                  fontSize: { xs: '0.9rem', sm: '1rem' }
                }}
              />
            </ListItemButton>
          </ListItem>
        ))}
      </List>
    </div>
  );

  return (
    <Box sx={{ display: 'flex' }}>
      <CssBaseline />
      <AppBar
        position="fixed"
        sx={{
          width: { sm: `calc(100% - ${drawerWidth}px)` },
          ml: { sm: `${drawerWidth}px` },
          boxShadow: { xs: 3, sm: 2 }
        }}
      >
        <Toolbar sx={{ minHeight: { xs: '56px', sm: '64px' } }}>
          <IconButton
            color="inherit"
            aria-label="open drawer"
            edge="start"
            onClick={handleDrawerToggle}
            sx={{ mr: 1, display: { sm: 'none' } }}
          >
            <MenuIcon />
          </IconButton>
          <Typography 
            variant="h6" 
            noWrap 
            component="div" 
            sx={{ 
              flexGrow: 1,
              fontSize: { xs: '1.1rem', sm: '1.25rem' }
            }}
          >
            {getTitle()}
          </Typography>
          
          {/* Theme Toggle */}
          <Tooltip title={darkMode ? "Switch to Light Mode" : "Switch to Dark Mode"}>
            <IconButton 
              color="inherit" 
              size="medium"
              onClick={toggleTheme}
              aria-label="toggle theme"
              sx={{ 
                mr: 1,
                transition: 'all 0.3s ease-in-out',
                '&:hover': { 
                  transform: 'rotate(30deg)',
                  backgroundColor: darkMode ? 'rgba(255, 255, 255, 0.15)' : 'rgba(0, 0, 0, 0.08)'
                }
              }}
            >
              {darkMode ? <LightModeIcon fontSize="small" /> : <DarkModeIcon fontSize="small" />}
            </IconButton>
          </Tooltip>

          {/* Hide Help icon on very small screens */}
          <Tooltip title="Help">
            <IconButton 
              color="inherit" 
              size="medium" 
              sx={{ display: { xs: 'none', xs350: 'flex' } }}
            >
              <HelpIcon fontSize="small" />
            </IconButton>
          </Tooltip>
          
          <Tooltip title="Notifications">
            <IconButton 
              color="inherit" 
              size="medium"
              onClick={handleNotificationsMenuOpen}
            >
              <Badge badgeContent={3} color="error">
                <NotificationsIcon fontSize="small" />
              </Badge>
            </IconButton>
          </Tooltip>
          
          <Menu
            id="notifications-menu"
            anchorEl={notificationsMenuAnchorEl}
            open={Boolean(notificationsMenuAnchorEl)}
            onClose={handleNotificationsMenuClose}
            anchorOrigin={{
              vertical: 'bottom',
              horizontal: 'right',
            }}
            transformOrigin={{
              vertical: 'top',
              horizontal: 'right',
            }}
            PaperProps={{
              style: {
                maxHeight: 300,
                width: '300px',
              },
            }}
          >
            <MenuItem onClick={handleNotificationsMenuClose}>New deployment completed</MenuItem>
            <MenuItem onClick={handleNotificationsMenuClose}>Security scan found 1 issue</MenuItem>
            <MenuItem onClick={handleNotificationsMenuClose}>Cost forecast updated</MenuItem>
          </Menu>
          
          <Tooltip title="Account">
            <IconButton
              onClick={handleUserMenuOpen}
              size="medium"
              edge="end"
              color="inherit"
              aria-label="account of current user"
              aria-controls="menu-appbar"
              aria-haspopup="true"
            >
              <Avatar sx={{ width: 32, height: 32, bgcolor: 'secondary.main' }}>
                <AccountCircleIcon fontSize="small" />
              </Avatar>
            </IconButton>
          </Tooltip>
          
          <Menu
            id="menu-appbar"
            anchorEl={userMenuAnchorEl}
            anchorOrigin={{
              vertical: 'bottom',
              horizontal: 'right',
            }}
            keepMounted
            transformOrigin={{
              vertical: 'top',
              horizontal: 'right',
            }}
            open={Boolean(userMenuAnchorEl)}
            onClose={handleUserMenuClose}
          >
            <MenuItem onClick={handleUserMenuClose}>Profile</MenuItem>
            <MenuItem onClick={handleUserMenuClose}>Account</MenuItem>
            <Divider />
            <MenuItem onClick={handleUserMenuClose}>Logout</MenuItem>
          </Menu>
        </Toolbar>
      </AppBar>
      
      <Box
        component="nav"
        sx={{ width: { sm: drawerWidth }, flexShrink: { sm: 0 } }}
        aria-label="navigation drawer"
      >
        {/* Mobile drawer - swipeable for better mobile experience */}
        <SwipeableDrawer
          variant="temporary"
          open={mobileOpen}
          onOpen={() => setMobileOpen(true)}
          onClose={handleDrawerToggle}
          ModalProps={{
            keepMounted: true, // Better open performance on mobile
          }}
          sx={{
            display: { xs: 'block', sm: 'none' },
            '& .MuiDrawer-paper': { 
              boxSizing: 'border-box', 
              width: drawerWidth,
              borderRadius: '0 8px 8px 0' 
            },
          }}
        >
          {drawer}
        </SwipeableDrawer>
        
        {/* Desktop drawer */}
        <Drawer
          variant="permanent"
          sx={{
            display: { xs: 'none', sm: 'block' },
            '& .MuiDrawer-paper': { 
              boxSizing: 'border-box', 
              width: drawerWidth,
              borderRight: '1px solid rgba(0, 0, 0, 0.12)'
            },
          }}
          open
        >
          {drawer}
        </Drawer>
      </Box>
      
      <Box
        component="main"
        sx={{
          flexGrow: 1,
          width: { sm: `calc(100% - ${drawerWidth}px)` },
          mt: { xs: '56px', sm: '64px' },
          pb: { xs: 7, sm: 4 } // Add bottom padding for mobile to account for nav or floating button
        }}
      >
        {children}
        
        {/* Scroll to top button - visible when scrolled down on mobile */}
        {showScrollTop && (
          <Fab 
            color="primary" 
            size="small" 
            aria-label="scroll to top"
            onClick={scrollToTop}
            sx={{ 
              position: 'fixed', 
              bottom: 20, 
              right: 20,
              display: { xs: 'flex', sm: 'none' }
            }}
          >
            <ArrowUpwardIcon />
          </Fab>
        )}
      </Box>
    </Box>
  );
}

export default Layout;