const deadlineService = require('../services/deadlineService');
const { sendSuccess, sendCreated, sendError, sendPaginated } = require('../utils/apiResponse');
const { HTTP_STATUS } = require('../config/constants');

const handleNotFound = (res, error) => {
  if (error.message === 'Deadline not found') {
    return sendError(res, 'Deadline not found', HTTP_STATUS.NOT_FOUND);
  }
  return null;
};

/**
 * POST /api/deadlines
 */
const createDeadline = async (req, res, next) => {
  try {
    const deadline = await deadlineService.createDeadline(req.userId, req.body);
    return sendCreated(res, { deadline }, 'Deadline created successfully');
  } catch (error) {
    next(error);
  }
};

/**
 * GET /api/deadlines
 */
const getDeadlines = async (req, res, next) => {
  try {
    const { deadlines, pagination } = await deadlineService.getDeadlines(req.userId, req.query);
    return sendPaginated(res, deadlines, pagination, 'Deadlines retrieved');
  } catch (error) {
    next(error);
  }
};

/**
 * GET /api/deadlines/today
 */
const getTodayDeadlines = async (req, res, next) => {
  try {
    const deadlines = await deadlineService.getTodayDeadlines(req.userId);
    return sendSuccess(res, { deadlines }, 'Today\'s deadlines retrieved');
  } catch (error) {
    next(error);
  }
};

/**
 * GET /api/deadlines/upcoming
 */
const getUpcomingDeadlines = async (req, res, next) => {
  try {
    const days = parseInt(req.query.days, 10) || 7;
    const deadlines = await deadlineService.getUpcomingDeadlines(req.userId, days);
    return sendSuccess(res, { deadlines }, 'Upcoming deadlines retrieved');
  } catch (error) {
    next(error);
  }
};

/**
 * GET /api/deadlines/overdue
 */
const getOverdueDeadlines = async (req, res, next) => {
  try {
    const deadlines = await deadlineService.getOverdueDeadlines(req.userId);
    return sendSuccess(res, { deadlines }, 'Overdue deadlines retrieved');
  } catch (error) {
    next(error);
  }
};

/**
 * GET /api/deadlines/:id
 */
const getDeadlineById = async (req, res, next) => {
  try {
    const deadline = await deadlineService.getDeadlineById(req.params.id, req.userId);
    return sendSuccess(res, { deadline }, 'Deadline retrieved');
  } catch (error) {
    const handled = handleNotFound(res, error);
    if (handled) return handled;
    next(error);
  }
};

/**
 * PUT /api/deadlines/:id
 */
const updateDeadline = async (req, res, next) => {
  try {
    const deadline = await deadlineService.updateDeadline(req.params.id, req.userId, req.body);
    return sendSuccess(res, { deadline }, 'Deadline updated');
  } catch (error) {
    const handled = handleNotFound(res, error);
    if (handled) return handled;
    next(error);
  }
};

/**
 * POST /api/deadlines/:id/complete
 */
const completeDeadline = async (req, res, next) => {
  try {
    const deadline = await deadlineService.completeDeadline(req.params.id, req.userId);
    return sendSuccess(res, { deadline }, 'Deadline marked as completed');
  } catch (error) {
    const handled = handleNotFound(res, error);
    if (handled) return handled;
    next(error);
  }
};

/**
 * DELETE /api/deadlines/:id
 */
const deleteDeadline = async (req, res, next) => {
  try {
    await deadlineService.deleteDeadline(req.params.id, req.userId);
    return sendSuccess(res, null, 'Deadline deleted');
  } catch (error) {
    const handled = handleNotFound(res, error);
    if (handled) return handled;
    next(error);
  }
};

module.exports = {
  createDeadline,
  getDeadlines,
  getTodayDeadlines,
  getUpcomingDeadlines,
  getOverdueDeadlines,
  getDeadlineById,
  updateDeadline,
  completeDeadline,
  deleteDeadline,
};
