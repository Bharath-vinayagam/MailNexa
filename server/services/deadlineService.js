const Deadline = require('../models/Deadline');
const { getPaginationParams, buildPaginationMeta } = require('../utils/pagination');
const { startOfToday, endOfToday, daysFromNow } = require('../utils/dateUtils');

/**
 * Creates a new deadline.
 */
const createDeadline = async (userId, data) => {
  const deadline = await Deadline.create({ userId, ...data });
  return deadline;
};

/**
 * Gets paginated deadlines for a user.
 */
const getDeadlines = async (userId, query) => {
  const { page, limit, skip } = getPaginationParams(query);
  const filter = { userId };

  if (query.isCompleted !== undefined) filter.isCompleted = query.isCompleted === 'true';
  if (query.isOverdue !== undefined) filter.isOverdue = query.isOverdue === 'true';
  if (query.category) filter.category = query.category;

  const sortField = query.sortBy || 'dueDate';
  const sortOrder = query.sortOrder === 'desc' ? -1 : 1;

  const [deadlines, total] = await Promise.all([
    Deadline.find(filter)
      .sort({ [sortField]: sortOrder })
      .skip(skip)
      .limit(limit)
      .lean(),
    Deadline.countDocuments(filter),
  ]);

  return { deadlines, pagination: buildPaginationMeta(total, page, limit) };
};

/**
 * Gets today's deadlines.
 */
const getTodayDeadlines = async (userId) => {
  return Deadline.find({
    userId,
    isCompleted: false,
    dueDate: { $gte: startOfToday(), $lte: endOfToday() },
  }).sort({ dueDate: 1 }).lean();
};

/**
 * Gets upcoming deadlines (next N days).
 */
const getUpcomingDeadlines = async (userId, days = 7) => {
  const now = new Date();
  return Deadline.find({
    userId,
    isCompleted: false,
    dueDate: { $gt: endOfToday(), $lte: daysFromNow(days) },
  }).sort({ dueDate: 1 }).limit(10).lean();
};

/**
 * Gets overdue deadlines.
 */
const getOverdueDeadlines = async (userId) => {
  return Deadline.find({
    userId,
    isCompleted: false,
    dueDate: { $lt: new Date() },
  }).sort({ dueDate: 1 }).lean();
};

/**
 * Gets a single deadline by ID.
 */
const getDeadlineById = async (deadlineId, userId) => {
  const deadline = await Deadline.findOne({ _id: deadlineId, userId });
  if (!deadline) throw new Error('Deadline not found');
  return deadline;
};

/**
 * Updates a deadline.
 */
const updateDeadline = async (deadlineId, userId, data) => {
  const deadline = await Deadline.findOneAndUpdate(
    { _id: deadlineId, userId },
    { $set: data },
    { new: true, runValidators: true }
  );
  if (!deadline) throw new Error('Deadline not found');
  return deadline;
};

/**
 * Marks a deadline as completed.
 */
const completeDeadline = async (deadlineId, userId) => {
  const deadline = await Deadline.findOneAndUpdate(
    { _id: deadlineId, userId },
    { $set: { isCompleted: true, isOverdue: false, completedAt: new Date() } },
    { new: true }
  );
  if (!deadline) throw new Error('Deadline not found');
  return deadline;
};

/**
 * Deletes a deadline.
 */
const deleteDeadline = async (deadlineId, userId) => {
  const result = await Deadline.findOneAndDelete({ _id: deadlineId, userId });
  if (!result) throw new Error('Deadline not found');
  return result;
};

/**
 * Bulk marks overdue deadlines (called by scheduled job).
 */
const markOverdueDeadlines = async () => {
  const result = await Deadline.updateMany(
    { isCompleted: false, isOverdue: false, dueDate: { $lt: new Date() } },
    { $set: { isOverdue: true } }
  );
  return result.modifiedCount;
};

module.exports = {
  createDeadline,
  getDeadlines,
  getTodayDeadlines,
  getUpcomingDeadlines,
  getOverdueDeadlines,
  getDeadlineById,
  updateDeadline,
  completeDeadline,
  deleteDeadline,
  markOverdueDeadlines,
};
