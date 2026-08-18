const { sendError } = require('../utils/apiResponse');
const { HTTP_STATUS } = require('../config/constants');

/**
 * Joi schema validation middleware factory.
 * @param {Joi.Schema} schema - Joi schema to validate against
 * @param {'body'|'query'|'params'} source - Which part of request to validate
 */
const validate = (schema, source = 'body') => {
  return (req, res, next) => {
    const data = req[source];
    const { error, value } = schema.validate(data, {
      abortEarly: false,
      stripUnknown: true,
      allowUnknown: false,
    });

    if (error) {
      const errors = error.details.map((detail) => ({
        field: detail.context.key || detail.context.label,
        message: detail.message.replace(/"/g, ''),
      }));
      return sendError(res, 'Validation failed', HTTP_STATUS.BAD_REQUEST, errors);
    }

    req[source] = value;
    next();
  };
};

module.exports = validate;
