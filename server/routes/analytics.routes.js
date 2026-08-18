const express = require('express');
const router = express.Router();
const analyticsController = require('../controllers/analyticsController');
const authenticate = require('../middleware/auth');

router.use(authenticate);

router.get('/dashboard', analyticsController.getDashboardStats);
router.get('/weekly', analyticsController.getWeeklyStats);
router.get('/monthly', analyticsController.getMonthlyStats);

module.exports = router;
