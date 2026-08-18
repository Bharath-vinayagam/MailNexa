const mongoose = require('mongoose');
const logger = require('../utils/logger');

let cachedConn = null;

const connectDB = async () => {
  if (mongoose.connection.readyState === 1) {
    return mongoose.connection;
  }
  if (cachedConn) {
    return cachedConn;
  }

  const uri = process.env.NODE_ENV === 'test'
    ? process.env.MONGODB_URI_TEST
    : process.env.MONGODB_URI;

  if (!uri) {
    logger.error('MONGODB_URI environment variable is missing');
    throw new Error('MONGODB_URI environment variable is missing');
  }

  const options = {
    serverSelectionTimeoutMS: 5000,
    socketTimeoutMS: 45000,
    maxPoolSize: 10,
    minPoolSize: 1,
    retryWrites: true,
    w: 'majority',
  };

  cachedConn = mongoose.connect(uri, options)
    .then((m) => {
      logger.info(`MongoDB connected: ${m.connection.host}`);
      return m.connection;
    })
    .catch((err) => {
      cachedConn = null;
      logger.error('MongoDB connection failed:', err.message);
      throw err;
    });

  return cachedConn;
};

module.exports = connectDB;
