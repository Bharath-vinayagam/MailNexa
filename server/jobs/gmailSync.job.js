const cron = require('node-cron');
const { syncAllUsers } = require('../services/gmailSyncService');
const logger = require('../utils/logger');

/**
 * Gmail Sync Job – runs every 5 minutes.
 * Fetches new emails for all active users using incremental historyId sync.
 */
const startGmailSyncJob = () => {
  const interval = parseInt(process.env.GMAIL_SYNC_INTERVAL_MINUTES, 10) || 1;
  const cronExpression = interval === 1 ? '* * * * *' : `*/${interval} * * * *`;

  cron.schedule(cronExpression, async () => {
    logger.info('[GmailSyncJob] Starting scheduled Gmail sync...');
    try {
      const result = await syncAllUsers();
      logger.info(`[GmailSyncJob] Sync complete: ${result.succeeded} users synced, ${result.failed} failed`);
    } catch (error) {
      logger.error('[GmailSyncJob] Sync job failed:', error.message);
    }
  }, {
    scheduled: true,
    timezone: 'UTC',
  });

  logger.info(`[GmailSyncJob] Scheduled every ${interval} minutes`);
};

module.exports = { startGmailSyncJob };
