const mongoose = require('mongoose');
const Email = require('../models/Email');
const User = require('../models/User');
const { getPaginationParams, buildPaginationMeta } = require('../utils/pagination');

/**
 * Default sample emails with AI summaries and term-based prioritization
 */
const getDefaultSampleEmails = (userId) => {
  const now = new Date();
  return [
    {
      userId,
      gmailId: 'msg_placement_google_01',
      sender: 'Google University Hiring <placements@google.com>',
      senderEmail: 'placements@google.com',
      subject: '[ACTION REQUIRED] Google Software Engineering Drive 2026 - OA Link & Slot Selection',
      snippet: 'Selected candidates must complete the Online Assessment (OA) before tomorrow midnight. Click link to select test slot.',
      body: 'Dear Candidate,\n\nCongratulations on passing the resume screening for Google Software Engineering Drive 2026.\n\nKey Details:\n- Test Type: Online Assessment (Data Structures & Algorithms)\n- Platform: HackerRank\n- Deadline: Tomorrow, 11:59 PM IST\n- Duration: 90 Minutes\n\nPlease ensure stable internet connectivity and a working webcam. Slots are assigned first-come-first-served.',
      category: 'Placement',
      priority: 'High',
      deadline: new Date(now.getTime() + 24 * 60 * 60 * 1000),
      deadlineDescription: 'Google OA Test Link Expiry',
      aiConfidence: 0.98,
      aiReasoning: 'HIGH URGENCY: Contains terms "Google", "Online Assessment", and "Deadline Tomorrow". Immediate action needed to attempt test slot selection.',
      isRead: false,
      isApplied: true,
      receivedAt: new Date(now.getTime() - 2 * 60 * 60 * 1000),
    },
    {
      userId,
      gmailId: 'msg_placement_deloitte_02',
      sender: 'Campus Placement Cell <placements@university.edu>',
      senderEmail: 'placements@university.edu',
      subject: 'Deloitte Analyst Role - Interview Shortlist & Schedule Announced',
      snippet: 'The following students have been shortlisted for Deloitte round 2 technical interviews tomorrow at 10:00 AM.',
      body: 'Attention Placement Aspirants,\n\nDeloitte USI has released the shortlist for Round 2 Technical Interviews.\n\nSchedule:\n- Venue: Main Placement Auditorium, Block B\n- Reporting Time: 9:30 AM sharp\n- Dress Code: Business Formals\n\nCarry 3 printed copies of your resume, college ID card, and academic transcripts.',
      category: 'Placement',
      priority: 'High',
      deadline: new Date(now.getTime() + 18 * 60 * 60 * 1000),
      deadlineDescription: 'Deloitte Interview Reporting Time',
      aiConfidence: 0.96,
      aiReasoning: 'HIGH PRIORITY: Placement interview shortlist notification for Deloitte with venue and reporting schedule.',
      isRead: false,
      isApplied: true,
      receivedAt: new Date(now.getTime() - 5 * 60 * 60 * 1000),
    },
    {
      userId,
      gmailId: 'msg_academic_proj_03',
      sender: 'Prof. Sharma (HOD CS) <sharma.cs@university.edu>',
      senderEmail: 'sharma.cs@university.edu',
      subject: 'FINAL DEADLINE: Capstone Project Mid-Term Evaluation & Report Submission',
      snippet: 'All final year CS students must upload their capstone project mid-term report and Github repository link on portal.',
      body: 'Dear Students,\n\nThis is a final reminder that the Capstone Project Mid-Term evaluation portals will close on Friday.\n\nSubmission Checklist:\n1. 15-page PDF Project Progress Report\n2. Public/Private Github Repository URL\n3. Architecture Diagram & Database Schema\n\nLate submissions will incur a 20% mark penalty per day.',
      category: 'Academic',
      priority: 'High',
      deadline: new Date(now.getTime() + 48 * 60 * 60 * 1000),
      deadlineDescription: 'Capstone Project Report Submission',
      aiConfidence: 0.94,
      aiReasoning: 'HIGH PRIORITY: Academic deadline for Capstone Project evaluation report with grading penalty clause.',
      isRead: true,
      isApplied: false,
      receivedAt: new Date(now.getTime() - 12 * 60 * 60 * 1000),
    },
    {
      userId,
      gmailId: 'msg_placement_stripe_04',
      sender: 'Stripe Careers <recruiting@stripe.com>',
      senderEmail: 'recruiting@stripe.com',
      subject: 'Stripe Early Career Software Engineer - Application Received & Next Steps',
      snippet: 'Thank you for applying to Stripe. We have received your application and will review your profile shortly.',
      body: 'Hi Bharath,\n\nThanks for applying to Stripe for the Early Career Software Engineer position.\n\nOur university recruiting team is currently reviewing your resume and project portfolio. We will follow up within 5 business days with feedback or next steps for the technical interview screen.',
      category: 'Placement',
      priority: 'Medium',
      deadline: new Date(now.getTime() + 5 * 24 * 60 * 60 * 1000),
      deadlineDescription: 'Stripe Application Review Window',
      aiConfidence: 0.91,
      aiReasoning: 'MEDIUM PRIORITY: Job application acknowledgment from Stripe with expected 5-day review timeline.',
      isRead: true,
      isApplied: true,
      receivedAt: new Date(now.getTime() - 24 * 60 * 60 * 1000),
    },
    {
      userId,
      gmailId: 'msg_academic_exam_05',
      sender: 'Examination Branch <controller.exams@university.edu>',
      senderEmail: 'controller.exams@university.edu',
      subject: 'Semester End Examination Time Table & Admit Card Download',
      snippet: 'Semester VI final examination schedule has been published. Download your hall ticket from the student portal.',
      body: 'Dear Students,\n\nThe End Semester Examination timetable for Semester VI is now published on the university portal.\n\nImportant Instructions:\n- Exams commence from 15th of next month\n- Download and print your digital Hall Ticket before 10th\n- No student will be admitted to the hall without a printed hall ticket and valid college ID card.',
      category: 'Academic',
      priority: 'Medium',
      deadline: new Date(now.getTime() + 7 * 24 * 60 * 60 * 1000),
      deadlineDescription: 'Admit Card Download Cutoff',
      aiConfidence: 0.93,
      aiReasoning: 'MEDIUM PRIORITY: Academic examination timetable release & hall ticket download instructions.',
      isRead: false,
      isApplied: false,
      receivedAt: new Date(now.getTime() - 36 * 60 * 60 * 1000),
    },
    {
      userId,
      gmailId: 'msg_admin_fee_06',
      sender: 'Accounts Department <bursar@university.edu>',
      senderEmail: 'bursar@university.edu',
      subject: 'Notice: Tuition Fee & Placement Registration Fee Payment Window Open',
      snippet: 'Final fee installment & placement registration fee portal is open. Please pay before the due date to avoid fine.',
      body: 'Dear Student,\n\nThis is to notify that the online payment portal for Final Semester Tuition Fee and Training & Placement Registration Fee is open.\n\nDue Date: 28th of this month\nPenalty for late payment: Rs. 500 per week.',
      category: 'Others',
      priority: 'Medium',
      deadline: new Date(now.getTime() + 10 * 24 * 60 * 60 * 1000),
      deadlineDescription: 'Tuition & Placement Fee Due Date',
      aiConfidence: 0.89,
      aiReasoning: 'MEDIUM PRIORITY: Administrative fee payment notice with late fee penalty cutoff.',
      isRead: true,
      isApplied: false,
      receivedAt: new Date(now.getTime() - 48 * 60 * 60 * 1000),
    },
    {
      userId,
      gmailId: 'msg_placement_microsoft_07',
      sender: 'Microsoft University Recruitment <ms.recruiting@microsoft.com>',
      senderEmail: 'ms.recruiting@microsoft.com',
      subject: 'Microsoft Engage 2026 Mentorship Program Registration Open',
      snippet: 'Register for Microsoft Engage 2026 mentorship and summer internship coding challenge.',
      body: 'Hello Aspirant,\n\nMicrosoft Engage 2026 mentorship program is now open for applications!\n\nProgram Highlights:\n- 1-on-1 mentorship from senior Microsoft engineers\n- Fast-track interview opportunity for Summer 2026 Internship\n- Hands-on machine learning & cloud project track\n\nApply before the registration link closes.',
      category: 'Placement',
      priority: 'Medium',
      deadline: new Date(now.getTime() + 3 * 24 * 60 * 60 * 1000),
      deadlineDescription: 'Microsoft Engage Registration Link',
      aiConfidence: 0.92,
      aiReasoning: 'MEDIUM PRIORITY: Placement mentorship & internship opportunity from Microsoft.',
      isRead: true,
      isApplied: false,
      receivedAt: new Date(now.getTime() - 72 * 60 * 60 * 1000),
    },
    {
      userId,
      gmailId: 'msg_academic_lib_08',
      sender: 'Central Library <library@university.edu>',
      senderEmail: 'library@university.edu',
      subject: 'Library Book Overdue Reminder - AI & Distributed Systems Textbooks',
      snippet: 'Please return or renew your borrowed textbooks before Friday to avoid daily overdue library fine.',
      body: 'Dear Reader,\n\nAccording to library records, the following books borrowed on your account are due:\n1. Designing Data-Intensive Applications (Martin Kleppmann)\n2. Artificial Intelligence: A Modern Approach (Russell & Norvig)\n\nPlease return or renew online.',
      category: 'Academic',
      priority: 'Low',
      deadline: new Date(now.getTime() + 4 * 24 * 60 * 60 * 1000),
      deadlineDescription: 'Library Book Return Date',
      aiConfidence: 0.88,
      aiReasoning: 'LOW PRIORITY: Routine library book renewal notification.',
      isRead: true,
      isApplied: false,
      receivedAt: new Date(now.getTime() - 96 * 60 * 60 * 1000),
    },
  ];
};

