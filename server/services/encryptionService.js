const CryptoJS = require('crypto-js');
const logger = require('../utils/logger');

const getKey = () => {
  const key = process.env.ENCRYPTION_KEY;
  if (!key) {
    throw new Error('ENCRYPTION_KEY is not configured');
  }
  return key;
};

/**
 * Encrypts a string using AES-256.
 * @param {string} text - Plain text to encrypt
 * @returns {string} Encrypted ciphertext
 */
const encrypt = (text) => {
  if (!text) return null;
  try {
    const ciphertext = CryptoJS.AES.encrypt(text, getKey()).toString();
    return ciphertext;
  } catch (error) {
    logger.error('Encryption failed:', error.message);
    throw new Error('Failed to encrypt data');
  }
};

/**
 * Decrypts an AES-256 encrypted string.
 * @param {string} ciphertext - Encrypted text
 * @returns {string} Decrypted plain text
 */
const decrypt = (ciphertext) => {
  if (!ciphertext) return null;
  try {
    const bytes = CryptoJS.AES.decrypt(ciphertext, getKey());
    const decrypted = bytes.toString(CryptoJS.enc.Utf8);
    if (!decrypted) throw new Error('Decryption produced empty string');
    return decrypted;
  } catch (error) {
    logger.error('Decryption failed:', error.message);
    throw new Error('Failed to decrypt data');
  }
};

module.exports = { encrypt, decrypt };
