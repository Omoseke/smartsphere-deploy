const express = require('express');
const path = require('path');

const app = express();
const PORT = process.env.PORT || 5000;

// Parse JSON and URL-encoded bodies
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Serve static files from the root directory
app.use(express.static(__dirname));

// API routes will be added here
app.get('/api/health', (req, res) => {
  res.json({ status: 'healthy', timestamp: new Date() });
});

// Simple routes for pages
app.get('/', (req, res) => {
  res.sendFile(path.join(__dirname, 'index.html'));
});

app.get('/login', (req, res) => {
  res.sendFile(path.join(__dirname, 'pages/login.html'));
});

app.get('/register', (req, res) => {
  res.sendFile(path.join(__dirname, 'pages/register.html'));
});

app.get('/verify-email', (req, res) => {
  res.sendFile(path.join(__dirname, 'pages/verify-email.html'));
});

app.get('/verification-success', (req, res) => {
  res.sendFile(path.join(__dirname, 'pages/verification-success.html'));
});

app.get('/login-email-verify', (req, res) => {
  res.sendFile(path.join(__dirname, 'pages/login-email-verify.html'));
});

// Start Express server without database dependency
app.listen(PORT, '0.0.0.0', () => {
  console.log(`Server running on port ${PORT}`);
  console.log(`Open your browser to http://localhost:${PORT}`);
});