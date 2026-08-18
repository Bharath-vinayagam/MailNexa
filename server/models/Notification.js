const mongoose = require('mongoose');
const { NOTIFICATION_TYPES } = require('../config/constants');

const notificationSchema = new mongoose.Schema({
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true,
    index: true,
  },
  emailId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Email',
    default: null,
  },
  deadlineId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Deadline',
    default: null,
  },
  title: {
    type: String,
    required: true,
    trim: true,
    maxlength: 200,
  },
  body: {
    type: String,
    required: true,
    trim: true,
    maxlength: 500,
  },
  type: {
    type: String,
    enum: Object.values(NOTIFICATION_TYPES),
    required: true,
    index: true,
  },
  // FCM delivery status
  fcmMessageId: {
    type: String,
    default: null,
  },
  delivered: {
    type: Boolean,
    default: false,
  },
  isRead: {
    type: Boolean,
    default: false,
    index: true,
  },
  sentAt: {
    type: Date,
    default: Date.now,
  },
  readAt: {
    type: Date,
    default: null,
  },
  // Extra data for deep linking in mobile app
  data: {
    type: mongoose.Schema.Types.Mixed,
    default: {},
  },
}, {
  timestamps: true,
  versionKey: false,
});

notificationSchema.index({ userId: 1, sentAt: -1 });
notificationSchema.index({ userId: 1, isRead: 1 });
notificationSchema.index({ userId: 1, type: 1 });

const Notification = mongoose.model('Notification', notificationSchema);

module.exports = Notification;
