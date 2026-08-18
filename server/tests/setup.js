const { MongoMemoryServer } = require('mongodb-memory-server');
const mongoose = require('mongoose');

// Increase timeout for first-time binary download
jest.setTimeout(120000);

let mongod;

// Start in-memory MongoDB before all tests
beforeAll(async () => {
  process.env.NODE_ENV = 'test';
  process.env.JWT_SECRET = 'test_jwt_secret_32_chars_minimum__';
  process.env.JWT_REFRESH_SECRET = 'test_refresh_secret_32_chars_min__';
  process.env.JWT_EXPIRES_IN = '15m';
  process.env.JWT_REFRESH_EXPIRES_IN = '7d';
  process.env.ENCRYPTION_KEY = 'test_encryption_key_32_chars____';

  mongod = await MongoMemoryServer.create();
  const uri = mongod.getUri();
  process.env.MONGODB_URI_TEST = uri;

  if (mongoose.connection.readyState === 0) {
    await mongoose.connect(uri);
  }
}, 120000);

// Clear all collections between tests
beforeEach(async () => {
  if (mongoose.connection.readyState !== 0) {
    const collections = mongoose.connection.collections;
    for (const key in collections) {
      await collections[key].deleteMany({});
    }
  }
});

// Close connection after all tests
afterAll(async () => {
  if (mongoose.connection.readyState !== 0) {
    await mongoose.disconnect();
  }
  if (mongod) {
    await mongod.stop();
  }
});
