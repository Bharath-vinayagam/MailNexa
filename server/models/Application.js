const mongoose = require('mongoose');
const { APPLICATION_STATUSES } = require('../config/constants');

const applicationSchema = new mongoose.Schema({
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
  companyName: {
    type: String,
    required: true,
    trim: true,
    maxlength: 200,
    index: true,
  },
  role: {
    type: String,
    required: true,
    trim: true,
    maxlength: 200,
  },
  location: {
    type: String,
    trim: true,
    default: '',
    maxlength: 200,
  },
  status: {
    type: String,
    enum: Object.values(APPLICATION_STATUSES),
    default: APPLICATION_STATUSES.APPLIED,
    index: true,
  },
  notes: {
    type: String,
    default: '',
    maxlength: 2000,
  },
  // Status transition history
  statusHistory: [
    {
      status: {
        type: String,
        enum: Object.values(APPLICATION_STATUSES),
      },
      changedAt: {
        type: Date,
        default: Date.now,
      },
      note: String,
    },
  ],
  appliedAt: {
    type: Date,
    default: Date.now,
  },
}, {
  timestamps: true,
  versionKey: false,
});

// Indexes for company-wise grouping and status filtering
applicationSchema.index({ userId: 1, companyName: 1 });
applicationSchema.index({ userId: 1, status: 1 });
applicationSchema.index({ userId: 1, appliedAt: -1 });

// Full-text search
applicationSchema.index(
  { companyName: 'text', role: 'text', location: 'text', notes: 'text' },
  { weights: { companyName: 10, role: 8, location: 3, notes: 1 }, name: 'application_text_search' }
);

// Pre-save: add status to history if status changes and not duplicate
applicationSchema.pre('save', function (next) {
  if (this.isModified('status') && !this.isNew) {
    const lastHistory = this.statusHistory[this.statusHistory.length - 1];
    if (!lastHistory || lastHistory.status !== this.status) {
      this.statusHistory.push({
        status: this.status,
        changedAt: new Date(),
      });
    }
  }
  next();
});

const Application = mongoose.model('Application', applicationSchema);

module.exports = Application;
