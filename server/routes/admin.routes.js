const express = require('express');
const router = express.Router();
const adminController = require('../controllers/adminController');
const authenticate = require('../middleware/auth');
const authorize = require('../middleware/authorize');
const { USER_ROLES } = require('../config/constants');

// All admin routes require authentication + admin role
router.use(authenticate, authorize(USER_ROLES.ADMIN));

router.get('/users', adminController.listUsers);
router.get('/users/:id', adminController.getUserDetails);
router.patch('/users/:id/role', adminController.updateUserRole);
router.patch('/users/:id/deactivate', adminController.deactivateUser);
router.get('/stats', adminController.getSystemStats);

module.exports = router;
