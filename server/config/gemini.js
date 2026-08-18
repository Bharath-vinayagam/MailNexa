const axios = require('axios');
const logger = require('../utils/logger');

const GEMINI_BASE_URL = 'https://generativelanguage.googleapis.com/v1beta/models';

/**
 * Calls the Gemini API with the given prompt.
 * @param {string} prompt
 * @returns {Promise<string>} The text response from Gemini
 */
const callGemini = async (prompt, retries = 3) => {
  const model = process.env.GEMINI_MODEL || 'gemini-3.5-flash-lite';
  const apiKey = process.env.GEMINI_API_KEY;

  if (!apiKey) {
    throw new Error('GEMINI_API_KEY is not configured');
  }

  const url = `${GEMINI_BASE_URL}/${model}:generateContent?key=${apiKey}`;

  const payload = {
    contents: [
      {
        parts: [{ text: prompt }],
      },
    ],
    generationConfig: {
      temperature: 0.1,
      topK: 1,
      topP: 0.8,
      maxOutputTokens: 512,
    },
    safetySettings: [
      { category: 'HARM_CATEGORY_HARASSMENT', threshold: 'BLOCK_ONLY_HIGH' },
      { category: 'HARM_CATEGORY_HATE_SPEECH', threshold: 'BLOCK_ONLY_HIGH' },
      { category: 'HARM_CATEGORY_SEXUALLY_EXPLICIT', threshold: 'BLOCK_ONLY_HIGH' },
      { category: 'HARM_CATEGORY_DANGEROUS_CONTENT', threshold: 'BLOCK_ONLY_HIGH' },
    ],
  };

  for (let attempt = 1; attempt <= retries; attempt++) {
    try {
      const response = await axios.post(url, payload, {
        headers: { 'Content-Type': 'application/json' },
        timeout: 20000,
      });

      const candidates = response.data?.candidates;
      if (!candidates || candidates.length === 0) {
        throw new Error('Gemini returned no candidates');
      }

      const text = candidates[0]?.content?.parts?.[0]?.text;
      if (!text) {
        throw new Error('Gemini returned empty text');
      }

      return text.trim();
    } catch (err) {
      const status = err.response?.status;
      if ((status === 429 || status === 503) && attempt < retries) {
        logger.warn(`Gemini rate limited (status ${status}). Retrying attempt ${attempt}/${retries} in ${attempt * 4}s...`);
        await new Promise((r) => setTimeout(r, attempt * 4000));
        continue;
      }
      throw err;
    }
  }
};

/**
 * Classifies an email using Gemini.
 * @param {Object} emailData - { subject, sender, snippet, body }
 * @returns {Promise<Object>} { category, priority, deadline, confidence }
 */
const classifyEmail = async (emailData) => {
  const { subject = '', sender = '', snippet = '', body = '' } = emailData;

  const truncatedBody = body.length > 2000 ? body.substring(0, 2000) + '...' : body;

  const prompt = `You are an AI assistant for a student's campus placement & academic system. Analyze the following email and respond ONLY with valid JSON.

Email Details:
- Sender: ${sender}
- Subject: ${subject}
- Preview: ${snippet}
- Body: ${truncatedBody}

Classify this email and respond with this exact JSON format (no markdown, no code block backticks):
{
  "category": "<one of: Placement, Academic, Personal, Promotions, Others>",
  "priority": "<one of: High, Medium, Low>",
  "deadline": "<ISO 8601 date string if a deadline is mentioned, otherwise null>",
  "deadlineDescription": "<brief description of the deadline if found, otherwise null>",
  "isShortlisted": <true ONLY if text explicitly states that the recipient student is shortlisted/selected for next round. Set false if email merely mentions an attached list or general shortlist announcement>,
  "events": [
    {
      "title": "<event title e.g. Pre-Placement Talk, Technical Test, Interview>",
      "date": "<ISO 8601 date string>",
      "type": "<one of: PPT, TEST, INTERVIEW, DEADLINE>"
    }
  ],
  "confidence": <number between 0.0 and 1.0>,
  "reasoning": "<concise 2-sentence summary of the email and mandatory next steps>"
}

Rules:
- Placement: job offers, interviews, shortlists, internships, coding tests, campus drives, PPTs
- High priority: shortlists, interview invites, coding tests, offer letters, urgent deadlines (<48h)
- Medium priority: registrations, upcoming drives, general academic updates
- Low priority: newsletters, promotions, informational emails`;

  const responseText = await callGemini(prompt);

  // Extract JSON from response
  const jsonMatch = responseText.match(/\{[\s\S]*\}/);
  if (!jsonMatch) {
    throw new Error('Gemini response did not contain valid JSON');
  }

  const parsed = JSON.parse(jsonMatch[0]);

  // Normalize events — filter out entries without a valid date
  const rawEvents = Array.isArray(parsed.events) ? parsed.events : [];
  const events = rawEvents
    .filter((ev) => ev && ev.date && !isNaN(new Date(ev.date)))
    .map((ev) => ({
      title: ev.title || 'Event',
      date: new Date(ev.date),
      type: ev.type || 'DEADLINE',
    }));

  return {
    category: parsed.category || 'Others',
    priority: parsed.priority || 'Low',
    isShortlisted: parsed.isShortlisted === true,
    events,
    deadline: parsed.deadline ? new Date(parsed.deadline) : null,
    deadlineDescription: parsed.deadlineDescription || null,
    confidence: typeof parsed.confidence === 'number' ? parsed.confidence : 0.5,
    reasoning: parsed.reasoning || '',
  };
};

/**
 * Custom prompt summarization for a specific email.
 */
const summarizeEmail = async (emailData, customPrompt) => {
  const { subject = '', sender = '', snippet = '', body = '' } = emailData;
  const truncatedBody = body.length > 3500 ? body.substring(0, 3500) + '...' : body;

  const userInstruction = (customPrompt && customPrompt.trim().length > 3)
      ? customPrompt.trim()
      : 'Summarize clearly and professionally.';

  const prompt = `You are a professional executive email assistant for a university student.
Summarize the following email based on this instruction: "${userInstruction}".

Email Details:
- Sender: ${sender}
- Subject: ${subject}
- Content: ${truncatedBody}

Formatting Rules:
- Strictly output 3 to 4 clean, formal bullet points starting with standard bullet points (• ).
- DO NOT use markdown bolding syntax like ** or __ anywhere in the text.
- DO NOT use emojis or informal symbols.
- Keep the language elegant, classic, executive, and direct.
- Point 1: Nature / category of notice.
- Point 2: Core topic or company update.
- Point 3: Shortlist / test link / eligibility details.
- Point 4: Action items, location, and deadlines.`;

  const responseText = await callGemini(prompt);
  return responseText;
};

module.exports = { callGemini, classifyEmail, summarizeEmail };
