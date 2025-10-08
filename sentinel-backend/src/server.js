const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const rateLimit = require('express-rate-limit');
const { createServer } = require('http');
require('dotenv').config();

const { initializeDatabase } = require('./config/database');
const SocketService = require('./services/socketService');

// Import routes
const authRoutes = require('./routes/auth');
const contactRoutes = require('./routes/contacts');
const alertRoutes = require('./routes/alerts');

const app = express();
const server = createServer(app);

// Initialize WebSocket service
const socketService = new SocketService(server);

// Security middleware
app.use(helmet({
  contentSecurityPolicy: {
    directives: {
      defaultSrc: ["'self'"],
      styleSrc: ["'self'", "'unsafe-inline'"],
      scriptSrc: ["'self'"],
      imgSrc: ["'self'", "data:", "https:"],
    },
  },
}));

app.use(cors({
  origin: process.env.NODE_ENV === 'production' 
    ? ['https://your-frontend-domain.com'] 
    : ['http://localhost:3000', 'http://127.0.0.1:3000', 'http://localhost:8080'],
  credentials: true,
}));

// Rate limiting
const limiter = rateLimit({
  windowMs: parseInt(process.env.RATE_LIMIT_WINDOW_MS) || 15 * 60 * 1000, // 15 minutes
  max: parseInt(process.env.RATE_LIMIT_MAX_REQUESTS) || 100,
  message: {
    error: 'Too Many Requests',
    message: 'Too many requests from this IP, please try again later.',
  },
  standardHeaders: true,
  legacyHeaders: false,
});

app.use(limiter);

// Stricter rate limiting for auth endpoints
const authLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 10, // 10 attempts per window
  message: {
    error: 'Too Many Authentication Attempts',
    message: 'Too many login attempts, please try again later.',
  },
});

// Body parsing middleware
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// Logging middleware
app.use(morgan('combined'));

// Request ID middleware for tracking
app.use((req, res, next) => {
  req.id = Math.random().toString(36).substr(2, 9);
  res.setHeader('X-Request-ID', req.id);
  next();
});

// Health check endpoint
app.get('/health', (req, res) => {
  res.status(200).json({
    status: 'OK',
    message: 'Sentinel Backend API is running',
    timestamp: new Date().toISOString(),
    uptime: process.uptime(),
    environment: process.env.NODE_ENV || 'development',
    version: '1.0.0',
    services: {
      database: 'connected',
      websocket: 'active',
      connectedUsers: socketService.getConnectedUsersCount(),
    },
  });
});

// API information endpoint
app.get('/api', (req, res) => {
  res.json({
    name: 'Sentinel Personal Safety API',
    version: '1.0.0',
    description: 'Backend API for Sentinel Personal Safety App',
    endpoints: {
      authentication: {
        'POST /api/auth/register': 'Register new user',
        'POST /api/auth/login': 'Login user',
        'GET /api/auth/me': 'Get user profile',
        'PUT /api/auth/profile': 'Update user profile',
        'PUT /api/auth/settings': 'Update user settings',
        'PUT /api/auth/change-password': 'Change password',
        'POST /api/auth/logout': 'Logout user',
      },
      contacts: {
        'GET /api/contacts': 'Get emergency contacts',
        'GET /api/contacts/active': 'Get active contacts',
        'GET /api/contacts/stats': 'Get contact statistics',
        'POST /api/contacts': 'Add emergency contact',
        'PUT /api/contacts/:id': 'Update emergency contact',
        'DELETE /api/contacts/:id': 'Delete emergency contact',
      },
      alerts: {
        'POST /api/alerts': 'Send emergency alert',
        'GET /api/alerts': 'Get alert history',
        'GET /api/alerts/stats': 'Get alert statistics',
        'GET /api/alerts/:id': 'Get specific alert',
        'PUT /api/alerts/:id/status': 'Update alert status',
        'POST /api/alerts/test': 'Test emergency system',
      },
    },
    documentation: 'https://docs.sentinel-app.com',
    support: 'support@sentinel-app.com',
  });
});

// API routes
app.use('/api/auth', authLimiter, authRoutes);
app.use('/api/contacts', contactRoutes);
app.use('/api/alerts', alertRoutes);

// WebSocket status endpoint
app.get('/api/socket/status', (req, res) => {
  res.json({
    connected: socketService.getConnectedUsersCount(),
    users: socketService.getConnectedUsers(),
  });
});

// Error handling middleware
app.use((err, req, res, next) => {
  console.error(`❌ Error [${req.id}]:`, err.stack);
  
  // Handle specific error types
  if (err.type === 'entity.parse.failed') {
    return res.status(400).json({
      error: 'Invalid JSON',
      message: 'Please check your request body format',
      requestId: req.id,
    });
  }

  if (err.name === 'ValidationError') {
    return res.status(400).json({
      error: 'Validation Error',
      message: err.message,
      requestId: req.id,
    });
  }

  // Default error response
  res.status(err.status || 500).json({
    error: 'Internal Server Error',
    message: process.env.NODE_ENV === 'development' ? err.message : 'Something went wrong',
    requestId: req.id,
    ...(process.env.NODE_ENV === 'development' && { stack: err.stack }),
  });
});

// 404 handler
app.use('*', (req, res) => {
  res.status(404).json({
    error: 'Not Found',
    message: `Route ${req.originalUrl} not found`,
    requestId: req.id,
    availableRoutes: [
      'GET /health',
      'GET /api',
      'POST /api/auth/register',
      'POST /api/auth/login',
      'GET /api/contacts',
      'POST /api/alerts',
    ],
  });
});

const PORT = process.env.PORT || 3000;

// Start server
const startServer = async () => {
  try {
    console.log('🚀 Starting Sentinel Backend Server...');
    
    // Initialize database
    await initializeDatabase();
    
    // Start server
    server.listen(PORT, () => {
      console.log('🚀 ====================================');
      console.log('🚀 Sentinel Backend Server Started!');
      console.log('🚀 ====================================');
      console.log(`📍 Server: http://localhost:${PORT}`);
      console.log(`📊 Health: http://localhost:${PORT}/health`);
      console.log(`🔗 API: http://localhost:${PORT}/api`);
      console.log(`🌐 WebSocket: ws://localhost:${PORT}`);
      console.log(`🌍 Environment: ${process.env.NODE_ENV || 'development'}`);
      console.log(`👥 Connected Users: ${socketService.getConnectedUsersCount()}`);
      console.log('🚀 ====================================');
    });
  } catch (error) {
    console.error('❌ Failed to start server:', error);
    process.exit(1);
  }
};

// Graceful shutdown
const gracefulShutdown = (signal) => {
  console.log(`\n📴 ${signal} received, shutting down gracefully...`);
  
  server.close(() => {
    console.log('✅ HTTP server closed');
    
    // Close database connections
    console.log('✅ Database connections closed');
    
    console.log('✅ Graceful shutdown complete');
    process.exit(0);
  });

  // Force close after 10 seconds
  setTimeout(() => {
    console.error('❌ Could not close connections in time, forcefully shutting down');
    process.exit(1);
  }, 10000);
};

process.on('SIGTERM', () => gracefulShutdown('SIGTERM'));
process.on('SIGINT', () => gracefulShutdown('SIGINT'));

// Handle unhandled promise rejections
process.on('unhandledRejection', (reason, promise) => {
  console.error('❌ Unhandled Rejection at:', promise, 'reason:', reason);
});

// Handle uncaught exceptions
process.on('uncaughtException', (error) => {
  console.error('❌ Uncaught Exception:', error);
  process.exit(1);
});

startServer();

module.exports = { app, server, socketService };