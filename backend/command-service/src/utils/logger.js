const winston = require('winston');

const logger = winston.createLogger({
  level: process.env.LOG_LEVEL || 'info',
  format: winston.format.combine(
    winston.format.timestamp(),
    winston.format.errors({ stack: true }),
    winston.format.json()
  ),
  defaultMeta: { service: 'command-service' },
  transports: [
    new winston.transports.Console({
      silent: process.env.NODE_ENV === 'test' && !process.env.DEBUG_TESTS,
    }),
  ],
});

module.exports = logger;
