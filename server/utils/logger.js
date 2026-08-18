const winston = require('winston');
const path = require('path');
const fs = require('fs');

const { combine, timestamp, printf, colorize, errors, json } = winston.format;

const consoleFormat = printf(({ level, message, timestamp: ts, stack }) => {
  return `${ts} [${level}]: ${stack || message}`;
});

const transportsList = [
  new winston.transports.Console({
    format: combine(
      colorize(),
      timestamp({ format: 'YYYY-MM-DD HH:mm:ss' }),
      consoleFormat,
    ),
    silent: process.env.NODE_ENV === 'test',
  }),
];

// Only add file transports in non-serverless environments (Vercel has read-only filesystem)
if (!process.env.VERCEL && process.env.NODE_ENV !== 'production') {
  try {
    const logDir = path.join(__dirname, '..', 'logs');
    if (!fs.existsSync(logDir)) {
      fs.mkdirSync(logDir, { recursive: true });
    }
    transportsList.push(
      new winston.transports.File({
        filename: path.join(logDir, 'app.log'),
        format: combine(json()),
        maxsize: 10 * 1024 * 1024,
        maxFiles: 5,
      }),
      new winston.transports.File({
        filename: path.join(logDir, 'error.log'),
        level: 'error',
        format: combine(json()),
        maxsize: 10 * 1024 * 1024,
        maxFiles: 5,
      })
    );
  } catch (e) {
    // Ignore file logger errors on serverless environments
  }
}

const logger = winston.createLogger({
  level: process.env.LOG_LEVEL || 'info',
  format: combine(
    timestamp({ format: 'YYYY-MM-DD HH:mm:ss' }),
    errors({ stack: true }),
  ),
  transports: transportsList,
  exitOnError: false,
});

module.exports = logger;
