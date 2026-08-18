const User = require('../models/User');
const analyticsService = require('../services/analyticsService');
const { sendSuccess, sendError, sendPaginated } = require('../utils/apiResponse');
const { HTTP_STATUS } = require('../config/constants');
const { getPaginationParams, buildPaginationMeta } = require('../utils/pagination');

/**
 * GET /api/admin/users
 * Lists all users (admin only).
 */
const listUsers = async (req, res, next) => {
  try {
    const { page, limit, skip } = getPaginationParams(req.query);
    const filter = {};
    if (req.query.role) filter.role = req.query.role;
    if (req.query.isActive !== undefined) filter.isActive = req.query.isActive === 'true';

    const [users, total] = await Promise.all([
      User.find(filter)
        .select('-googleRefreshToken -fcmToken')
        .sort({ createdAt: -1 })
        .skip(skip)
        .limit(limit)
        .lean(),
      User.countDocuments(filter),
    ]);

    return sendPaginated(res, users, buildPaginationMeta(total, page, limit), 'Users retrieved');
  } catch (error) {
    next(error);
  }
};

/**
 * GET /api/admin/users/:id
 */
const getUserDetails = async (req, res, next) => {
  try {
    const user = await User.findById(req.params.id).select('-googleRefreshToken -fcmToken');
    if (!user) return sendError(res, 'User not found', HTTP_STATUS.NOT_FOUND);
    return sendSuccess(res, { user }, 'User retrieved');
  } catch (error) {
    next(error);
  }
};

/**
 * PATCH /api/admin/users/:id/role
 * Updates a user's role.
 * Body: { role: 'user' | 'admin' }
 */
const updateUserRole = async (req, res, next) => {
  try {
    const { role } = req.body;
    const user = await User.findByIdAndUpdate(
      req.params.id,
      { $set: { role } },
      { new: true, runValidators: true }
    ).select('-googleRefreshToken -fcmToken');

    if (!user) return sendError(res, 'User not found', HTTP_STATUS.NOT_FOUND);
    return sendSuccess(res, { user }, 'User role updated');
  } catch (error) {
    next(error);
  }
};

/**
 * PATCH /api/admin/users/:id/deactivate
 */
const deactivateUser = async (req, res, next) => {
  try {
    const user = await User.findByIdAndUpdate(
      req.params.id,
      { $set: { isActive: false } },
      { new: true }
    ).select('-googleRefreshToken -fcmToken');

    if (!user) return sendError(res, 'User not found', HTTP_STATUS.NOT_FOUND);
    return sendSuccess(res, { user }, 'User deactivated');
  } catch (error) {
    next(error);
  }
};

/**
 * GET /api/admin/stats
 * Returns system-wide statistics.
 */
const getSystemStats = async (req, res, next) => {
  try {
    const stats = await analyticsService.getSystemStats();
    return sendSuccess(res, { stats }, 'System stats retrieved');
  } catch (error) {
    next(error);
  }
};

module.exports = { listUsers, getUserDetails, updateUserRole, deactivateUser, getSystemStats };
