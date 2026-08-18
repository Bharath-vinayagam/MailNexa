const { classifyEmail } = require('../config/gemini');
const { CATEGORY_KEYWORDS, PRIORITY_KEYWORDS, EMAIL_CATEGORIES, EMAIL_PRIORITIES } = require('../config/constants');
const logger = require('../utils/logger');

/**
 * Keyword-based fallback classifier (used when Gemini is unavailable).
 * @param {{ subject: string, sender: string, snippet: string, body: string }} emailData
 * @returns {{ category, priority, deadline, confidence }}
 */
const fallbackClassify = (emailData) => {
  const text = `${emailData.subject} ${emailData.sender} ${emailData.snippet} ${emailData.body}`.toLowerCase();

  // Determine category by keyword matching
  let bestCategory = EMAIL_CATEGORIES.OTHERS;
  let bestCategoryScore = 0;

  for (const [category, keywords] of Object.entries(CATEGORY_KEYWORDS)) {
    const score = keywords.reduce((acc, kw) => {
      return acc + (text.includes(kw.toLowerCase()) ? 1 : 0);
    }, 0);
    if (score > bestCategoryScore) {
      bestCategoryScore = score;
      bestCategory = category;
    }
  }

  // Determine priority by keyword matching
  let priority = EMAIL_PRIORITIES.LOW;
  for (const kw of PRIORITY_KEYWORDS.HIGH) {
    if (text.includes(kw.toLowerCase())) {
      priority = EMAIL_PRIORITIES.HIGH;
      break;
    }
  }
  if (priority === EMAIL_PRIORITIES.LOW) {
    for (const kw of PRIORITY_KEYWORDS.MEDIUM) {
      if (text.includes(kw.toLowerCase())) {
        priority = EMAIL_PRIORITIES.MEDIUM;
        break;
      }
    }
  }

  return {
    category: bestCategory,
    priority,
    isShortlisted: false,
    events: [],
    deadline: null,
    deadlineDescription: null,
    confidence: 0.4,
    reasoning: 'Keyword-based fallback classification',
  };
};

/**
 * Classifies an email with Gemini AI, with keyword fallback.
 * @param {Object} emailData - { subject, sender, snippet, body }
 * @returns {Promise<Object>} Classification result
 */
const classifyWithAI = async (emailData) => {
  // ─── Filter out unnecessary senders (NPTEL, Kaggle) ─────────────────
  const textCheck = `${emailData.sender || ''} ${emailData.subject || ''}`.toLowerCase();
  if (textCheck.includes('nptel') || textCheck.includes('kaggle')) {
    return {
      category: EMAIL_CATEGORIES.PROMOTIONS,
      priority: EMAIL_PRIORITIES.LOW,
      isShortlisted: false,
      events: [],
      deadline: null,
      deadlineDescription: null,
      confidence: 1.0,
      reasoning: 'Unnecessary promotional email from NPTEL/Kaggle',
    };
  }

  try {
    if (!process.env.GEMINI_API_KEY) {
      logger.warn('Gemini API key not set – using keyword fallback');
      return fallbackClassify(emailData);
    }

    const timeout = new Promise((_, reject) =>
      setTimeout(() => reject(new Error('AI classification timeout')), 12000)
    );

    const result = await Promise.race([classifyEmail(emailData), timeout]);
    return result;
  } catch (error) {
    logger.warn('AI classification fallback activated:', error.message);
    return fallbackClassify(emailData);
  }
};

/**
 * Processes a manual override from the user.
 * Updates the email's category/priority and marks it as manually overridden.
 */
const processManualOverride = async (email, { category, priority }) => {
  const Email = require('../models/Email');

  const update = { manualOverride: true };
  if (category) update.category = category;
  if (priority) update.priority = priority;

  const updated = await Email.findByIdAndUpdate(
    email._id,
    { $set: update },
    { new: true, runValidators: true }
  );

  return updated;
};

module.exports = { classifyWithAI, fallbackClassify, processManualOverride };
