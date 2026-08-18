const rateLimit = require('express-rate-limit');
const { sendError } = require('../utils/apiResponse');
const { HTTP_STATUS } = require('../config/constants');

const rateLimitHandler = (req, res) => {
  return sendError(
    res,
    'Too many requests. Please wait before trying again.',
    HTTP_STATUS.TOO_MANY_REQUESTS
  );
};

/**
 * General API rate limiter – 100 requests per 15 minutes.
 */
const generalLimiter = rateLimit({
  windowMs: parseInt(process.env.RATE_LIMIT_WINDOW_MS, 10) || 15 * 60 * 1000,
  max: parseInt(process.env.RATE_LIMIT_MAX, 10) || 100,
  standardHeaders: true,
  legacyHeaders: false,
  handler: rateLimitHandler,
  skip: (req) => process.env.NODE_ENV === 'test',
});

/**
 * Strict auth rate limiter – 10 requests per 15 minutes.
 */
const authLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 10,
  standardHeaders: true,
  legacyHeaders: false,
  handler: rateLimitHandler,
  skip: (req) => process.env.NODE_ENV === 'test',
  message: 'Too many authentication attempts',
});

/**
 * Gmail sync rate limiter – 5 manual triggers per 5 minutes.
 */
const syncLimiter = rateLimit({
  windowMs: 5 * 60 * 1000,
  max: 100,
  standardHeaders: true,
  legacyHeaders: false,
  handler: rateLimitHandler,
  skip: (req) => process.env.NODE_ENV === 'development' || process.env.NODE_ENV === 'test',
});

module.exports = { generalLimiter, authLimiter, syncLimiter };
