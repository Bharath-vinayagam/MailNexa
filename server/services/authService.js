const { oauth2Client, getOAuth2Client } = require('../config/gmail');
const { GMAIL_SCOPES } = require('../config/constants');
const { signAccessToken, signRefreshToken, verifyRefreshToken } = require('../utils/tokenUtils');
const { encrypt, decrypt } = require('./encryptionService');
const User = require('../models/User');
const auditService = require('./auditService');
const logger = require('../utils/logger');

/**
 * Generates the Google OAuth2 authorization URL.
 */
const getAuthUrl = () => {
  return oauth2Client.generateAuthUrl({
    access_type: 'offline',
    scope: GMAIL_SCOPES,
    prompt: 'consent',
    include_granted_scopes: true,
  });
};

/**
 * Demo / Quick Student login. Creates a valid Mongoose user and issues real JWT tokens.
 */
const demoLogin = async (emailInput) => {
  const email = (emailInput || 'student@university.edu').toLowerCase().trim();
  const name = email.split('@')[0].replace('.', ' ').toUpperCase();

  let user = await User.findOne({ email });
  if (!user) {
    user = await User.create({
      name: name.length > 0 ? name : 'Bharath',
      email,
      googleId: `demo_${Date.now()}`,
      role: 'user',
      isActive: true,
      lastLoginAt: new Date(),
    });
  } else {
    user.lastLoginAt = new Date();
    await user.save();
  }

  const payload = { userId: user._id.toString(), email: user.email, role: user.role };
  const accessToken = signAccessToken(payload);
  const refreshToken = signRefreshToken(payload);

  return {
    accessToken,
    refreshToken,
    user: {
      id: user._id.toString(),
      name: user.name,
      email: user.email,
      role: user.role,
      picture: user.picture || null,
    },
  };
};

/**
 * Exchanges a Google authorization code for tokens and upserts the user.
 */
const googleAuthCallback = async (code, ipAddress, userAgent) => {
  try {
    const { google } = require('googleapis');
    const cleanClient = new google.auth.OAuth2(
      process.env.GOOGLE_CLIENT_ID,
      process.env.GOOGLE_CLIENT_SECRET
    );

    let tokens;
    try {
      const res = await cleanClient.getToken(code);
      tokens = res.tokens;
    } catch (err1) {
      logger.error('cleanClient.getToken(code) failed:', err1.response?.data || err1.message);
      try {
        const res = await oauth2Client.getToken({ code, redirect_uri: 'postmessage' });
        tokens = res.tokens;
      } catch (err2) {
        logger.error('oauth2Client.getToken postmessage failed:', err2.response?.data || err2.message);
        throw err1;
      }
    }

    oauth2Client.setCredentials(tokens);

    const oauth2 = getOAuth2Client(tokens.refresh_token || tokens.access_token);
    const { data: profile } = await oauth2.userinfo.get();

    if (!profile.email) {
      return demoLogin('student@university.edu');
    }

    const tokenToSave = tokens.refresh_token || tokens.access_token;
    const encryptedRefreshToken = tokenToSave ? encrypt(tokenToSave) : null;

    let user = await User.findOneAndUpdate(
      { email: profile.email.toLowerCase() },
      {
        $set: {
          googleId: profile.id,
          name: profile.name,
          email: profile.email.toLowerCase(),
          picture: profile.picture || null,
          lastLoginAt: new Date(),
          ...(encryptedRefreshToken && { googleRefreshToken: encryptedRefreshToken }),
        },
      },
      { new: true, upsert: true }
    );

    setImmediate(() => {
      const { syncUserEmails } = require('./gmailSyncService');
      syncUserEmails(user).catch(err => logger.error('Initial post-login Gmail sync failed:', err.message));
    });

    const jwtPayload = { userId: user._id.toString(), email: user.email, role: user.role };
    const accessToken = signAccessToken(jwtPayload);
    const refreshToken = signRefreshToken(jwtPayload);

    return {
      accessToken,
      refreshToken,
      user: {
        id: user._id.toString(),
        name: user.name,
        email: user.email,
        role: user.role,
        picture: user.picture || null,
      },
    };
  } catch (error) {
    logger.error('Google token exchange failed:', error.response?.data || error.message || error);
    throw new Error(`Google Auth failed: ${error.response?.data?.error_description || error.message}`);
  }
};

/**
 * Rotates a refresh token to generate a new token pair.
 */
const refreshAccessToken = async (token) => {
  const decoded = verifyRefreshToken(token);
  const user = await User.findById(decoded.userId);
  if (!user || !user.isActive) {
    throw new Error('Invalid or inactive user account');
  }

  const jwtPayload = { userId: user._id.toString(), email: user.email, role: user.role };
  const newAccessToken = signAccessToken(jwtPayload);
  const newRefreshToken = signRefreshToken(jwtPayload);

  return {
    accessToken: newAccessToken,
    refreshToken: newRefreshToken,
    user: {
      id: user._id.toString(),
      name: user.name,
      email: user.email,
      role: user.role,
    },
  };
};

/**
 * Logs out the user.
 */
const logout = async (user, ipAddress, userAgent) => {
  if (user && user.googleRefreshToken) {
    try {
      const decrypted = decrypt(user.googleRefreshToken);
      await oauth2Client.revokeToken(decrypted);
    } catch (error) {
      logger.warn('Failed to revoke Google token for user:', user._id, error.message);
    }
  }
};

/**
 * Returns the full user profile.
 */
const getProfile = async (userId) => {
  const user = await User.findById(userId).select('-googleRefreshToken -fcmToken');
  if (!user) throw new Error('User not found');
  return user;
};

/**
 * Updates the user's FCM token for push notifications.
 */
const updateFcmToken = async (userId, fcmToken) => {
  await User.findByIdAndUpdate(userId, { fcmToken });
};

module.exports = {
  getAuthUrl,
  googleAuthCallback,
  refreshAccessToken,
  logout,
  getProfile,
  updateFcmToken,
  demoLogin,
};
