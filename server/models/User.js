const mongoose = require('mongoose');
const { USER_ROLES } = require('../config/constants');

const notificationPreferencesSchema = new mongoose.Schema({
  highPriorityEmails: { type: Boolean, default: true },
  deadlineReminders: { type: Boolean, default: true },
  applicationUpdates: { type: Boolean, default: true },
  reminderHoursBefore: { type: Number, default: 24, min: 1, max: 168 },
  quietHoursStart: { type: String, default: '22:00' },
  quietHoursEnd: { type: String, default: '07:00' },
}, { _id: false });

const userSchema = new mongoose.Schema({
  googleId: {
    type: String,
    required: true,
    unique: true,
    index: true,
  },
  name: {
    type: String,
    required: true,
    trim: true,
    maxlength: 100,
  },
  email: {
    type: String,
    required: true,
    unique: true,
    lowercase: true,
    trim: true,
    index: true,
    match: [/^\S+@\S+\.\S+$/, 'Invalid email format'],
  },
  picture: {
    type: String,
    default: null,
  },
  registrationNumber: {
    type: String,
    default: process.env.STUDENT_REG_NO || '',
    trim: true,
  },
  neoPatId: {
    type: String,
    default: process.env.STUDENT_NEOPAT_ID || '',
    trim: true,
  },
  phone: {
    type: String,
    default: '',
    trim: true,
  },
  customAiPrompt: {
    type: String,
    default: 'Summarize email highlighting placement action items, test links, shortlist status, deadlines, and mandatory next steps.',
    trim: true,
  },
  role: {
    type: String,
    enum: Object.values(USER_ROLES),
    default: USER_ROLES.USER,
  },
  // Encrypted with AES-256 before storage
  googleRefreshToken: {
    type: String,
    default: null,
  },
  // Firebase Cloud Messaging token for push notifications
  fcmToken: {
    type: String,
    default: null,
  },
  // Gmail historyId for incremental sync
  historyId: {
    type: String,
    default: null,
  },
  notificationPreferences: {
    type: notificationPreferencesSchema,
    default: () => ({}),
  },
  isActive: {
    type: Boolean,
    default: true,
  },
  lastLoginAt: {
    type: Date,
    default: null,
  },
  lastSyncAt: {
    type: Date,
    default: null,
  },
}, {
  timestamps: true,
  versionKey: false,
});

// Indexes
userSchema.index({ role: 1 });
userSchema.index({ isActive: 1 });

// Remove sensitive fields from JSON output
userSchema.methods.toSafeJSON = function () {
  const obj = this.toObject();
  delete obj.googleRefreshToken;
  delete obj.fcmToken;
  return obj;
};

const User = mongoose.model('User', userSchema);

module.exports = User;
