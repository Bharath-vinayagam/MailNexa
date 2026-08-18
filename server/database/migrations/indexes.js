require('dotenv').config();
const mongoose = require('mongoose');
const logger = require('../../utils/logger');

const MONGO_URI = process.env.MONGODB_URI || 'mongodb://localhost:27017/mailguard';

const createIndexes = async () => {
  await mongoose.connect(MONGO_URI);
  logger.info('Creating MongoDB indexes...');

  const db = mongoose.connection.db;

  // Users collection
  await db.collection('users').createIndexes([
    { key: { email: 1 }, unique: true, background: true },
    { key: { googleId: 1 }, unique: true, background: true },
    { key: { role: 1 }, background: true },
    { key: { isActive: 1 }, background: true },
    { key: { createdAt: -1 }, background: true },
  ]);

  // Emails collection
  await db.collection('emails').createIndexes([
    { key: { userId: 1, gmailId: 1 }, unique: true, background: true },
    { key: { userId: 1, category: 1, receivedAt: -1 }, background: true },
    { key: { userId: 1, priority: 1, receivedAt: -1 }, background: true },
    { key: { userId: 1, deadline: 1 }, background: true },
    { key: { userId: 1, receivedAt: -1 }, background: true },
    { key: { userId: 1, isRead: 1 }, background: true },
    {
      key: { subject: 'text', snippet: 'text', sender: 'text', senderEmail: 'text' },
      weights: { subject: 10, sender: 5, senderEmail: 5, snippet: 1 },
      name: 'email_text_search',
      background: true,
    },
  ]);

  // Applications collection
  await db.collection('applications').createIndexes([
    { key: { userId: 1, companyName: 1 }, background: true },
    { key: { userId: 1, status: 1 }, background: true },
    { key: { userId: 1, appliedAt: -1 }, background: true },
    {
      key: { companyName: 'text', role: 'text', location: 'text' },
      name: 'application_text_search',
      background: true,
    },
  ]);

  // Deadlines collection
  await db.collection('deadlines').createIndexes([
    { key: { userId: 1, dueDate: 1 }, background: true },
    { key: { userId: 1, isCompleted: 1, dueDate: 1 }, background: true },
    { key: { userId: 1, isOverdue: 1 }, background: true },
    { key: { reminderSent: 1, dueDate: 1 }, background: true },
  ]);

  // Notifications collection
  await db.collection('notifications').createIndexes([
    { key: { userId: 1, sentAt: -1 }, background: true },
    { key: { userId: 1, isRead: 1 }, background: true },
  ]);

  // AuditLogs collection
  await db.collection('auditlogs').createIndexes([
    { key: { userId: 1, timestamp: -1 }, background: true },
    { key: { action: 1, timestamp: -1 }, background: true },
    { key: { timestamp: -1 }, background: true },
    // TTL index: delete after 1 year
    { key: { timestamp: 1 }, expireAfterSeconds: 365 * 24 * 3600, background: true },
  ]);

  logger.info('✅ All indexes created successfully');
  await mongoose.disconnect();
};

createIndexes().catch((err) => {
  logger.error('Index creation failed:', err);
  process.exit(1);
});
