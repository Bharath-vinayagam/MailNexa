const Email = require('../models/Email');
const Deadline = require('../models/Deadline');
const Application = require('../models/Application');
const User = require('../models/User');
const { startOfWeek, startOfMonth, startOfToday } = require('../utils/dateUtils');
const mongoose = require('mongoose');

/**
 * Gets comprehensive dashboard statistics for a user.
 */
const getDashboardStats = async (userId) => {
  let uid;
  try {
    uid = new mongoose.Types.ObjectId(userId.toString());
  } catch (e) {
    uid = userId;
  }

  const [
    emailStats,
    todayHighPriorityCount,
    upcomingDeadlineCount,
    overdueDeadlineCount,
    applicationStats,
    recentHighPriorityEmails,
  ] = await Promise.all([
    // Email category breakdown
    Email.aggregate([
      { $match: { userId: uid } },
      { $group: { _id: '$category', count: { $sum: 1 } } },
    ]),

    // Today's high priority emails
    Email.countDocuments({
      userId: uid,
      priority: 'High',
      receivedAt: { $gte: startOfToday() },
    }),

    // Upcoming deadlines (next 7 days)
    Deadline.countDocuments({
      userId: uid,
      isCompleted: false,
      dueDate: { $gte: new Date(), $lte: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000) },
    }),

    // Overdue deadlines
    Deadline.countDocuments({
      userId: uid,
      isCompleted: false,
      isOverdue: true,
    }),

    // Application status breakdown
    Application.aggregate([
      { $match: { userId: uid } },
      { $group: { _id: '$status', count: { $sum: 1 } } },
    ]),

    // 3 most recent high-priority emails for hero card
    Email.find({ userId: uid, priority: 'High' })
      .sort({ receivedAt: -1 })
      .limit(3)
      .select('sender subject snippet receivedAt category')
      .lean(),
  ]);

  // Format category stats
  const categoryStats = {};
  for (const stat of emailStats) {
    categoryStats[stat._id] = stat.count;
  }

  const appStats = { total: 0, applied: 0, interview: 0, offer: 0, rejected: 0 };
  for (const s of applicationStats) {
    const key = s._id.toLowerCase();
    appStats[key] = s.count;
    appStats.total += s.count;
  }

  return {
    emailStats: categoryStats,
    todayHighPriorityCount,
    upcomingDeadlineCount,
    overdueDeadlineCount,
    applicationStats: appStats,
    recentHighPriorityEmails,
  };
};

/**
 * Gets weekly email classification breakdown for the chart.
 */
const getWeeklyStats = async (userId) => {
  let uid;
  try { uid = new mongoose.Types.ObjectId(userId.toString()); } catch (e) { uid = userId; }
  const weekStart = startOfWeek();

  return Email.aggregate([
    {
      $match: {
        userId: uid,
        receivedAt: { $gte: weekStart },
      },
    },
    {
      $group: {
        _id: {
          day: { $dayOfWeek: '$receivedAt' },
          category: '$category',
        },
        count: { $sum: 1 },
      },
    },
    { $sort: { '_id.day': 1 } },
  ]);
};

/**
 * Gets monthly email trend data.
 */
const getMonthlyStats = async (userId) => {
  const uid = mongoose.Types.ObjectId.createFromHexString(userId.toString());
  const monthStart = startOfMonth();

  return Email.aggregate([
    { $match: { userId: uid, receivedAt: { $gte: monthStart } } },
    {
      $group: {
        _id: {
          week: { $week: '$receivedAt' },
          priority: '$priority',
        },
        count: { $sum: 1 },
      },
    },
    { $sort: { '_id.week': 1 } },
  ]);
};

/**
 * Gets admin-level system stats.
 */
const getSystemStats = async () => {
  const [totalUsers, activeUsers, totalEmails, totalDeadlines, totalApplications] = await Promise.all([
    User.countDocuments(),
    User.countDocuments({ isActive: true }),
    Email.countDocuments(),
    Deadline.countDocuments(),
    Application.countDocuments(),
  ]);

  return {
    totalUsers,
    activeUsers,
    totalEmails,
    totalDeadlines,
    totalApplications,
  };
};

module.exports = { getDashboardStats, getWeeklyStats, getMonthlyStats, getSystemStats };
