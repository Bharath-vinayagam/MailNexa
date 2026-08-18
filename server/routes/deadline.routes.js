const express = require('express');
const router = express.Router();
const deadlineController = require('../controllers/deadlineController');
const authenticate = require('../middleware/auth');
const auditLog = require('../middleware/auditLogger');
const { AUDIT_ACTIONS, AUDIT_RESOURCES } = require('../config/constants');

router.use(authenticate);

router.get('/today', deadlineController.getTodayDeadlines);
router.get('/upcoming', deadlineController.getUpcomingDeadlines);
router.get('/overdue', deadlineController.getOverdueDeadlines);
router.get('/', deadlineController.getDeadlines);

router.post(
  '/',
  auditLog(AUDIT_ACTIONS.CREATE, AUDIT_RESOURCES.DEADLINE),
  deadlineController.createDeadline
);

router.get('/:id', deadlineController.getDeadlineById);

router.put(
  '/:id',
  auditLog(AUDIT_ACTIONS.UPDATE, AUDIT_RESOURCES.DEADLINE),
  deadlineController.updateDeadline
);

router.post(
  '/:id/complete',
  auditLog(AUDIT_ACTIONS.UPDATE, AUDIT_RESOURCES.DEADLINE),
  deadlineController.completeDeadline
);

router.delete(
  '/:id',
  auditLog(AUDIT_ACTIONS.DELETE, AUDIT_RESOURCES.DEADLINE),
  deadlineController.deleteDeadline
);

module.exports = router;
