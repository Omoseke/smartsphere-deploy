import React, { useState, useEffect, useMemo } from 'react';
import { Routes, Route } from 'react-router-dom';
import { ThemeProvider, createTheme } from '@mui/material/styles';
import CssBaseline from '@mui/material/CssBaseline';
import useMediaQuery from '@mui/material/useMediaQuery';

// Layout components
import Layout from './components/Layout';

// Pages
import Dashboard from './pages/Dashboard';
import Deployments from './pages/Deployments';
import Infrastructure from './pages/Infrastructure';
import Monitoring from './pages/Monitoring';
import Security from './pages/Security';
import Costs from './pages/Costs';
import Settings from './pages/Settings';
import NotFound from './pages/NotFound';

function App() {
  // Check for saved theme preference or use system preference
  const prefersDarkMode = useMediaQuery('(prefers-color-scheme: dark)');
  const [mode, setMode] = useState(() => {
    const savedMode = localStorage.getItem('theme');
    if (savedMode) {
      return savedMode === 'dark' ? 'dark' : 'light';
    }
    return prefersDarkMode ? 'dark' : 'light';
  });

  // Update body class for global styling
  useEffect(() => {
    document.body.classList.toggle('dark-mode', mode === 'dark');
  }, [mode]);

  // Create theme with dynamic mode
  const theme = useMemo(
    () =>
      createTheme({
        palette: {
          mode: mode,
          primary: {
            main: mode === 'dark' ? '#90caf9' : '#1976d2',
          },
          secondary: {
            main: mode === 'dark' ? '#f48fb1' : '#f50057',
          },
          background: {
            default: mode === 'dark' ? '#121212' : '#f5f5f5',
            paper: mode === 'dark' ? '#1e1e1e' : '#ffffff',
          },
        },
        typography: {
          fontFamily: 'Roboto, Arial, sans-serif',
          h4: {
            fontSize: '1.75rem',
            '@media (max-width:600px)': {
              fontSize: '1.5rem',
            },
          },
          h5: {
            fontSize: '1.5rem',
            '@media (max-width:600px)': {
              fontSize: '1.25rem',
            },
          },
          h6: {
            fontSize: '1.25rem',
            '@media (max-width:600px)': {
              fontSize: '1.1rem',
            },
          },
        },
        breakpoints: {
          values: {
            xs: 0,
            xs350: 350, // Custom very small phone breakpoint
            sm: 600,
            md: 960,
            lg: 1280,
            xl: 1920,
          },
        },
        components: {
          MuiButton: {
            styleOverrides: {
              root: {
                '@media (max-width:600px)': {
                  padding: '6px 12px',
                  fontSize: '0.8125rem',
                },
              },
            },
          },
          MuiCard: {
            styleOverrides: {
              root: {
                '@media (max-width:600px)': {
                  borderRadius: '8px',
                },
              },
            },
          },
        },
      }),
    [mode, prefersDarkMode]
  );

  // Function to toggle theme mode
  const toggleColorMode = () => {
    const newMode = mode === 'light' ? 'dark' : 'light';
    setMode(newMode);
    localStorage.setItem('theme', newMode);
  };

  return (
    <ThemeProvider theme={theme}>
      <CssBaseline />
      <Layout darkMode={mode === 'dark'} toggleTheme={toggleColorMode}>
        <Routes>
          <Route path="/" element={<Dashboard />} />
          <Route path="/deployments" element={<Deployments />} />
          <Route path="/infrastructure" element={<Infrastructure />} />
          <Route path="/monitoring" element={<Monitoring />} />
          <Route path="/security" element={<Security />} />
          <Route path="/costs" element={<Costs />} />
          <Route path="/settings" element={<Settings />} />
          <Route path="*" element={<NotFound />} />
        </Routes>
      </Layout>
    </ThemeProvider>
  );
}

export default App;