const { google } = require('googleapis');

const oauth2Client = new google.auth.OAuth2(
  process.env.GOOGLE_CLIENT_ID,
  process.env.GOOGLE_CLIENT_SECRET,
  process.env.GOOGLE_REDIRECT_URI
);

/**
 * Creates an authenticated OAuth2 client for a specific user.
 * @param {string} refreshToken - The user's decrypted refresh token
 * @returns {OAuth2Client} Authenticated client
 */
const createAuthenticatedClient = (token) => {
  const client = new google.auth.OAuth2(
    process.env.GOOGLE_CLIENT_ID,
    process.env.GOOGLE_CLIENT_SECRET,
    process.env.GOOGLE_REDIRECT_URI
  );
  client.setCredentials({
    refresh_token: token,
    access_token: token,
  });
  return client;
};

/**
 * Returns a Gmail API instance authenticated with the given refresh token.
 * @param {string} refreshToken
 * @returns {gmail_v1.Gmail}
 */
const getGmailClient = (refreshToken) => {
  const authClient = createAuthenticatedClient(refreshToken);
  return google.gmail({ version: 'v1', auth: authClient });
};

/**
 * Returns a Google People / OAuth2 API instance.
 * @param {string} refreshToken
 * @returns {oauth2_v2.Oauth2}
 */
const getOAuth2Client = (refreshToken) => {
  const authClient = createAuthenticatedClient(refreshToken);
  return google.oauth2({ version: 'v2', auth: authClient });
};

module.exports = { oauth2Client, createAuthenticatedClient, getGmailClient, getOAuth2Client };
