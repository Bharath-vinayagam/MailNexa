/**
 * Gmail message parsing utilities.
 * Handles base64url decoding, MIME part extraction, and header parsing.
 */

/**
 * Decodes a base64url encoded string to UTF-8 text.
 */
const decodeBase64 = (data) => {
  if (!data) return '';
  const cleaned = data.replace(/-/g, '+').replace(/_/g, '/');
  return Buffer.from(cleaned, 'base64').toString('utf-8');
};

/**
 * Extracts the value of a specific header from Gmail message headers.
 */
const getHeader = (headers, name) => {
  if (!headers) return '';
  const header = headers.find(
    (h) => h.name.toLowerCase() === name.toLowerCase()
  );
  return header ? header.value : '';
};

/**
 * Recursively extracts text/plain or text/html body from MIME parts.
 */
const extractBody = (payload) => {
  if (!payload) return '';

  // Direct body data
  if (payload.body && payload.body.data) {
    return decodeBase64(payload.body.data);
  }

  // Multipart – prefer text/plain
  if (payload.parts) {
    const plainPart = payload.parts.find((p) => p.mimeType === 'text/plain');
    if (plainPart && plainPart.body && plainPart.body.data) {
      return decodeBase64(plainPart.body.data);
    }

    // Fallback to text/html
    const htmlPart = payload.parts.find((p) => p.mimeType === 'text/html');
    if (htmlPart && htmlPart.body && htmlPart.body.data) {
      const html = decodeBase64(htmlPart.body.data);
      return stripHtml(html);
    }

    // Recursively check nested parts
    for (const part of payload.parts) {
      const body = extractBody(part);
      if (body) return body;
    }
  }

  return '';
};

/**
 * Strips HTML tags from a string for plain text extraction.
 */
const stripHtml = (html) => {
  return html
    .replace(/<style[^>]*>[\s\S]*?<\/style>/gi, '')
    .replace(/<script[^>]*>[\s\S]*?<\/script>/gi, '')
    .replace(/<[^>]+>/g, ' ')
    .replace(/&nbsp;/g, ' ')
    .replace(/&amp;/g, '&')
    .replace(/&lt;/g, '<')
    .replace(/&gt;/g, '>')
    .replace(/&quot;/g, '"')
    .replace(/\s+/g, ' ')
    .trim();
};

/**
 * Extracts sender name and email from "From" header.
 * e.g. "John Doe <john@example.com>" -> { name: "John Doe", email: "john@example.com" }
 */
const parseSender = (fromHeader) => {
  if (!fromHeader) return { name: '', email: '' };

  const match = fromHeader.match(/^(.*?)\s*<(.+)>$/);
  if (match) {
    return {
      name: match[1].trim().replace(/"/g, ''),
      email: match[2].trim().toLowerCase(),
    };
  }

  // Just an email address
  if (fromHeader.includes('@')) {
    return { name: '', email: fromHeader.trim().toLowerCase() };
  }

  return { name: fromHeader.trim(), email: '' };
};

/**
 * Parses a full Gmail message object into a clean email data structure.
 */
const parseGmailMessage = (message) => {
  const { payload } = message;
  if (!payload) return null;

  const headers = payload.headers || [];
  const from = getHeader(headers, 'from');
  const { name: senderName, email: senderEmail } = parseSender(from);

  return {
    gmailId: message.id,
    threadId: message.threadId,
    sender: senderName || senderEmail,
    senderEmail,
    subject: getHeader(headers, 'subject') || '(No Subject)',
    snippet: message.snippet || '',
    body: extractBody(payload),
    labels: message.labelIds || [],
    receivedAt: new Date(parseInt(message.internalDate, 10)),
    isRead: !(message.labelIds || []).includes('UNREAD'),
  };
};

module.exports = {
  decodeBase64,
  getHeader,
  extractBody,
  stripHtml,
  parseSender,
  parseGmailMessage,
};
