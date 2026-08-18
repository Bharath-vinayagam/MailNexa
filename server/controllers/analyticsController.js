const analyticsService = require('../services/analyticsService');
const deadlineService = require('../services/deadlineService');
const { sendSuccess } = require('../utils/apiResponse');

/**
 * GET /api/analytics/dashboard
 * Returns comprehensive dashboard statistics.
 */
const getDashboardStats = async (req, res, next) => {
  try {
    const stats = await analyticsService.getDashboardStats(req.userId);

    // Include upcoming deadlines for the dashboard widget
    const upcomingDeadlines = await deadlineService.getUpcomingDeadlines(req.userId, 7);

    return sendSuccess(res, { ...stats, upcomingDeadlines }, 'Dashboard stats retrieved');
  } catch (error) {
    next(error);
  }
};

/**
 * GET /api/analytics/weekly
 */
const getWeeklyStats = async (req, res, next) => {
  try {
    const stats = await analyticsService.getWeeklyStats(req.userId);
    return sendSuccess(res, { stats }, 'Weekly stats retrieved');
  } catch (error) {
    next(error);
  }
};

/**
 * GET /api/analytics/monthly
 */
const getMonthlyStats = async (req, res, next) => {
  try {
    const stats = await analyticsService.getMonthlyStats(req.userId);
    return sendSuccess(res, { stats }, 'Monthly stats retrieved');
  } catch (error) {
    next(error);
  }
};

module.exports = { getDashboardStats, getWeeklyStats, getMonthlyStats };
