require('dotenv').config();
const mongoose = require('mongoose');
const User = require('../../models/User');
const Email = require('../../models/Email');
const Application = require('../../models/Application');
const Deadline = require('../../models/Deadline');
const Notification = require('../../models/Notification');
const Category = require('../../models/Category');
const { encrypt } = require('../../services/encryptionService');
const logger = require('../../utils/logger');

const MONGO_URI = process.env.MONGODB_URI || 'mongodb://localhost:27017/mailguard';

const categories = [
  { name: 'Placement', description: 'Job offers, internships, campus drives', color: '#005cbb', icon: 'briefcase', order: 1 },
  { name: 'Academic', description: 'Exams, assignments, university emails', color: '#374859', icon: 'school', order: 2 },
  { name: 'Personal', description: 'Personal and financial emails', color: '#4f6071', icon: 'person', order: 3 },
  { name: 'Promotions', description: 'Marketing and newsletter emails', color: '#805600', icon: 'local_offer', order: 4 },
  { name: 'Others', description: 'Uncategorized emails', color: '#727784', icon: 'more_horiz', order: 5 },
];

const seedDatabase = async () => {
  try {
    await mongoose.connect(MONGO_URI);
    logger.info('Connected to MongoDB for seeding');

    // Clear existing data
    await Promise.all([
      User.deleteMany({}),
      Email.deleteMany({}),
      Application.deleteMany({}),
      Deadline.deleteMany({}),
      Notification.deleteMany({}),
      Category.deleteMany({}),
    ]);
    logger.info('Cleared existing data');

    // Seed categories
    await Category.insertMany(categories);
    logger.info('Seeded categories');

    // Create admin user
    const admin = await User.create({
      googleId: 'admin_google_id_seed',
      name: 'Admin User',
      email: 'admin@mailguard.dev',
      role: 'admin',
      picture: null,
      googleRefreshToken: null,
      isActive: true,
    });

    // Create student user
    const student = await User.create({
      googleId: 'student_google_id_seed',
      name: 'Jordan Smith',
      email: 'jordan.smith@university.edu',
      role: 'user',
      picture: null,
      googleRefreshToken: null,
      isActive: true,
    });

    logger.info(`Created users: admin=${admin._id}, student=${student._id}`);

    // Seed emails
    const emails = await Email.insertMany([
      {
        userId: student._id,
        gmailId: 'gmail_seed_001',
        threadId: 'thread_001',
        sender: 'Career Services – TechCorp',
        senderEmail: 'careers@techcorp.com',
        subject: 'Interview Invitation: Software Engineer Intern',
        snippet: 'Dear Student, We are pleased to invite you for a technical interview following your impressive application...',
        body: 'Dear Student, We are pleased to invite you for a technical interview following your impressive application to the Software Engineer Intern position. The interview is scheduled for next Tuesday at 10:00 AM IST via Google Meet.',
        category: 'Placement',
        priority: 'High',
        deadline: new Date(Date.now() + 2 * 24 * 60 * 60 * 1000),
        deadlineDescription: 'Interview scheduled for next Tuesday',
        isRead: false,
        isApplied: false,
        aiConfidence: 0.95,
        receivedAt: new Date(Date.now() - 2 * 60 * 60 * 1000),
      },
      {
        userId: student._id,
        gmailId: 'gmail_seed_002',
        threadId: 'thread_002',
        sender: 'Dr. Helena Vance',
        senderEmail: 'h.vance@university.edu',
        subject: 'Thesis Proposal Feedback: Urgent Review Required',
        snippet: 'I have reviewed your initial draft for the neural networks research. While the methodology is...',
        body: 'I have reviewed your initial draft for the neural networks research. While the methodology is sound, there are critical revisions needed in Section 3. Please submit the revised version by Oct 31.',
        category: 'Academic',
        priority: 'High',
        deadline: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000),
        deadlineDescription: 'Revised thesis due Oct 31',
        isRead: false,
        isApplied: false,
        aiConfidence: 0.88,
        receivedAt: new Date(Date.now() - 24 * 60 * 60 * 1000),
      },
      {
        userId: student._id,
        gmailId: 'gmail_seed_003',
        threadId: 'thread_003',
        sender: 'University Registrar',
        senderEmail: 'registrar@university.edu',
        subject: 'Tuition Payment Confirmation for Fall Semester',
        snippet: 'This is an automated confirmation that your payment of $4,500 has been successfully processed...',
        body: 'This is an automated confirmation that your payment of $4,500 has been successfully processed for the Fall 2024 semester. Your student account is now clear.',
        category: 'Personal',
        priority: 'Medium',
        deadline: null,
        isRead: true,
        isApplied: false,
        aiConfidence: 0.91,
        receivedAt: new Date(Date.now() - 3 * 24 * 60 * 60 * 1000),
      },
      {
        userId: student._id,
        gmailId: 'gmail_seed_004',
        threadId: 'thread_004',
        sender: 'Student Union Weekly',
        senderEmail: 'newsletter@studentunion.edu',
        subject: 'Upcoming Campus Events & Workshops',
        snippet: 'Don\'t miss out on this week\'s networking events and the workshop on Effective Time Management...',
        body: 'This week\'s campus highlights: Networking Night on Thursday, Time Management Workshop on Friday, and the Annual Cultural Fest on Saturday.',
        category: 'Promotions',
        priority: 'Low',
        deadline: null,
        isRead: false,
        isApplied: false,
        aiConfidence: 0.82,
        receivedAt: new Date(Date.now() - 4 * 24 * 60 * 60 * 1000),
      },
      {
        userId: student._id,
        gmailId: 'gmail_seed_005',
        threadId: 'thread_005',
        sender: 'Stellar Dynamics HR',
        senderEmail: 'careers@stellardynamics.io',
        subject: 'Update on your Summer 2024 Software Engineering Internship Application',
        snippet: 'Thank you for your interest in the Summer 2024 Software Engineering Internship position at Stellar Dynamics...',
        body: 'Dear Candidate, Thank you for your interest in the Summer 2024 Software Engineering Internship position at Stellar Dynamics. We have reviewed your initial application and are excited to move forward with the next stage – a 90-minute technical assessment. Please complete the assessment before Thursday, Oct 31, 2023 at 11:59 PM PST.',
        category: 'Placement',
        priority: 'High',
        deadline: new Date(Date.now() + 1 * 24 * 60 * 60 * 1000),
        deadlineDescription: 'Technical assessment due Oct 31, 11:59 PM PST',
        isRead: false,
        isApplied: true,
        aiConfidence: 0.97,
        receivedAt: new Date(Date.now() - 5 * 60 * 60 * 1000),
      },
    ]);

    logger.info(`Seeded ${emails.length} emails`);

    // Seed applications
    const applications = await Application.insertMany([
      {
        userId: student._id,
        emailId: emails[0]._id,
        companyName: 'Google',
        role: 'UX Design Intern',
        location: 'Mountain View, CA',
        status: 'Interview',
        statusHistory: [
          { status: 'Applied', changedAt: new Date(Date.now() - 10 * 24 * 60 * 60 * 1000) },
          { status: 'Interview', changedAt: new Date(Date.now() - 2 * 60 * 60 * 1000) },
        ],
        appliedAt: new Date(Date.now() - 10 * 24 * 60 * 60 * 1000),
      },
      {
        userId: student._id,
        emailId: null,
        companyName: 'Google',
        role: 'Product Management Intern',
        location: 'London, UK',
        status: 'Applied',
        statusHistory: [
          { status: 'Applied', changedAt: new Date(Date.now() - 4 * 24 * 60 * 60 * 1000) },
        ],
        appliedAt: new Date(Date.now() - 4 * 24 * 60 * 60 * 1000),
      },
      {
        userId: student._id,
        emailId: null,
        companyName: 'Deloitte',
        role: 'Strategy Consultant',
        location: 'New York, NY',
        status: 'Offer',
        statusHistory: [
          { status: 'Applied', changedAt: new Date(Date.now() - 30 * 24 * 60 * 60 * 1000) },
          { status: 'Interview', changedAt: new Date(Date.now() - 15 * 24 * 60 * 60 * 1000) },
          { status: 'Offer', changedAt: new Date(Date.now() - 24 * 60 * 60 * 1000) },
        ],
        appliedAt: new Date(Date.now() - 30 * 24 * 60 * 60 * 1000),
      },
      {
        userId: student._id,
        emailId: null,
        companyName: 'Stripe',
        role: 'Software Engineer Intern',
        location: 'Remote',
        status: 'Rejected',
        statusHistory: [
          { status: 'Applied', changedAt: new Date(Date.now() - 20 * 24 * 60 * 60 * 1000) },
          { status: 'Rejected', changedAt: new Date(Date.now() - 7 * 24 * 60 * 60 * 1000) },
        ],
        appliedAt: new Date(Date.now() - 20 * 24 * 60 * 60 * 1000),
      },
    ]);

    logger.info(`Seeded ${applications.length} applications`);

    // Seed deadlines
    const deadlines = await Deadline.insertMany([
      {
        userId: student._id,
        emailId: emails[0]._id,
        title: 'TCS NQT Registration',
        description: 'National Qualifier Test registration closes today',
        source: 'TCS NextStep Portal',
        dueDate: new Date(Date.now() + 4 * 60 * 60 * 1000),
        isCompleted: false,
        isOverdue: false,
        category: 'Placement',
      },
      {
        userId: student._id,
        emailId: emails[0]._id,
        title: 'Google STEP Application',
        description: 'Google Student Training in Engineering Program application',
        source: 'Google Careers',
        dueDate: new Date(Date.now() + 12 * 60 * 60 * 1000),
        isCompleted: false,
        isOverdue: false,
        category: 'Placement',
      },
      {
        userId: student._id,
        emailId: null,
        title: 'JP Morgan CFG Hackathon',
        description: 'Code For Good Hackathon submission deadline',
        source: 'HackerRank Confirmation',
        dueDate: new Date(Date.now() + 2 * 24 * 60 * 60 * 1000),
        isCompleted: false,
        isOverdue: false,
        category: 'Placement',
      },
      {
        userId: student._id,
        emailId: null,
        title: 'Amazon SDE Internship',
        description: 'Summer 2024 internship application deadline',
        source: 'Amazon University Jobs',
        dueDate: new Date(Date.now() + 6 * 24 * 60 * 60 * 1000),
        isCompleted: false,
        isOverdue: false,
        category: 'Placement',
      },
      {
        userId: student._id,
        emailId: null,
        title: 'Adobe WIT Scholarship',
        description: 'Women in Technology Scholarship application',
        source: 'Adobe Foundation',
        dueDate: new Date(Date.now() - 3 * 24 * 60 * 60 * 1000),
        isCompleted: true,
        completedAt: new Date(Date.now() - 3 * 24 * 60 * 60 * 1000),
        isOverdue: false,
        category: 'Academic',
      },
    ]);

    logger.info(`Seeded ${deadlines.length} deadlines`);

    logger.info('✅ Database seeding complete!');
    logger.info(`   Admin: ${admin.email}`);
    logger.info(`   Student: ${student.email}`);
    logger.info(`   Emails: ${emails.length}`);
    logger.info(`   Applications: ${applications.length}`);
    logger.info(`   Deadlines: ${deadlines.length}`);

  } catch (error) {
    logger.error('Seeding failed:', error);
    throw error;
  } finally {
    await mongoose.disconnect();
    logger.info('MongoDB disconnected after seeding');
  }
};

seedDatabase();
