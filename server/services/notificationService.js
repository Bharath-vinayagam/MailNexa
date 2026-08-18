const { getMessaging } = require('../config/firebase');
const Notification = require('../models/Notification');
const User = require('../models/User');
const { NOTIFICATION_TYPES } = require('../config/constants');
const logger = require('../utils/logger');

/**
 * Sends a push notification via FCM and saves to DB.
 */
const sendPushNotification = async ({ userId, emailId = null, deadlineId = null, title, body, type, data = {} }) => {
  // Save to DB
  const notification = await Notification.create({
    userId,
    emailId,
    deadlineId,
    title,
    body,
    type,
    data,
    sentAt: new Date(),
  });

  // Send via FCM
  const user = await User.findById(userId).select('fcmToken');
  if (!user || !user.fcmToken) {
    logger.debug(`No FCM token for user ${userId} – notification saved to DB only`);
    return notification;
  }

  const messaging = getMessaging();
  if (!messaging) {
    logger.warn('Firebase Messaging not available – skipping FCM send');
    return notification;
  }

  try {
    const message = {
      token: user.fcmToken,
      notification: { title, body },
      data: {
        type,
        notificationId: notification._id.toString(),
        ...Object.fromEntries(
          Object.entries(data).map(([k, v]) => [k, String(v)])
        ),
      },
      android: {
        priority: 'high',
        notification: {
          channelId: type === NOTIFICATION_TYPES.HIGH_PRIORITY_EMAIL ? 'high_priority' : 'default',
          sound: 'default',
        },
      },
      apns: {
        payload: {
          aps: {
            sound: 'default',
            badge: 1,
          },
        },
      },
    };

    const fcmResponse = await messaging.send(message);
    await Notification.findByIdAndUpdate(notification._id, {
      fcmMessageId: fcmResponse,
      delivered: true,
    });
    logger.debug(`FCM sent to user ${userId}: ${fcmResponse}`);
  } catch (fcmError) {
    logger.error(`FCM send failed for user ${userId}:`, fcmError.message);

    // If token is invalid, clear it
    if (
      fcmError.code === 'messaging/registration-token-not-registered' ||
      fcmError.code === 'messaging/invalid-registration-token'
    ) {
      await User.findByIdAndUpdate(userId, { fcmToken: null });
      logger.info(`Cleared invalid FCM token for user ${userId}`);
    }
  }

  return notification;
};

/**
 * Sends a high-priority email notification.
 */
const sendHighPriorityNotification = async (user, email) => {
  const summary = email.autoSummary || email.snippet || email.subject;
  return sendPushNotification({
    userId: user._id,
    emailId: email._id,
    title: `From: ${email.sender}`,
    body: `Summary: ${summary}`,
    type: NOTIFICATION_TYPES.HIGH_PRIORITY_EMAIL,
    data: { emailId: email._id.toString(), category: email.category },
  });
};

/**
 * Sends a deadline reminder notification.
 */
const sendDeadlineReminder = async (user, deadline) => {
  const hoursLeft = Math.floor((new Date(deadline.dueDate) - new Date()) / (1000 * 60 * 60));
  const timeText = hoursLeft <= 0 ? 'NOW' : hoursLeft < 24 ? `${hoursLeft}h` : `${Math.floor(hoursLeft / 24)} days`;

  return sendPushNotification({
    userId: user._id,
    deadlineId: deadline._id,
    title: `⏰ Deadline Due ${timeText}: ${deadline.title}`,
    body: deadline.source ? `Source: ${deadline.source}` : 'Check your deadlines',
    type: NOTIFICATION_TYPES.DEADLINE_REMINDER,
    data: { deadlineId: deadline._id.toString() },
  });
};

/**
 * Gets notification history for a user.
 */
const getNotificationHistory = async (userId, { page = 1, limit = 20 } = {}) => {
  const skip = (page - 1) * limit;
  const [notifications, total] = await Promise.all([
    Notification.find({ userId })
      .sort({ sentAt: -1 })
      .skip(skip)
      .limit(limit)
      .lean(),
    Notification.countDocuments({ userId }),
  ]);
  return { notifications, total };
};

/**
 * Marks a notification as read.
 */
const markAsRead = async (notificationId, userId) => {
  return Notification.findOneAndUpdate(
    { _id: notificationId, userId },
    { isRead: true, readAt: new Date() },
    { new: true }
  );
};

/**
 * Returns unread notification count for a user.
 */
const getUnreadCount = async (userId) => {
  return Notification.countDocuments({ userId, isRead: false });
};

module.exports = {
  sendPushNotification,
  sendHighPriorityNotification,
  sendDeadlineReminder,
  getNotificationHistory,
  markAsRead,
  getUnreadCount,
};
