const cron = require('node-cron');
const Deadline = require('../models/Deadline');
const User = require('../models/User');
const notificationService = require('../services/notificationService');
const logger = require('../utils/logger');

/**
 * Deadline Reminder Job – runs every 5 minutes.
 * Sends push notifications for deadlines approaching within 30 minutes, and 24 hours.
 */
const startDeadlineReminderJob = () => {
  // Run every 5 minutes
  cron.schedule('*/5 * * * *', async () => {
    logger.info('[DeadlineReminderJob] Checking deadlines for 30-min & 24h reminders...');
    let sent = 0;

    try {
      const now = new Date();

      // Find active pending deadlines
      const pendingDeadlines = await Deadline.find({
        isCompleted: false,
        isOverdue: false,
        dueDate: { $gte: now },
      }).populate('userId', 'notificationPreferences fcmToken isActive');

      for (const deadline of pendingDeadlines) {
        const user = deadline.userId;
        if (!user || !user.isActive) continue;

        const minsUntilDue = (new Date(deadline.dueDate) - now) / (1000 * 60);

        // 🚨 30-Minute Urgent Reminder Check (triggers between 0 and 35 mins before deadline)
        if (minsUntilDue <= 35 && minsUntilDue >= 0 && !deadline.reminderSent30m) {
          await notificationService.sendPushNotification({
            userId: user._id,
            deadlineId: deadline._id,
            title: `🚨 URGENT: Deadline in ${Math.round(minsUntilDue)} Mins!`,
            body: `${deadline.title} is due shortly. Take action now!`,
            type: NOTIFICATION_TYPES.DEADLINE_REMINDER,
            data: { deadlineId: deadline._id.toString(), urgent: 'true' },
          });

          await Deadline.findByIdAndUpdate(deadline._id, {
            reminderSent30m: true,
            reminderSentAt: new Date(),
          });
          sent++;
        }
        // ⏰ 24-Hour Standard Reminder Check
        else if (minsUntilDue <= 1440 && !deadline.reminderSent) {
          await notificationService.sendDeadlineReminder(user, deadline);
          await Deadline.findByIdAndUpdate(deadline._id, {
            reminderSent: true,
            reminderSentAt: new Date(),
          });
          sent++;
        }
      }

      if (sent > 0) {
        logger.info(`[DeadlineReminderJob] Sent ${sent} deadline reminders`);
      }
    } catch (error) {
      logger.error('[DeadlineReminderJob] Error:', error.message);
    }
  }, { scheduled: true, timezone: 'UTC' });

  logger.info('[DeadlineReminderJob] Scheduled every 5 minutes for 30-min urgent alerts');
};

module.exports = { startDeadlineReminderJob };
