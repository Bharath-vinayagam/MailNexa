const xlsx = require('xlsx');
const pdfParse = require('pdf-parse');
const logger = require('../utils/logger');

/**
 * Downloads and parses email attachments (Excel, CSV, PDF, Text) to check
 * if the user's registration number, name, or NeoPAT ID is in the shortlist.
 */
class AttachmentService {
  /**
   * Scans an attachment for user shortlist matches.
   * @param {Object} gmail - Authenticated Google Gmail API client
   * @param {string} messageId - Gmail message ID
   * @param {Object} attachmentMeta - { attachmentId, filename, mimeType }
   * @param {Object} user - User document containing { registrationNumber, name, neoPatId }
   * @returns {Promise<{ isShortlisted: boolean, matchedKey: string|null }>}
   */
  async scanAttachmentForShortlist(gmail, messageId, attachmentMeta, user) {
    try {
      if (!attachmentMeta.attachmentId) {
        return { isShortlisted: false, matchedKey: null };
      }

      // Build target search patterns — STRICTLY Student Reg No & NeoPAT ID
      const searchTerms = [];
      const regNo = (user.registrationNumber || process.env.STUDENT_REG_NO || '').trim();
      const neoId = (user.neoPatId || process.env.STUDENT_NEOPAT_ID || '').trim();

      if (regNo.length > 2) {
        searchTerms.push({ key: regNo, value: regNo.toLowerCase() });
      }
      if (neoId.length > 2) {
        searchTerms.push({ key: neoId, value: neoId.toLowerCase() });
      }

      if (searchTerms.length === 0) {
        return { isShortlisted: false, matchedKey: null };
      }

      // Fetch attachment buffer from Gmail API
      const res = await gmail.users.messages.attachments.get({
        userId: 'me',
        messageId: messageId,
        id: attachmentMeta.attachmentId,
      });

      if (!res.data || !res.data.data) {
        return { isShortlisted: false, matchedKey: null };
      }

      // Decode base64url buffer
      const base64Data = res.data.data.replace(/-/g, '+').replace(/_/g, '/');
      const buffer = Buffer.from(base64Data, 'base64');
      const fileNameLower = (attachmentMeta.filename || '').toLowerCase();

      // ─── Excel / CSV Files ────────────────────────────
      if (fileNameLower.endsWith('.xlsx') || fileNameLower.endsWith('.xls') || fileNameLower.endsWith('.csv') || attachmentMeta.mimeType?.includes('spreadsheet') || attachmentMeta.mimeType?.includes('csv')) {
        const workbook = xlsx.read(buffer, { type: 'buffer' });
        for (const sheetName of workbook.SheetNames) {
          const sheet = workbook.Sheets[sheetName];
          const csvText = xlsx.utils.sheet_to_csv(sheet).toLowerCase();

          for (const term of searchTerms) {
            if (csvText.includes(term.value)) {
              logger.info(`🔥 Shortlist match found in attachment "${attachmentMeta.filename}" for user ${user.email}: term=${term.key}`);
              return { isShortlisted: true, matchedKey: term.key };
            }
          }
        }
      }

      // ─── PDF Files ────────────────────────────────────
      if (fileNameLower.endsWith('.pdf') || attachmentMeta.mimeType?.includes('pdf')) {
        const pdfData = await pdfParse(buffer);
        const textLower = (pdfData.text || '').toLowerCase();
        for (const term of searchTerms) {
          if (textLower.includes(term.value)) {
            logger.info(`🔥 Shortlist match found in PDF attachment "${attachmentMeta.filename}" for user ${user.email}: term=${term.key}`);
            return { isShortlisted: true, matchedKey: term.key };
          }
        }
      }

      // ─── Text / Plain Files ───────────────────────────
      if (fileNameLower.endsWith('.txt') || fileNameLower.endsWith('.log') || attachmentMeta.mimeType?.includes('text')) {
        const textLower = buffer.toString('utf8').toLowerCase();
        for (const term of searchTerms) {
          if (textLower.includes(term.value)) {
            logger.info(`🔥 Shortlist match found in Text attachment "${attachmentMeta.filename}" for user ${user.email}: term=${term.key}`);
            return { isShortlisted: true, matchedKey: term.key };
          }
        }
      }

      return { isShortlisted: false, matchedKey: null };
    } catch (error) {
      logger.warn(`Failed to scan attachment ${attachmentMeta.filename}:`, error.message);
      return { isShortlisted: false, matchedKey: null };
    }
  }
}

module.exports = new AttachmentService();
