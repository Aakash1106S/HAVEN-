const rateLimit = require('express-rate-limit');

const isTest = process.env.NODE_ENV === 'test';

const commandLimiter = rateLimit({
  windowMs: 60 * 1000, // 1 minute
  max: isTest ? 10000 : 30,
  message: {
    error: 'Too Many Requests',
    message: 'Command rate limit exceeded. Max 30 requests per minute.',
  },
  standardHeaders: true,
  legacyHeaders: false,
});

const pairingLimiter = rateLimit({
  windowMs: 10 * 60 * 1000, // 10 minutes
  max: isTest ? 10000 : 5,
  message: {
    error: 'Too Many Requests',
    message: 'Pairing rate limit exceeded. Max 5 requests per 10 minutes.',
  },
  standardHeaders: true,
  legacyHeaders: false,
});

const generalLimiter = rateLimit({
  windowMs: 60 * 1000, // 1 minute
  max: isTest ? 10000 : 100,
  message: {
    error: 'Too Many Requests',
    message: 'General API rate limit exceeded. Max 100 requests per minute.',
  },
  standardHeaders: true,
  legacyHeaders: false,
});

module.exports = {
  commandLimiter,
  pairingLimiter,
  generalLimiter,
};
