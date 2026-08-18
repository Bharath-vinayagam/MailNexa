const { verifyAccessToken } = require('../utils/tokenUtils');
const User = require('../models/User');
const { sendError } = require('../utils/apiResponse');
const { HTTP_STATUS } = require('../config/constants');

/**
 * JWT Authentication Middleware.
 * Validates Bearer token and attaches the user object to req.user.
 */
const authenticate = async (req, res, next) => {
  try {
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return sendError(res, 'Access token is required', HTTP_STATUS.UNAUTHORIZED);
    }

    const token = authHeader.split(' ')[1];
    if (!token) {
      return sendError(res, 'Access token is missing', HTTP_STATUS.UNAUTHORIZED);
    }

    let decoded;
    try {
      decoded = verifyAccessToken(token);
    } catch (tokenError) {
      if (tokenError.name === 'TokenExpiredError') {
        return sendError(res, 'Access token has expired', HTTP_STATUS.UNAUTHORIZED);
      }
      return sendError(res, 'Invalid access token', HTTP_STATUS.UNAUTHORIZED);
    }

    const user = await User.findById(decoded.userId).select('-googleRefreshToken -fcmToken');
    if (!user) {
      return sendError(res, 'User not found', HTTP_STATUS.UNAUTHORIZED);
    }

    if (!user.isActive) {
      return sendError(res, 'Account has been deactivated', HTTP_STATUS.FORBIDDEN);
    }

    req.user = user;
    req.userId = user._id.toString();
    next();
  } catch (error) {
    return sendError(res, 'Authentication failed', HTTP_STATUS.UNAUTHORIZED);
  }
};

module.exports = authenticate;
