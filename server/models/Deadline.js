const mongoose = require('mongoose');

const deadlineSchema = new mongoose.Schema({
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
  title: {
    type: String,
    required: true,
    trim: true,
    maxlength: 300,
  },
  description: {
    type: String,
    default: '',
    maxlength: 1000,
  },
  source: {
    type: String,
    trim: true,
    default: '',
    maxlength: 200,
  },
  dueDate: {
    type: Date,
    required: true,
    index: true,
  },
  isCompleted: {
    type: Boolean,
    default: false,
    index: true,
  },
  isOverdue: {
    type: Boolean,
    default: false,
    index: true,
  },
  completedAt: {
    type: Date,
    default: null,
  },
  // True when at least one reminder has been sent
  reminderSent: {
    type: Boolean,
    default: false,
  },
  reminderSent30m: {
    type: Boolean,
    default: false,
  },
  reminderSentAt: {
    type: Date,
    default: null,
  },
  // Category for display purposes
  category: {
    type: String,
    default: 'General',
  },
}, {
  timestamps: true,
  versionKey: false,
});

// Compound indexes
deadlineSchema.index({ userId: 1, dueDate: 1 });
deadlineSchema.index({ userId: 1, isCompleted: 1, dueDate: 1 });
deadlineSchema.index({ userId: 1, isOverdue: 1 });

// Full-text search
deadlineSchema.index(
  { title: 'text', description: 'text', source: 'text' },
  { weights: { title: 10, description: 5, source: 3 }, name: 'deadline_text_search' }
);

// Virtual: time remaining in milliseconds
deadlineSchema.virtual('timeRemaining').get(function () {
  return this.dueDate - new Date();
});

// Pre-save: auto-detect overdue
deadlineSchema.pre('save', function (next) {
  if (!this.isCompleted && this.dueDate < new Date()) {
    this.isOverdue = true;
  }
  if (this.isCompleted && !this.completedAt) {
    this.completedAt = new Date();
  }
  next();
});

const Deadline = mongoose.model('Deadline', deadlineSchema);

module.exports = Deadline;
