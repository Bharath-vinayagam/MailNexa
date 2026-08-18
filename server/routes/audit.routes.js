const express = require('express');
const router = express.Router();
const auditController = require('../controllers/auditController');
const authenticate = require('../middleware/auth');
const authorize = require('../middleware/authorize');
const { USER_ROLES } = require('../config/constants');

router.use(authenticate);

// User can see their own logs
router.get('/my-logs', auditController.getMyLogs);
router.get('/login-history', auditController.getLoginHistory);

// Admin-only routes
router.get('/logs', authorize(USER_ROLES.ADMIN), auditController.getLogs);
router.get('/security', authorize(USER_ROLES.ADMIN), auditController.getSecurityLogs);

module.exports = router;
