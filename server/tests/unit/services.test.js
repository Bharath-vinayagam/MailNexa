const { MongoMemoryServer } = require('mongodb-memory-server');
const mongoose = require('mongoose');

// Set test environment variables
process.env.NODE_ENV = 'test';
process.env.JWT_SECRET = 'test_jwt_secret_minimum_64_characters_abcdefghijklmnopqrstuvwxyz12345';
process.env.JWT_REFRESH_SECRET = 'test_refresh_secret_min_64_chars_abcdefghijklmnopqrstuvwxyz12345';
process.env.JWT_EXPIRES_IN = '15m';
process.env.JWT_REFRESH_EXPIRES_IN = '7d';
process.env.ENCRYPTION_KEY = 'test_encryption_key_32_chars____';

describe('Encryption Service', () => {
  const { encrypt, decrypt } = require('../../services/encryptionService');

  test('should encrypt a string', () => {
    const plainText = 'my_refresh_token_value';
    const encrypted = encrypt(plainText);
    expect(encrypted).toBeDefined();
    expect(encrypted).not.toEqual(plainText);
  });

  test('should decrypt an encrypted string back to original', () => {
    const plainText = 'my_refresh_token_value';
    const encrypted = encrypt(plainText);
    const decrypted = decrypt(encrypted);
    expect(decrypted).toEqual(plainText);
  });

  test('should return null when encrypting null', () => {
    expect(encrypt(null)).toBeNull();
    expect(decrypt(null)).toBeNull();
  });

  test('should throw when decrypting invalid data', () => {
    expect(() => decrypt('invalid_cipher_text')).toThrow();
  });
});

describe('Token Utils', () => {
  const { signAccessToken, signRefreshToken, verifyAccessToken, verifyRefreshToken } = require('../../utils/tokenUtils');

  const payload = { userId: '507f1f77bcf86cd799439011', email: 'test@example.com', role: 'user' };

  test('should sign and verify an access token', () => {
    const token = signAccessToken(payload);
    expect(token).toBeDefined();
    const decoded = verifyAccessToken(token);
    expect(decoded.userId).toEqual(payload.userId);
    expect(decoded.email).toEqual(payload.email);
  });

  test('should sign and verify a refresh token', () => {
    const token = signRefreshToken(payload);
    const decoded = verifyRefreshToken(token);
    expect(decoded.userId).toEqual(payload.userId);
  });

  test('should throw when verifying an invalid access token', () => {
    expect(() => verifyAccessToken('invalid.token.here')).toThrow();
  });
});

describe('Date Utils', () => {
  const {
    startOfToday, endOfToday, daysFromNow, daysAgo, isToday, isPast, relativeTime,
  } = require('../../utils/dateUtils');

  test('startOfToday should be at 00:00:00', () => {
    const d = startOfToday();
    expect(d.getHours()).toBe(0);
    expect(d.getMinutes()).toBe(0);
    expect(d.getSeconds()).toBe(0);
  });

  test('endOfToday should be at 23:59:59', () => {
    const d = endOfToday();
    expect(d.getHours()).toBe(23);
    expect(d.getMinutes()).toBe(59);
    expect(d.getSeconds()).toBe(59);
  });

  test('daysFromNow should return correct future date', () => {
    const d = daysFromNow(3);
    const expectedDate = new Date();
    expectedDate.setDate(expectedDate.getDate() + 3);
    expect(d.getDate()).toEqual(expectedDate.getDate());
  });

  test('isToday should return true for today', () => {
    expect(isToday(new Date())).toBe(true);
  });

  test('isPast should return true for past dates', () => {
    expect(isPast(new Date(Date.now() - 1000))).toBe(true);
    expect(isPast(new Date(Date.now() + 100000))).toBe(false);
  });

  test('relativeTime should format correctly', () => {
    const futureDate = new Date(Date.now() + 26 * 60 * 60 * 1000);
    expect(relativeTime(futureDate)).toContain('days');
    const pastDate = new Date(Date.now() - 26 * 60 * 60 * 1000);
    expect(relativeTime(pastDate)).toContain('overdue');
  });
});

describe('Gmail Parser', () => {
  const { parseSender, decodeBase64, stripHtml } = require('../../utils/gmailParser');

  test('parseSender should extract name and email from "Name <email>"', () => {
    const result = parseSender('John Doe <john@example.com>');
    expect(result.name).toBe('John Doe');
    expect(result.email).toBe('john@example.com');
  });

  test('parseSender should handle email-only format', () => {
    const result = parseSender('john@example.com');
    expect(result.email).toBe('john@example.com');
  });

  test('decodeBase64 should decode base64url encoded strings', () => {
    const text = 'Hello, World!';
    const encoded = Buffer.from(text).toString('base64').replace(/\+/g, '-').replace(/\//g, '_');
    expect(decodeBase64(encoded)).toBe(text);
  });

  test('stripHtml should remove HTML tags', () => {
    const html = '<p>Hello <strong>World</strong></p>';
    const stripped = stripHtml(html);
    expect(stripped).toBe('Hello  World');
  });
});

describe('Fallback AI Classifier', () => {
  const { fallbackClassify } = require('../../services/aiClassificationService');

  test('should classify placement emails correctly', () => {
    const result = fallbackClassify({
      subject: 'Interview Invitation for Software Engineer Role',
      sender: 'HR TechCorp',
      snippet: 'We are pleased to invite you for an interview',
      body: 'Dear candidate, your application for the Software Engineer internship has been shortlisted.',
    });
    expect(result.category).toBe('Placement');
    expect(result.priority).toBe('High');
  });

  test('should classify academic emails', () => {
    const result = fallbackClassify({
      subject: 'Mid-term Exam Schedule',
      sender: 'University Registrar',
      snippet: 'Your exam timetable for the semester',
      body: 'The mid-term exam for CS402 is scheduled for next week.',
    });
    expect(result.category).toBe('Academic');
  });

  test('should classify promotional emails as low priority', () => {
    const result = fallbackClassify({
      subject: 'Sale! 50% off everything',
      sender: 'Store Newsletter',
      snippet: 'Huge discounts this weekend only',
      body: 'Subscribe to our newsletter for weekly deals and promotions.',
    });
    expect(result.priority).toBe('Low');
  });
});

describe('API Response Helpers', () => {
  const { sendSuccess, sendError, sendPaginated } = require('../../utils/apiResponse');

  const mockRes = () => {
    const res = {};
    res.status = jest.fn().mockReturnValue(res);
    res.json = jest.fn().mockReturnValue(res);
    return res;
  };

  test('sendSuccess should return 200 with success=true', () => {
    const res = mockRes();
    sendSuccess(res, { key: 'value' }, 'Done');
    expect(res.status).toHaveBeenCalledWith(200);
    expect(res.json).toHaveBeenCalledWith(
      expect.objectContaining({ success: true, message: 'Done' })
    );
  });

  test('sendError should return correct status code with success=false', () => {
    const res = mockRes();
    sendError(res, 'Not found', 404);
    expect(res.status).toHaveBeenCalledWith(404);
    expect(res.json).toHaveBeenCalledWith(
      expect.objectContaining({ success: false, error: 'Not found' })
    );
  });

  test('sendPaginated should include pagination metadata', () => {
    const res = mockRes();
    const pagination = { total: 100, page: 2, limit: 10, totalPages: 10, hasNextPage: true, hasPrevPage: true };
    sendPaginated(res, [], pagination, 'List');
    expect(res.json).toHaveBeenCalledWith(
      expect.objectContaining({ pagination })
    );
  });
});
