require('dotenv').config();
const connectDB = require('../config/db');
const Email = require('../models/Email');
const { summarizeEmail } = require('../config/gemini');

async function backfillSummaries() {
  try {
    await connectDB();
    const emails = await Email.find({
      $or: [
        { autoSummary: { $exists: false } },
        { autoSummary: '' },
        { autoSummary: null }
      ]
    });

    console.log(`Found ${emails.length} emails needing autoSummary backfill...`);

    const delay = (ms) => new Promise((resolve) => setTimeout(resolve, ms));

    for (let i = 0; i < emails.length; i++) {
      const email = emails[i];
      try {
        console.log(`[${i + 1}/${emails.length}] Summarizing: ${email.subject.substring(0, 40)}...`);
        const summary = await summarizeEmail(email, null);
        await Email.findByIdAndUpdate(email._id, { autoSummary: summary });
        console.log('✓ Summary saved!');
      } catch (e) {
        console.error(`✗ Summary failed for ${email._id}:`, e.message);
      }
      await delay(2000); // 2s delay to comply with Gemini free tier RPM
    }
    console.log('All email summaries backfilled successfully!');
  } catch (err) {
    console.error('Error during backfill:', err);
  } finally {
    process.exit(0);
  }
}

backfillSummaries();
