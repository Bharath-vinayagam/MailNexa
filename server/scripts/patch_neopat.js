require('dotenv').config();
const mongoose = require('mongoose');
const path = require('path');

mongoose.connect(process.env.MONGODB_URI).then(async () => {
  const User = require(path.join(__dirname, '..', 'models', 'User'));

  const result = await User.updateMany(
    { $or: [{ neoPatId: '' }, { neoPatId: null }, { neoPatId: { $exists: false } }] },
    { $set: { neoPatId: process.env.STUDENT_NEOPAT_ID || '<YOUR_NEOPAT_ID>', registrationNumber: process.env.STUDENT_REG_NO || '<YOUR_REG_NO>' } }
  );
  console.log(`Updated ${result.modifiedCount} users with student identifiers`);

  const users = await User.find({}).select('name email registrationNumber neoPatId');
  users.forEach(u => console.log(`  [${u.email}] reg=${u.registrationNumber} | neo=${u.neoPatId}`));

  await mongoose.disconnect();
  console.log('Done!');
}).catch(e => { console.error(e.message); process.exit(1); });
