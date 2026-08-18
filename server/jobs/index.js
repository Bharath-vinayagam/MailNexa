const { startGmailSyncJob } = require('./gmailSync.job');
const { startDeadlineReminderJob } = require('./deadlineReminder.job');
const { startOverdueDetectionJob } = require('./overdueDetection.job');
const logger = require('../utils/logger');

/**
 * Starts all background jobs.
 * Called once during server startup.
 */
const startAllJobs = () => {
  logger.info('Starting background jobs...');
  startGmailSyncJob();
  startDeadlineReminderJob();
  startOverdueDetectionJob();
  logger.info('All background jobs started');
};

module.exports = { startAllJobs };
