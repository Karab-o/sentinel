const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
require('dotenv').config();

// Import database config (now it exists)
const { initializeDatabase } = require('./config/database');

const app = express();

// Security middleware
app.use(helmet());
app.use(cors());

// Body parsing middleware
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Logging
app.use(morgan('combined'));

// Health check endpoint
app.get('/health', (req, res) => {
  res.status(200).json({
    status: 'OK',
    message: 'Sentinel Backend is running!',
    timestamp: new Date().toISOString(),
    uptime: process.uptime(),
    environment: process.env.NODE_ENV || 'development',
    version: '1.0.0',
  });
});

// API info endpoint
app.get('/api', (req, res) => {
  res.json({
    message: 'Welcome to Sentinel API',
    version: '1.0.0',
    endpoints: [
      'GET /health - Health check',
      'GET /api - This endpoint',
      'GET /test - Test endpoint',
      'POST /echo - Echo test endpoint',
    ],
  });
});

// Test endpoint
app.get('/test', (req, res) => {
  res.json({
    message: 'Test endpoint working!',
    timestamp: new Date().toISOString(),
    server: 'Sentinel Backend',
  });
});

// Echo endpoint for testing POST requests
app.post('/echo', (req, res) => {
  res.json({
    message: 'Echo endpoint working!',
    method: req.method,
    headers: req.headers,
    body: req.body,
    query: req.query,
    timestamp: new Date().toISOString(),
  });
});

// Status endpoint
app.get('/status', (req, res) => {
  res.json({
    server: 'Sentinel Backend',
    status: 'running',
    memory: process.memoryUsage(),
    uptime: process.uptime(),
    platform: process.platform,
    nodeVersion: process.version,
    timestamp: new Date().toISOString(),
  });
});

// Error handling middleware
app.use((err, req, res, next) => {
  console.error('❌ Error:', err.stack);
  res.status(500).json({
    error: 'Internal Server Error',
    message: process.env.NODE_ENV === 'development' ? err.message : 'Something went wrong',
  });
});

// 404 handler
app.use('*', (req, res) => {
  res.status(404).json({
    error: 'Not Found',
    message: `Route ${req.originalUrl} not found`,
    availableRoutes: ['/health', '/api', '/test', '/status'],
  });
});

const PORT = process.env.PORT || 3000;

// Start server function
const startServer = async () => {
  try {
    // Initialize database (mock for now)
    await initializeDatabase();
    
    // Start server
    const server = app.listen(PORT, () => {
      console.log('🚀 ====================================');
      console.log('🚀 Sentinel Backend Server Started!');
      console.log('🚀 ====================================');
      console.log(`📍 Server: http://localhost:${PORT}`);
      console.log(`📊 Health: http://localhost:${PORT}/health`);
      console.log(`🔗 API: http://localhost:${PORT}/api`);
      console.log(`🧪 Test: http://localhost:${PORT}/test`);
      console.log(`📈 Status: http://localhost:${PORT}/status`);
      console.log(`🌍 Environment: ${process.env.NODE_ENV || 'development'}`);
      console.log('🚀 ====================================');
    });

    // Graceful shutdown
    process.on('SIGTERM', () => {
      console.log('SIGTERM received, shutting down gracefully');
      server.close(() => {
        console.log('Process terminated');
      });
    });

    process.on('SIGINT', () => {
      console.log('SIGINT received, shutting down gracefully');
      server.close(() => {
        console.log('Process terminated');
      });
    });

  } catch (error) {
    console.error('❌ Failed to start server:', error);
    process.exit(1);
  }
};

// Start the server
startServer();

module.exports = app;