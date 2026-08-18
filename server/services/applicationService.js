const Application = require('../models/Application');
const { getPaginationParams, buildPaginationMeta } = require('../utils/pagination');
const { APPLICATION_STATUSES } = require('../config/constants');

/**
 * Creates a new application.
 */
const createApplication = async (userId, data) => {
  const application = await Application.create({
    userId,
    ...data,
    statusHistory: [{ status: data.status || APPLICATION_STATUSES.APPLIED, changedAt: new Date() }],
  });
  return application;
};

/**
 * Gets paginated applications for a user, optionally grouped by company.
 */
const getApplications = async (userId, query) => {
  const { page, limit, skip } = getPaginationParams(query);
  const filter = { userId };

  if (query.status) filter.status = query.status;
  if (query.companyName) filter.companyName = new RegExp(query.companyName, 'i');

  const sortField = query.sortBy || 'appliedAt';
  const sortOrder = query.sortOrder === 'asc' ? 1 : -1;

  const [applications, total] = await Promise.all([
    Application.find(filter)
      .sort({ [sortField]: sortOrder })
      .skip(skip)
      .limit(limit)
      .populate('emailId', 'subject sender receivedAt')
      .lean(),
    Application.countDocuments(filter),
  ]);

  return { applications, pagination: buildPaginationMeta(total, page, limit) };
};

/**
 * Gets applications grouped by company name.
 */
const getApplicationsGroupedByCompany = async (userId) => {
  const applications = await Application.find({ userId })
    .sort({ companyName: 1, appliedAt: -1 })
    .lean();

  const grouped = {};
  for (const app of applications) {
    if (!grouped[app.companyName]) {
      grouped[app.companyName] = [];
    }
    grouped[app.companyName].push(app);
  }

  return Object.entries(grouped).map(([company, apps]) => ({
    company,
    applications: apps,
    total: apps.length,
  }));
};

/**
 * Gets a single application.
 */
const getApplicationById = async (applicationId, userId) => {
  const application = await Application.findOne({ _id: applicationId, userId })
    .populate('emailId', 'subject sender body receivedAt');
  if (!application) throw new Error('Application not found');
  return application;
};

/**
 * Updates an application.
 */
const updateApplication = async (applicationId, userId, data) => {
  const application = await Application.findOneAndUpdate(
    { _id: applicationId, userId },
    { $set: data },
    { new: true, runValidators: true }
  );
  if (!application) throw new Error('Application not found');
  return application;
};

/**
 * Updates application status with history tracking.
 */
const updateApplicationStatus = async (applicationId, userId, status, note = '') => {
  const application = await Application.findOne({ _id: applicationId, userId });
  if (!application) throw new Error('Application not found');

  const lastHistory = application.statusHistory[application.statusHistory.length - 1];
  if (!lastHistory || lastHistory.status !== status) {
    application.statusHistory.push({ status, changedAt: new Date(), note });
  }
  application.status = status;
  await application.save();

  return application;
};

/**
 * Deletes an application.
 */
const deleteApplication = async (applicationId, userId) => {
  const result = await Application.findOneAndDelete({ _id: applicationId, userId });
  if (!result) throw new Error('Application not found');
  return result;
};

/**
 * Gets application statistics for the dashboard.
 */
const getApplicationStats = async (userId) => {
  const stats = await Application.aggregate([
    { $match: { userId: require('mongoose').Types.ObjectId.createFromHexString(userId.toString()) } },
    {
      $group: {
        _id: '$status',
        count: { $sum: 1 },
      },
    },
  ]);

  const result = {
    total: 0,
    applied: 0,
    interview: 0,
    offer: 0,
    rejected: 0,
  };

  for (const s of stats) {
    const key = s._id.toLowerCase();
    result[key] = s.count;
    result.total += s.count;
  }

  return result;
};

module.exports = {
  createApplication,
  getApplications,
  getApplicationsGroupedByCompany,
  getApplicationById,
  updateApplication,
  updateApplicationStatus,
  deleteApplication,
  getApplicationStats,
};
