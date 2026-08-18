const cron = require('node-cron');
const { markOverdueDeadlines } = require('../services/deadlineService');
const logger = require('../utils/logger');

/**
 * Overdue Detection Job – runs every 30 minutes.
 * Bulk-marks deadlines as overdue when their dueDate has passed.
 */
const startOverdueDetectionJob = () => {
  cron.schedule('*/30 * * * *', async () => {
    logger.info('[OverdueDetectionJob] Checking for overdue deadlines...');
    try {
      const count = await markOverdueDeadlines();
      if (count > 0) {
        logger.info(`[OverdueDetectionJob] Marked ${count} deadlines as overdue`);
      }
    } catch (error) {
      logger.error('[OverdueDetectionJob] Error:', error.message);
    }
  }, { scheduled: true, timezone: 'UTC' });

  logger.info('[OverdueDetectionJob] Scheduled every 30 minutes');
};

module.exports = { startOverdueDetectionJob };
