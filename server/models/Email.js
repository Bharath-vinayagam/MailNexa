const mongoose = require('mongoose');
const { EMAIL_CATEGORIES, EMAIL_PRIORITIES } = require('../config/constants');

const emailSchema = new mongoose.Schema({
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true,
    index: true,
  },
  gmailId: {
    type: String,
    required: true,
  },
  threadId: {
    type: String,
    default: null,
  },
  sender: {
    type: String,
    trim: true,
    default: '',
  },
  senderEmail: {
    type: String,
    lowercase: true,
    trim: true,
    default: '',
  },
  subject: {
    type: String,
    trim: true,
    default: '(No Subject)',
    maxlength: 500,
  },
  snippet: {
    type: String,
    trim: true,
    default: '',
    maxlength: 500,
  },
  body: {
    type: String,
    default: '',
  },
  category: {
    type: String,
    enum: Object.values(EMAIL_CATEGORIES),
    default: EMAIL_CATEGORIES.OTHERS,
    index: true,
  },
  priority: {
    type: String,
    enum: Object.values(EMAIL_PRIORITIES),
    default: EMAIL_PRIORITIES.LOW,
    index: true,
  },
  deadline: {
    type: Date,
    default: null,
    index: true,
  },
  deadlineDescription: {
    type: String,
    default: null,
  },
  labels: {
    type: [String],
    default: [],
  },
  isRead: {
    type: Boolean,
    default: false,
    index: true,
  },
  isApplied: {
    type: Boolean,
    default: false,
  },
  isShortlisted: {
    type: Boolean,
    default: false,
    index: true,
  },
  attachments: [{
    filename: { type: String },
    mimeType: { type: String },
    attachmentId: { type: String },
    size: { type: Number, default: 0 },
    isShortlisted: { type: Boolean, default: false },
  }],
  events: [{
    title: { type: String },
    date: { type: Date },
    type: { type: String }, // PPT, TEST, INTERVIEW, DEADLINE
  }],
  // True if user manually changed category/priority
  manualOverride: {
    type: Boolean,
    default: false,
  },
  // AI confidence score (0.0 – 1.0)
  aiConfidence: {
    type: Number,
    default: 0,
    min: 0,
    max: 1,
  },
  aiReasoning: {
    type: String,
    default: null,
  },
  // Auto-generated summary using user's custom AI prompt (set at sync time)
  autoSummary: {
    type: String,
    default: null,
  },
  receivedAt: {
    type: Date,
    required: true,
    index: true,
  },
}, {
  timestamps: true,
  versionKey: false,
});

// Compound unique index to prevent duplicate gmail messages per user
emailSchema.index({ userId: 1, gmailId: 1 }, { unique: true });
emailSchema.index({ userId: 1, category: 1, receivedAt: -1 });
emailSchema.index({ userId: 1, priority: 1, receivedAt: -1 });
emailSchema.index({ userId: 1, deadline: 1 });
emailSchema.index({ userId: 1, receivedAt: -1 });

// Full-text search index
emailSchema.index({
  subject: 'text',
  snippet: 'text',
  sender: 'text',
  senderEmail: 'text',
}, {
  weights: { subject: 10, sender: 5, senderEmail: 5, snippet: 1 },
  name: 'email_text_search',
});

const Email = mongoose.model('Email', emailSchema);

module.exports = Email;
