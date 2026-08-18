const express = require('express');
const router = express.Router();
const emailController = require('../controllers/emailController');
const authenticate = require('../middleware/auth');
const { syncLimiter } = require('../middleware/rateLimiter');
const auditLog = require('../middleware/auditLogger');
const { AUDIT_ACTIONS, AUDIT_RESOURCES } = require('../config/constants');

// All email routes require authentication
router.use(authenticate);

// GET /api/emails/search
router.get('/search', emailController.searchEmails);

// GET /api/emails/today-priority
router.get('/today-priority', emailController.getTodayPriorityEmails);

// POST /api/emails/sync – manual Gmail sync trigger
router.post('/sync', syncLimiter, emailController.triggerSync);

// GET /api/emails
router.get('/', emailController.getEmails);

// GET /api/emails/:id
router.get('/:id', emailController.getEmailById);

// POST /api/emails/:id/mark-applied
router.post(
  '/:id/mark-applied',
  auditLog(AUDIT_ACTIONS.UPDATE, AUDIT_RESOURCES.EMAIL),
  emailController.markApplied
);

// PATCH /api/emails/:id/category
router.patch(
  '/:id/category',
  auditLog(AUDIT_ACTIONS.OVERRIDE, AUDIT_RESOURCES.EMAIL),
  emailController.changeCategory
);

// POST /api/emails/:id/summarize
router.post('/:id/summarize', emailController.summarizeWithPrompt);

module.exports = router;
