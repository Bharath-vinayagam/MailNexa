const AuditLog = require('../models/AuditLog');
const logger = require('../utils/logger');

/**
 * Creates an audit log entry.
 * Never throws – silently catches errors so logging never blocks the app.
 */
const log = async ({
  userId = null,
  action,
  resource,
  resourceId = null,
  details = {},
  ipAddress = null,
  userAgent = null,
  success = true,
  errorMessage = null,
}) => {
  try {
    await AuditLog.create({
      userId,
      action,
      resource,
      resourceId,
      details,
      ipAddress,
      userAgent,
      success,
      errorMessage,
      timestamp: new Date(),
    });
  } catch (error) {
    logger.error('Failed to write audit log:', error.message);
  }
};

/**
 * Fetches audit logs with optional filters.
 */
const getLogs = async ({
  userId = null,
  action = null,
  resource = null,
  startDate = null,
  endDate = null,
  page = 1,
  limit = 20,
}) => {
  const query = {};
  if (userId) query.userId = userId;
  if (action) query.action = action;
  if (resource) query.resource = resource;
  if (startDate || endDate) {
    query.timestamp = {};
    if (startDate) query.timestamp.$gte = new Date(startDate);
    if (endDate) query.timestamp.$lte = new Date(endDate);
  }

  const skip = (page - 1) * limit;
  const [logs, total] = await Promise.all([
    AuditLog.find(query)
      .sort({ timestamp: -1 })
      .skip(skip)
      .limit(limit)
      .populate('userId', 'name email'),
    AuditLog.countDocuments(query),
  ]);

  return { logs, total, page, limit };
};

/**
 * Fetches login/logout history for a user.
 */
const getLoginHistory = async (userId, { page = 1, limit = 20 } = {}) => {
  return getLogs({
    userId,
    action: 'LOGIN',
    resource: 'Auth',
    page,
    limit,
  });
};

/**
 * Fetches security-related logs (failed logins, revocations).
 */
const getSecurityLogs = async ({ page = 1, limit = 20 } = {}) => {
  const query = {
    $or: [
      { success: false },
      { action: { $in: ['LOGOUT', 'REVOKE', 'LOGIN'] } },
    ],
  };
  const skip = (page - 1) * limit;
  const [logs, total] = await Promise.all([
    AuditLog.find(query)
      .sort({ timestamp: -1 })
      .skip(skip)
      .limit(limit)
      .populate('userId', 'name email'),
    AuditLog.countDocuments(query),
  ]);
  return { logs, total, page, limit };
};

module.exports = { log, getLogs, getLoginHistory, getSecurityLogs };
