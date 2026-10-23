require('dotenv').config();
const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const config = require('./config');
const logger = require('./utils/logger');
const mqttClient = require('./mqtt/client');
const { generalLimiter } = require('./middleware/rateLimiter');

// Route handlers
const commandsRouter = require('./routes/commands');
const devicesRouter = require('./routes/devices');
const pairingRouter = require('./routes/pairing');

const app = express();

// Security headers
app.use(helmet());

// CORS configuration
if (config.allowedOrigins && config.allowedOrigins.length > 0) {
  app.use(
    cors({
      origin: config.allowedOrigins,
      credentials: true,
    })
  );
} else {
  app.use(cors());
}

// Body parsing
app.use(express.json({ limit: '1mb' }));
app.use(express.urlencoded({ extended: true }));

// General rate limiting
app.use(generalLimiter);

// Health check endpoint
app.get('/health', (req, res) => {
  res.status(200).json({
    status: 'ok',
    service: 'haven-command-service',
    timestamp: new Date().toISOString(),
    mqttConnected: mqttClient.isConnected,
    uptimeSeconds: Math.floor(process.uptime()),
  });
});

// Mount API routes
app.use('/api/commands', commandsRouter);
app.use('/api/homes', devicesRouter);
app.use('/api/devices', pairingRouter);

// 404 Handler
app.use((req, res) => {
  res.status(404).json({
    error: 'Not Found',
    message: `Cannot ${req.method} ${req.originalUrl}`,
  });
});

// Centralized error handler
app.use((err, req, res, next) => {
  logger.error('Unhandled request error', {
    error: err.message,
    stack: err.stack,
    url: req.originalUrl,
    method: req.method,
  });

  const statusCode = err.statusCode || 500;
  res.status(statusCode).json({
    error: err.name || 'InternalServerError',
    message: err.message || 'An unexpected error occurred',
  });
});

// Connect MQTT client (skipped automatically in test env)
mqttClient.connect();

// Start HTTP server only if run directly
let server = null;
if (process.env.NODE_ENV !== 'test') {
  server = app.listen(config.port, () => {
    logger.info(`Haven Command Service running on port ${config.port}`, {
      port: config.port,
      env: process.env.NODE_ENV || 'development',
    });
  });

  server.on('error', (err) => {
    if (err.code === 'EADDRINUSE') {
      logger.error(`Port ${config.port} is already in use. Please change PORT in .env or config.js to an open port.`);
    } else {
      logger.error('Server error', { error: err.message });
    }
    process.exit(1);
  });
}

// Graceful shutdown handling
function shutdown(signal) {
  logger.info(`Received ${signal}. Shutting down gracefully...`);
  if (server) {
    server.close(() => {
      logger.info('HTTP server closed.');
      mqttClient.disconnect().finally(() => {
        process.exit(0);
      });
    });

    // Force shutdown after timeout if pending connections hang
    setTimeout(() => {
      logger.error('Forced shutdown after timeout.');
      process.exit(1);
    }, 10000);
  } else {
    process.exit(0);
  }
}

process.on('SIGTERM', () => shutdown('SIGTERM'));
process.on('SIGINT', () => shutdown('SIGINT'));

module.exports = app;
