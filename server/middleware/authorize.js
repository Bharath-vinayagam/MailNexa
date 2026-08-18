const { sendError } = require('../utils/apiResponse');
const { HTTP_STATUS } = require('../config/constants');

/**
 * Role-based authorization middleware factory.
 * @param {...string} roles - Allowed roles
 * @returns {Function} Express middleware
 */
const authorize = (...roles) => {
  return (req, res, next) => {
    if (!req.user) {
      return sendError(res, 'Authentication required', HTTP_STATUS.UNAUTHORIZED);
    }

    if (!roles.includes(req.user.role)) {
      return sendError(
        res,
        `Access denied. Required role(s): ${roles.join(', ')}`,
        HTTP_STATUS.FORBIDDEN
      );
    }

    next();
  };
};

module.exports = authorize;
