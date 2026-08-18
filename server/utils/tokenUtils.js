const jwt = require('jsonwebtoken');
const crypto = require('crypto');

/**
 * Signs a JWT access token.
 */
const signAccessToken = (payload) => {
  return jwt.sign(payload, process.env.JWT_SECRET, {
    expiresIn: process.env.JWT_EXPIRES_IN || '15m',
    issuer: 'mailguard',
    audience: 'mailguard-client',
  });
};

/**
 * Signs a JWT refresh token.
 */
const signRefreshToken = (payload) => {
  return jwt.sign(payload, process.env.JWT_REFRESH_SECRET, {
    expiresIn: process.env.JWT_REFRESH_EXPIRES_IN || '7d',
    issuer: 'mailguard',
    audience: 'mailguard-client',
  });
};

/**
 * Verifies a JWT access token.
 * @throws {JsonWebTokenError | TokenExpiredError}
 */
const verifyAccessToken = (token) => {
  return jwt.verify(token, process.env.JWT_SECRET, {
    issuer: 'mailguard',
    audience: 'mailguard-client',
  });
};

/**
 * Verifies a JWT refresh token.
 * @throws {JsonWebTokenError | TokenExpiredError}
 */
const verifyRefreshToken = (token) => {
  return jwt.verify(token, process.env.JWT_REFRESH_SECRET, {
    issuer: 'mailguard',
    audience: 'mailguard-client',
  });
};

/**
 * Generates a secure random token (for CSRF or one-time tokens).
 */
const generateSecureToken = (bytes = 32) => {
  return crypto.randomBytes(bytes).toString('hex');
};

/**
 * Decodes a JWT without verifying (for extracting payload).
 */
const decodeToken = (token) => {
  return jwt.decode(token);
};

module.exports = {
  signAccessToken,
  signRefreshToken,
  verifyAccessToken,
  verifyRefreshToken,
  generateSecureToken,
  decodeToken,
};
