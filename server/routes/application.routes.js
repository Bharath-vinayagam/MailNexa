const express = require('express');
const router = express.Router();
const applicationController = require('../controllers/applicationController');
const authenticate = require('../middleware/auth');
const auditLog = require('../middleware/auditLogger');
const { AUDIT_ACTIONS, AUDIT_RESOURCES } = require('../config/constants');

router.use(authenticate);

router.get('/grouped', applicationController.getApplicationsGrouped);
router.get('/stats', applicationController.getApplicationStats);
router.get('/', applicationController.getApplications);

router.post(
  '/',
  auditLog(AUDIT_ACTIONS.CREATE, AUDIT_RESOURCES.APPLICATION),
  applicationController.createApplication
);

router.get('/:id', applicationController.getApplicationById);

router.put(
  '/:id',
  auditLog(AUDIT_ACTIONS.UPDATE, AUDIT_RESOURCES.APPLICATION),
  applicationController.updateApplication
);

router.patch(
  '/:id/status',
  auditLog(AUDIT_ACTIONS.UPDATE, AUDIT_RESOURCES.APPLICATION),
  applicationController.updateStatus
);

router.delete(
  '/:id',
  auditLog(AUDIT_ACTIONS.DELETE, AUDIT_RESOURCES.APPLICATION),
  applicationController.deleteApplication
);

module.exports = router;
