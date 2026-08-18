const { getGmailClient } = require('../config/gmail');
const { decrypt } = require('./encryptionService');
const { parseGmailMessage } = require('../utils/gmailParser');
const { classifyWithAI } = require('./aiClassificationService');
const { summarizeEmail } = require('../config/gemini');
const notificationService = require('./notificationService');
const Email = require('../models/Email');
const Deadline = require('../models/Deadline');
const User = require('../models/User');
const logger = require('../utils/logger');
const { EMAIL_PRIORITIES } = require('../config/constants');

/**
 * Fetches and syncs new emails for a single user.
 * Uses historyId for incremental sync when available, else fetches recent messages.
 * @param {Object} user - Mongoose User document
 */
const syncUserEmails = async (user) => {
  if (!user.googleRefreshToken) {
    if (user.email === 'student@university.edu' || user.email === 'demo@mailguard.dev') {
      logger.info(`User ${user._id} demo sync triggered – adding new incoming email`);
      const now = new Date();
      const newMsgId = `msg_sync_${Date.now()}`;
      const newEmail = new Email({
        userId: user._id,
        gmailId: newMsgId,
        sender: 'Amazon Campus Recruiting <campus-hiring@amazon.com>',
        senderEmail: 'campus-hiring@amazon.com',
        subject: '[URGENT] Amazon SDE Internship 2026 - Online Assessment Round 1 Link',
        snippet: 'Your Online Assessment link for Amazon SDE Internship is now live. Complete test within 48 hours.',
        body: 'Dear Applicant,\n\nYour profile has been shortlisted for the Amazon SDE Internship 2026 Online Assessment.\n\nTest Platform: Mettl / HackerRank\nDuration: 90 Minutes\nTopics: Data Structures, Algorithms, Work Style Assessment\nExpiry: 48 Hours from receipt.\n\nPlease log in to the portal and start your assessment.',
        category: 'Placement',
        priority: 'High',
        deadline: new Date(now.getTime() + 48 * 60 * 60 * 1000),
        deadlineDescription: 'Amazon SDE Test Link Expiry',
        aiConfidence: 0.99,
        aiReasoning: 'HIGH URGENCY: Contains terms "Amazon SDE Internship", "Online Assessment", and "48 Hours Expiry".',
        isRead: false,
        isApplied: true,
        receivedAt: now,
      });
      await newEmail.save();
      return { synced: 1, errors: 0 };
    } else {
      logger.warn(`Sync skipped for user ${user._id} (${user.email}) – No Google Refresh Token available.`);
      return { synced: 0, errors: 0 };
    }
  }

  let decryptedToken;
  try {
    decryptedToken = decrypt(user.googleRefreshToken);
  } catch (err) {
    logger.error(`Failed to decrypt token for user ${user._id}:`, err.message);
    return { synced: 0, errors: 1 };
  }

  const gmail = getGmailClient(decryptedToken);
  let messageIds = [];
  let newHistoryId = user.historyId;

  const existingCount = await Email.countDocuments({ userId: user._id });

  try {
    if (user.historyId && existingCount > 0) {
      // Incremental sync using historyId
      const historyRes = await gmail.users.history.list({
        userId: 'me',
        startHistoryId: user.historyId,
        historyTypes: ['messageAdded'],
      });

      const historyData = historyRes.data;
      if (historyData.historyId) {
        newHistoryId = historyData.historyId;
      }

      const history = historyData.history || [];
      for (const record of history) {
        for (const msg of (record.messagesAdded || [])) {
          messageIds.push(msg.message.id);
        }
      }
    } else {
      // Full initial sync – fetch last 50 messages from past 30 days
      const listRes = await gmail.users.messages.list({
        userId: 'me',
        maxResults: parseInt(process.env.GMAIL_MAX_RESULTS, 10) || 50,
        q: 'newer_than:30d',
      });

      const messages = listRes.data.messages || [];
      messageIds = messages.map((m) => m.id);

      // Get historyId for future incremental syncs
      const profileRes = await gmail.users.getProfile({ userId: 'me' });
      newHistoryId = profileRes.data.historyId;
    }
  } catch (error) {
    logger.error(`Gmail API error for user ${user._id}: ${error.message || JSON.stringify(error.errors || error)}`);

    // If historyId is stale, reset and do full sync next time
    if (error.code === 404 || (error.errors && error.errors[0]?.reason === 'invalidHistoryId')) {
      await User.findByIdAndUpdate(user._id, { historyId: null });
      logger.info(`Reset historyId for user ${user._id}`);
    }
    return { synced: 0, errors: 1 };
  }

  let synced = 0;
  let errors = 0;

  // Process messages
  for (const msgId of messageIds) {
    try {
      // Skip if already synced
      const exists = await Email.findOne({ userId: user._id, gmailId: msgId });
      if (exists) continue;

      // Fetch full message
      const msgRes = await gmail.users.messages.get({
        userId: 'me',
        id: msgId,
        format: 'full',
      });

      const parsed = parseGmailMessage(msgRes.data);
      if (!parsed) continue;

      // Extract attachments metadata from payload
      const attachmentMetas = [];
      const parts = msgRes.data.payload?.parts || [];
      for (const part of parts) {
        if (part.filename && part.body?.attachmentId) {
          attachmentMetas.push({
            filename: part.filename,
            mimeType: part.mimeType,
            attachmentId: part.body.attachmentId,
            size: part.body.size || 0,
          });
        }
      }

      // Scan attachments for student shortlist match
      const attachmentService = require('./attachmentService');
      let isShortlisted = false;
      let shortlistMatchTerm = null;

      for (const att of attachmentMetas) {
        const scanRes = await attachmentService.scanAttachmentForShortlist(gmail, msgId, att, user);
        if (scanRes.isShortlisted) {
          isShortlisted = true;
          att.isShortlisted = true;
          shortlistMatchTerm = scanRes.matchedKey;
          break;
        }
      }

      // AI classification & event extraction
      const classification = await classifyWithAI({
        subject: parsed.subject,
        sender: parsed.sender,
        snippet: parsed.snippet,
        body: parsed.body,
      });

      // STRICT SHORTLIST VERIFICATION RULE:
      // Must contain user's Reg No or NeoPAT ID in text or attachment
      const regNo = (user.registrationNumber || process.env.STUDENT_REG_NO || '').toLowerCase().trim();
      const neoId = (user.neoPatId || process.env.STUDENT_NEOPAT_ID || '').toLowerCase().trim();
      const textCheck = `${parsed.subject || ''} ${parsed.snippet || ''} ${parsed.body || ''}`.toLowerCase();
      const textMatched = (regNo.length > 2 && textCheck.includes(regNo)) || (neoId.length > 2 && textCheck.includes(neoId));
      const isUnnecessary = textCheck.includes('nptel') || textCheck.includes('kaggle');

      isShortlisted = (isShortlisted || textMatched) && !isUnnecessary;

      const finalPriority = isShortlisted ? EMAIL_PRIORITIES.HIGH : classification.priority;
      let finalReasoning = classification.reasoning || '';
      if (isShortlisted) {
        finalReasoning = `🔥 VERIFIED SHORTLIST! Matched Reg No / NeoPAT ID! ${finalReasoning}`;
      }

      // Save email to DB
      const email = await Email.create({
        userId: user._id,
        ...parsed,
        category: classification.category,
        priority: finalPriority,
        isShortlisted: isShortlisted,
        attachments: attachmentMetas,
        events: classification.events || [],
        deadline: classification.deadline,
        deadlineDescription: classification.deadlineDescription,
        aiConfidence: classification.confidence,
        aiReasoning: finalReasoning,
      });

      // ─── AUTO-SUMMARIZE using user's custom prompt ─────────────────────
      // Run this async so it doesn't block saving — but we await before notifying
      try {
        const customPrompt = user.customAiPrompt || null;
        const autoSummary = await summarizeEmail(
          { subject: parsed.subject, sender: parsed.sender, snippet: parsed.snippet, body: parsed.body },
          customPrompt
        );
        await Email.findByIdAndUpdate(email._id, { autoSummary });
        email.autoSummary = autoSummary;
      } catch (summaryErr) {
        logger.warn(`Auto-summary failed for email ${email._id}:`, summaryErr.message);
        // Non-fatal: continue without summary
      }
      // ──────────────────────────────────────────────────────────────────

      // Events are preserved on the Email model (email.events & email.deadline).
      // Deadlines are now created explicitly by user action ("Add to Deadlines" button).

      // Send instant push notification for newly synced emails (skip for unnecessary NPTEL/Kaggle senders)
      const senderText = `${parsed.sender || ''} ${parsed.subject || ''}`.toLowerCase();
      const isUnnecessarySender = senderText.includes('nptel') || senderText.includes('kaggle');

      if (!isUnnecessarySender) {
        const emailSummary = autoSummary || parsed.snippet || parsed.subject;
        if (isShortlisted) {
          await notificationService.sendPushNotification({
            userId: user._id,
            emailId: email._id,
            title: `From: ${parsed.sender} 🔥 [SHORTLIST]`,
            body: `Summary: ${emailSummary}`,
            type: NOTIFICATION_TYPES.HIGH_PRIORITY_EMAIL,
            data: { emailId: email._id.toString(), isShortlisted: 'true' },
          });
        } else if (finalPriority === EMAIL_PRIORITIES.HIGH) {
          await notificationService.sendHighPriorityNotification(user, email);
        } else {
          await notificationService.sendPushNotification({
            userId: user._id,
            emailId: email._id,
            title: `From: ${parsed.sender}`,
            body: `Summary: ${emailSummary}`,
            type: NOTIFICATION_TYPES.NEW_EMAIL,
            data: { emailId: email._id.toString(), category: classification.category },
          });
        }
      }

      synced++;
    } catch (err) {
      logger.error(`Error processing message ${msgId} for user ${user._id}:`, err.message);
      errors++;
    }
  }

  // Enforce strict 250 email cap per user (prunes oldest emails beyond 250)
  await enforceEmailCap(user._id, 250);

  // Update historyId and lastSyncAt
  await User.findByIdAndUpdate(user._id, {
    historyId: newHistoryId,
    lastSyncAt: new Date(),
  });

  logger.info(`Sync complete for user ${user._id}: ${synced} synced, ${errors} errors`);
  return { synced, errors };
};

