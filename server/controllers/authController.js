const authService = require('../services/authService');
const { sendSuccess, sendError } = require('../utils/apiResponse');
const { HTTP_STATUS } = require('../config/constants');

/**
 * GET /api/auth/url
 * Returns the Google OAuth authorization URL.
 */
const getAuthUrl = (req, res) => {
  const url = authService.getAuthUrl();
  return sendSuccess(res, { url }, 'Authorization URL generated');
};

/**
 * POST /api/auth/google
 * Exchanges Google authorization code for JWT tokens.
 * Body: { code: string }
 */
const googleAuth = async (req, res, next) => {
  try {
    const { code } = req.body;
    if (!code) {
      return sendError(res, 'Authorization code is required', HTTP_STATUS.BAD_REQUEST);
    }

    const result = await authService.googleAuthCallback(
      code,
      req.ip,
      req.headers['user-agent']
    );

    return sendSuccess(res, result, 'Authentication successful');
  } catch (error) {
    next(error);
  }
};

/**
 * POST /api/auth/refresh
 * Rotates refresh token and returns new token pair.
 * Body: { refreshToken: string }
 */
const refreshToken = async (req, res, next) => {
  try {
    const { refreshToken: token } = req.body;
    if (!token) {
      return sendError(res, 'Refresh token is required', HTTP_STATUS.BAD_REQUEST);
    }

    const tokens = await authService.refreshAccessToken(token);
    return sendSuccess(res, tokens, 'Token refreshed successfully');
  } catch (error) {
    if (error.message.includes('Invalid') || error.message.includes('expired')) {
      return sendError(res, error.message, HTTP_STATUS.UNAUTHORIZED);
    }
    next(error);
  }
};

/**
 * POST /api/auth/logout
 * Revokes Google OAuth access and logs out the user.
 */
const logout = async (req, res, next) => {
  try {
    await authService.logout(req.user, req.ip, req.headers['user-agent']);
    return sendSuccess(res, null, 'Logged out successfully');
  } catch (error) {
    next(error);
  }
};

/**
 * GET /api/auth/profile
 * Returns the authenticated user's profile.
 */
const getProfile = async (req, res, next) => {
  try {
    const user = await authService.getProfile(req.userId);
    return sendSuccess(res, { user }, 'Profile retrieved successfully');
  } catch (error) {
    next(error);
  }
};

/**
 * PUT /api/auth/fcm-token
 * Updates the user's FCM token for push notifications.
 * Body: { fcmToken: string }
 */
const updateFcmToken = async (req, res, next) => {
  try {
    const { fcmToken } = req.body;
    if (!fcmToken) {
      return sendError(res, 'FCM token is required', HTTP_STATUS.BAD_REQUEST);
    }
    await authService.updateFcmToken(req.userId, fcmToken);
    return sendSuccess(res, null, 'FCM token updated');
  } catch (error) {
    next(error);
  }
};

/**
 * PATCH /api/auth/profile
 * Updates student identifier fields (registrationNumber, neoPatId, phone).
 */
const updateProfile = async (req, res, next) => {
  try {
    const { registrationNumber, neoPatId, phone, customAiPrompt } = req.body || {};
    const User = require('../models/User');
    const update = {};
    if (registrationNumber !== undefined) update.registrationNumber = registrationNumber;
    if (neoPatId !== undefined) update.neoPatId = neoPatId;
    if (phone !== undefined) update.phone = phone;
    if (customAiPrompt !== undefined) update.customAiPrompt = customAiPrompt;

    const user = await User.findByIdAndUpdate(req.userId, { $set: update }, { new: true });
    return sendSuccess(res, { user: user.toSafeJSON() }, 'Profile updated successfully');
  } catch (error) {
    next(error);
  }
};

/**
 * POST /api/auth/demo-login
 * Quick email-based login for dev/testing — finds or creates user by email.
 * Body: { email: string }
 */
const demoLogin = async (req, res, next) => {
  try {
    const { email } = req.body;
    if (!email) {
      return sendError(res, 'Email is required', HTTP_STATUS.BAD_REQUEST);
    }

    const User = require('../models/User');
    const { signAccessToken, signRefreshToken } = require('../utils/tokenUtils');

    // Find or create the user by email
    let user = await User.findOne({ email: email.toLowerCase().trim() });
    if (!user) {
      user = await User.create({
        email: email.toLowerCase().trim(),
        name: email.split('@')[0].replace(/[._]/g, ' '),
        googleId: `demo_${email.toLowerCase().trim().replace(/[^a-z0-9]/g, '_')}`,
        role: 'user',
        isActive: true,
        registrationNumber: process.env.STUDENT_REG_NO || '<YOUR_REG_NO>',
        neoPatId: process.env.STUDENT_NEOPAT_ID || '<YOUR_NEOPAT_ID>',
      });
    }

    const accessToken = signAccessToken({ userId: user._id, email: user.email, role: user.role });
    const refreshToken = signRefreshToken({ userId: user._id });

    return sendSuccess(res, {
      accessToken,
      refreshToken,
      user: user.toSafeJSON ? user.toSafeJSON() : user,
    }, 'Login successful');
  } catch (error) {
    next(error);
  }
};

module.exports = { getAuthUrl, googleAuth, refreshToken, logout, getProfile, updateFcmToken, updateProfile, demoLogin };