/**
 * Fetches paginated emails for a user with optional filters.
 */
const getEmails = async (userId, query) => {
  const { page, limit, skip } = getPaginationParams(query);
  let uid;
  try {
    uid = new mongoose.Types.ObjectId(userId.toString());
  } catch (e) {
    uid = userId;
  }
  const filter = { userId: uid };

  // Case-insensitive flexible query matching
  if (query.category) {
    filter.category = { $regex: new RegExp(`^${query.category}$`, 'i') };
  }
  if (query.priority) {
    filter.priority = { $regex: new RegExp(`^${query.priority}$`, 'i') };
  }
  if (query.isRead !== undefined) filter.isRead = query.isRead === 'true';
  if (query.isApplied !== undefined) filter.isApplied = query.isApplied === 'true';
  if (query.isShortlisted !== undefined) filter.isShortlisted = query.isShortlisted === 'true';

  // Date range filter
  if (query.startDate || query.endDate) {
    filter.receivedAt = {};
    if (query.startDate) filter.receivedAt.$gte = new Date(query.startDate);
    if (query.endDate) filter.receivedAt.$lte = new Date(query.endDate);
  }

  // Sort
  const sortField = query.sortBy || 'receivedAt';
  const sortOrder = query.sortOrder === 'asc' ? 1 : -1;
  const sort = { [sortField]: sortOrder };

  let count = await Email.countDocuments({ userId });
  if (count === 0) {
    const userObj = await User.findById(userId);
    if (userObj && (userObj.email === 'student@university.edu' || userObj.email === 'demo@mailguard.dev')) {
      const samples = getDefaultSampleEmails(userId);
      await Email.insertMany(samples);
    } else if (userObj && userObj.googleRefreshToken) {
      const { syncUserEmails } = require('./gmailSyncService');
      await syncUserEmails(userObj).catch(err => console.error('Background sync on fetch error:', err));
    }
  }

  const [emails, total] = await Promise.all([
    Email.find(filter).sort(sort).skip(skip).limit(limit).lean(),
    Email.countDocuments(filter),
  ]);

  return { emails, pagination: buildPaginationMeta(total, page, limit) };
};

/**
 * Gets a single email by ID.
 */
const getEmailById = async (emailId, userId) => {
  const email = await Email.findOne({ _id: emailId, userId });
  if (!email) throw new Error('Email not found');
  return email;
};

/**
 * Marks an email as applied (triggers application creation).
 */
const markEmailAsApplied = async (emailId, userId) => {
  const email = await Email.findOneAndUpdate(
    { _id: emailId, userId },
    { $set: { isApplied: true } },
    { new: true }
  );
  if (!email) throw new Error('Email not found');
  return email;
};

/**
 * Changes the category/priority of an email (manual override).
 */
const changeCategory = async (emailId, userId, { category, priority }) => {
  const update = { manualOverride: true };
  if (category) update.category = category;
  if (priority) update.priority = priority;

  const email = await Email.findOneAndUpdate(
    { _id: emailId, userId },
    { $set: update },
    { new: true }
  );
  if (!email) throw new Error('Email not found');
  return email;
};

module.exports = {
  getEmails,
  getEmailById,
  markEmailAsApplied,
  changeCategory,
};
