const notificationService = require('../services/notificationService');
const { sendSuccess, sendError } = require('../utils/apiResponse');
const { HTTP_STATUS } = require('../config/constants');

/**
 * GET /api/notifications
 */
const getNotifications = async (req, res, next) => {
  try {
    const { page, limit } = req.query;
    const result = await notificationService.getNotificationHistory(req.userId, {
      page: parseInt(page, 10) || 1,
      limit: parseInt(limit, 10) || 20,
    });
    return sendSuccess(res, result, 'Notifications retrieved');
  } catch (error) {
    next(error);
  }
};

/**
 * GET /api/notifications/unread-count
 */
const getUnreadCount = async (req, res, next) => {
  try {
    const count = await notificationService.getUnreadCount(req.userId);
    return sendSuccess(res, { count }, 'Unread count retrieved');
  } catch (error) {
    next(error);
  }
};

/**
 * PATCH /api/notifications/:id/read
 */
const markAsRead = async (req, res, next) => {
  try {
    const notification = await notificationService.markAsRead(req.params.id, req.userId);
    if (!notification) {
      return sendError(res, 'Notification not found', HTTP_STATUS.NOT_FOUND);
    }
    return sendSuccess(res, { notification }, 'Notification marked as read');
  } catch (error) {
    next(error);
  }
};

/**
 * PATCH /api/notifications/mark-all-read
 */
const markAllRead = async (req, res, next) => {
  try {
    const Notification = require('../models/Notification');
    await Notification.updateMany(
      { userId: req.userId, isRead: false },
      { $set: { isRead: true, readAt: new Date() } }
    );
    return sendSuccess(res, null, 'All notifications marked as read');
  } catch (error) {
    next(error);
  }
};

module.exports = { getNotifications, getUnreadCount, markAsRead, markAllRead };
