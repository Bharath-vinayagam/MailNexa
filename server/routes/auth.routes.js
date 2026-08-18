const express = require('express');
const router = express.Router();
const authController = require('../controllers/authController');
const authenticate = require('../middleware/auth');
const { authLimiter } = require('../middleware/rateLimiter');

// GET /api/auth/url – get Google OAuth URL
router.get('/url', authController.getAuthUrl);

// POST /api/auth/google – exchange code for tokens
router.post('/google', authLimiter, authController.googleAuth);

// POST /api/auth/demo-login – quick email-based login (dev/testing)
router.post('/demo-login', authLimiter, authController.demoLogin);

// POST /api/auth/refresh – rotate refresh token
router.post('/refresh', authLimiter, authController.refreshToken);

// POST /api/auth/logout – revoke tokens
router.post('/logout', authenticate, authController.logout);

// GET /api/auth/profile – get user profile
router.get('/profile', authenticate, authController.getProfile);

// PATCH /api/auth/profile – update student profile identifiers
router.patch('/profile', authenticate, authController.updateProfile);

// PUT /api/auth/fcm-token – register FCM token
router.put('/fcm-token', authenticate, authController.updateFcmToken);

module.exports = router;
