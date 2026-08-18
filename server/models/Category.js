const mongoose = require('mongoose');
const { EMAIL_CATEGORIES } = require('../config/constants');

const categorySchema = new mongoose.Schema({
  name: {
    type: String,
    enum: Object.values(EMAIL_CATEGORIES),
    required: true,
    unique: true,
  },
  description: {
    type: String,
    default: '',
  },
  color: {
    type: String,
    default: '#005cbb',
    match: [/^#[0-9A-Fa-f]{6}$/, 'Invalid hex color'],
  },
  icon: {
    type: String,
    default: 'mail',
  },
  isSystem: {
    type: Boolean,
    default: true,
  },
  order: {
    type: Number,
    default: 0,
  },
}, {
  timestamps: true,
  versionKey: false,
});

const Category = mongoose.model('Category', categorySchema);

module.exports = Category;
