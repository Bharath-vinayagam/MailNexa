module.exports = async (req, res) => {
  try {
    const app = require('../server');
    return app(req, res);
  } catch (err) {
    return res.status(500).json({
      error: 'Serverless Handler Initialization Error',
      message: err.message,
      stack: err.stack,
    });
  }
};
