const auditService = require('../services/auditService');

/**
 * Creates an audit log middleware for a specific action and resource.
 * Logs after the response is sent.
 */
const auditLog = (action, resource) => {
  return (req, res, next) => {
    const originalJson = res.json.bind(res);

    res.json = function (body) {
      // Log after response
      setImmediate(async () => {
        try {
          await auditService.log({
            userId: req.user ? req.user._id : null,
            action,
            resource,
            resourceId: body?.data?._id || req.params?.id || null,
            details: {
              method: req.method,
              url: req.originalUrl,
              statusCode: res.statusCode,
              success: res.statusCode < 400,
            },
            ipAddress: req.ip || req.connection.remoteAddress,
            userAgent: req.headers['user-agent'] || '',
            success: res.statusCode < 400,
          });
        } catch (err) {
          // Never let audit logging crash the app
        }
      });

      return originalJson(body);
    };

    next();
  };
};

module.exports = auditLog;