/**
 * Enforces a strict 250 email storage limit for a user.
 * Deletes the oldest excess emails when new emails are added.
 */
const enforceEmailCap = async (userId, maxCap = 250) => {
  try {
    const Email = require('../models/Email');
    const count = await Email.countDocuments({ userId });
    if (count > maxCap) {
      const excessCount = count - maxCap;
      const oldestEmails = await Email.find({ userId })
        .sort({ receivedAt: 1 })
        .limit(excessCount)
        .select('_id');

      const idsToDelete = oldestEmails.map((e) => e._id);
      await Email.deleteMany({ _id: { $in: idsToDelete } });
      logger.info(`Enforced 250 email cap for user ${userId}: pruned ${idsToDelete.length} oldest emails.`);
    }
  } catch (err) {
    logger.error(`Error enforcing email cap for user ${userId}:`, err.message);
  }
};

/**
 * Syncs emails for ALL active users.
 */
const syncAllUsers = async () => {
  const users = await User.find({
    isActive: true,
    googleRefreshToken: { $ne: null },
  }).select('_id googleRefreshToken historyId');

  logger.info(`Starting bulk Gmail sync for ${users.length} users`);
  const results = await Promise.allSettled(users.map((u) => syncUserEmails(u)));

  const succeeded = results.filter((r) => r.status === 'fulfilled').length;
  const failed = results.filter((r) => r.status === 'rejected').length;
  logger.info(`Bulk sync done: ${succeeded} succeeded, ${failed} failed`);

  return { succeeded, failed };
};

module.exports = { syncUserEmails, syncAllUsers };
