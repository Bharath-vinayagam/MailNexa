/**
 * Standardized API response helpers.
 */

/**
 * Sends a success response.
 */
const sendSuccess = (res, data = {}, message = 'Success', statusCode = 200) => {
  return res.status(statusCode).json({
    success: true,
    message,
    data,
    timestamp: new Date().toISOString(),
  });
};

/**
 * Sends a created response (201).
 */
const sendCreated = (res, data = {}, message = 'Resource created successfully') => {
  return sendSuccess(res, data, message, 201);
};

/**
 * Sends an error response.
 */
const sendError = (res, message = 'An error occurred', statusCode = 500, errors = null) => {
  const response = {
    success: false,
    error: message,
    timestamp: new Date().toISOString(),
  };
  if (errors) response.errors = errors;
  return res.status(statusCode).json(response);
};

/**
 * Sends a paginated response.
 */
const sendPaginated = (res, data, pagination, message = 'Success') => {
  return res.status(200).json({
    success: true,
    message,
    data,
    pagination,
    timestamp: new Date().toISOString(),
  });
};

module.exports = { sendSuccess, sendCreated, sendError, sendPaginated };
