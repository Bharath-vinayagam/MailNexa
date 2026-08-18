const emailService = require('../services/emailService');
const gmailSyncService = require('../services/gmailSyncService');
const { sendSuccess, sendError, sendPaginated } = require('../utils/apiResponse');
const { HTTP_STATUS } = require('../config/constants');
const User = require('../models/User');
const logger = require('../utils/logger');

/**
 * GET /api/emails
 * Returns paginated, filtered, sortable email list.
 */
const getEmails = async (req, res, next) => {
  try {
    const { emails, pagination } = await emailService.getEmails(req.userId, req.query);
    return sendPaginated(res, emails, pagination, 'Emails retrieved successfully');
  } catch (error) {
    next(error);
  }
};

/**
 * GET /api/emails/:id
 * Returns a single email by ID.
 */
const getEmailById = async (req, res, next) => {
  try {
    let email = await emailService.getEmailById(req.params.id, req.userId);
    if (!email.autoSummary || email.autoSummary.trim().length === 0) {
      try {
        const { summarizeEmail } = require('../config/gemini');
        const autoSummary = await summarizeEmail(email, null);
        const Email = require('../models/Email');
        await Email.findByIdAndUpdate(email._id, { autoSummary });
        email = email.toObject ? email.toObject() : email;
        email.autoSummary = autoSummary;
      } catch (sumErr) {
        logger.warn(`On-demand auto-summary failed for ${req.params.id}:`, sumErr.message);
      }
    }
    return sendSuccess(res, { email }, 'Email retrieved successfully');
  } catch (error) {
    if (error.message === 'Email not found') {
      return sendError(res, 'Email not found', HTTP_STATUS.NOT_FOUND);
    }
    next(error);
  }
};

/**
 * POST /api/emails/:id/mark-applied
 * Marks an email as applied.
 */
const markApplied = async (req, res, next) => {
  try {
    const email = await emailService.markEmailAsApplied(req.params.id, req.userId);
    return sendSuccess(res, { email }, 'Email marked as applied');
  } catch (error) {
    if (error.message === 'Email not found') {
      return sendError(res, 'Email not found', HTTP_STATUS.NOT_FOUND);
    }
    next(error);
  }
};

/**
 * PATCH /api/emails/:id/category
 * Changes the category/priority of an email (manual override).
 * Body: { category?: string, priority?: string }
 */
const changeCategory = async (req, res, next) => {
  try {
    const { category, priority } = req.body;
    const email = await emailService.changeCategory(req.params.id, req.userId, { category, priority });
    return sendSuccess(res, { email }, 'Email category updated');
  } catch (error) {
    if (error.message === 'Email not found') {
      return sendError(res, 'Email not found', HTTP_STATUS.NOT_FOUND);
    }
    next(error);
  }
};

/**
 * POST /api/emails/sync
 * Manually triggers Gmail sync for the current user.
 */
const triggerSync = async (req, res, next) => {
  try {
    const user = await User.findById(req.userId);
    const result = await gmailSyncService.syncUserEmails(user);
    return sendSuccess(res, result, `Sync complete: ${result.synced} new emails processed`);
  } catch (error) {
    next(error);
  }
};

/**
 * GET /api/emails/search
 * Full-text + filtered email search.
 */
const searchEmails = async (req, res, next) => {
  try {
    const { q, category, priority, page, limit } = req.query;
    const result = await emailService.searchEmails(req.userId, { query: q, category, priority, page, limit });
    return sendPaginated(res, result.emails, result.pagination, 'Search results');
  } catch (error) {
    next(error);
  }
};

/**
 * GET /api/emails/today-priority
 * Returns today's high-priority emails for the dashboard.
 */
const getTodayPriorityEmails = async (req, res, next) => {
  try {
    const emails = await emailService.getTodayHighPriorityEmails(req.userId);
    return sendSuccess(res, { emails }, 'Today\'s priority emails retrieved');
  } catch (error) {
    next(error);
  }
};

/**
 * POST /api/emails/:id/summarize
 * Generates an on-demand custom AI summary for a specific email.
 * Body: { customPrompt?: string }
 */
const summarizeWithPrompt = async (req, res, next) => {
  try {
    const { customPrompt } = req.body || {};
    const email = await emailService.getEmailById(req.params.id, req.userId);
    const { summarizeEmail } = require('../config/gemini');
    const summary = await summarizeEmail(email, customPrompt);
    return sendSuccess(res, { summary }, 'Custom summary generated successfully');
  } catch (error) {
    if (error.response?.status === 429 || error.message.includes('429')) {
      return sendError(res, 'AI is currently busy due to rate limits. Please try again in 5-10 seconds.', HTTP_STATUS.TOO_MANY_REQUESTS);
    }
    next(error);
  }
};

module.exports = {
  getEmails,
  getEmailById,
  markApplied,
  changeCategory,
  triggerSync,
  searchEmails,
  getTodayPriorityEmails,
  summarizeWithPrompt,
};
