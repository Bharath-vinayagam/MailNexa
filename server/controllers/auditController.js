const auditService = require('../services/auditService');
const { sendSuccess, sendPaginated } = require('../utils/apiResponse');
const { buildPaginationMeta } = require('../utils/pagination');

/**
 * GET /api/audit/logs
 * Returns audit logs with optional filters (admin only).
 */
const getLogs = async (req, res, next) => {
  try {
    const { userId, action, resource, startDate, endDate, page, limit } = req.query;
    const result = await auditService.getLogs({
      userId,
      action,
      resource,
      startDate,
      endDate,
      page: parseInt(page, 10) || 1,
      limit: parseInt(limit, 10) || 20,
    });
    return sendPaginated(
      res,
      result.logs,
      buildPaginationMeta(result.total, result.page, result.limit),
      'Audit logs retrieved'
    );
  } catch (error) {
    next(error);
  }
};

/**
 * GET /api/audit/my-logs
 * Returns the current user's own audit logs.
 */
const getMyLogs = async (req, res, next) => {
  try {
    const { page, limit } = req.query;
    const result = await auditService.getLogs({
      userId: req.userId,
      page: parseInt(page, 10) || 1,
      limit: parseInt(limit, 10) || 20,
    });
    return sendPaginated(
      res,
      result.logs,
      buildPaginationMeta(result.total, result.page, result.limit),
      'Your audit logs retrieved'
    );
  } catch (error) {
    next(error);
  }
};

/**
 * GET /api/audit/login-history
 * Returns login history for the current user.
 */
const getLoginHistory = async (req, res, next) => {
  try {
    const { page, limit } = req.query;
    const result = await auditService.getLoginHistory(req.userId, {
      page: parseInt(page, 10) || 1,
      limit: parseInt(limit, 10) || 20,
    });
    return sendSuccess(res, result, 'Login history retrieved');
  } catch (error) {
    next(error);
  }
};

/**
 * GET /api/audit/security (admin only)
 */
const getSecurityLogs = async (req, res, next) => {
  try {
    const { page, limit } = req.query;
    const result = await auditService.getSecurityLogs({
      page: parseInt(page, 10) || 1,
      limit: parseInt(limit, 10) || 20,
    });
    return sendSuccess(res, result, 'Security logs retrieved');
  } catch (error) {
    next(error);
  }
};

module.exports = { getLogs, getMyLogs, getLoginHistory, getSecurityLogs };
