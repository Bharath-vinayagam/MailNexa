const applicationService = require('../services/applicationService');
const { sendSuccess, sendCreated, sendError, sendPaginated } = require('../utils/apiResponse');
const { HTTP_STATUS } = require('../config/constants');

const handleNotFound = (res, error) => {
  if (error.message === 'Application not found') {
    return sendError(res, 'Application not found', HTTP_STATUS.NOT_FOUND);
  }
  return null;
};

/**
 * POST /api/applications
 */
const createApplication = async (req, res, next) => {
  try {
    const application = await applicationService.createApplication(req.userId, req.body);
    return sendCreated(res, { application }, 'Application created successfully');
  } catch (error) {
    next(error);
  }
};

/**
 * GET /api/applications
 */
const getApplications = async (req, res, next) => {
  try {
    const { applications, pagination } = await applicationService.getApplications(req.userId, req.query);
    return sendPaginated(res, applications, pagination, 'Applications retrieved');
  } catch (error) {
    next(error);
  }
};

/**
 * GET /api/applications/grouped
 * Returns applications grouped by company name.
 */
const getApplicationsGrouped = async (req, res, next) => {
  try {
    const groups = await applicationService.getApplicationsGroupedByCompany(req.userId);
    return sendSuccess(res, { groups }, 'Applications grouped by company');
  } catch (error) {
    next(error);
  }
};

/**
 * GET /api/applications/stats
 */
const getApplicationStats = async (req, res, next) => {
  try {
    const stats = await applicationService.getApplicationStats(req.userId);
    return sendSuccess(res, { stats }, 'Application statistics retrieved');
  } catch (error) {
    next(error);
  }
};

/**
 * GET /api/applications/:id
 */
const getApplicationById = async (req, res, next) => {
  try {
    const application = await applicationService.getApplicationById(req.params.id, req.userId);
    return sendSuccess(res, { application }, 'Application retrieved');
  } catch (error) {
    const handled = handleNotFound(res, error);
    if (handled) return handled;
    next(error);
  }
};

/**
 * PUT /api/applications/:id
 */
const updateApplication = async (req, res, next) => {
  try {
    const application = await applicationService.updateApplication(req.params.id, req.userId, req.body);
    return sendSuccess(res, { application }, 'Application updated');
  } catch (error) {
    const handled = handleNotFound(res, error);
    if (handled) return handled;
    next(error);
  }
};

/**
 * PATCH /api/applications/:id/status
 * Updates application status with optional note.
 * Body: { status: string, note?: string }
 */
const updateStatus = async (req, res, next) => {
  try {
    const { status, note } = req.body;
    const application = await applicationService.updateApplicationStatus(
      req.params.id,
      req.userId,
      status,
      note
    );
    return sendSuccess(res, { application }, 'Application status updated');
  } catch (error) {
    const handled = handleNotFound(res, error);
    if (handled) return handled;
    next(error);
  }
};

/**
 * DELETE /api/applications/:id
 */
const deleteApplication = async (req, res, next) => {
  try {
    await applicationService.deleteApplication(req.params.id, req.userId);
    return sendSuccess(res, null, 'Application deleted');
  } catch (error) {
    const handled = handleNotFound(res, error);
    if (handled) return handled;
    next(error);
  }
};

module.exports = {
  createApplication,
  getApplications,
  getApplicationsGrouped,
  getApplicationStats,
  getApplicationById,
  updateApplication,
  updateStatus,
  deleteApplication,
};
