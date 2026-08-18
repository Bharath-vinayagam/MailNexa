

describe('User Model', () => {
  const User = require('../../models/User');

  test('should create a valid user', async () => {
    const user = await User.create({
      googleId: 'google_123',
      name: 'Test User',
      email: 'test@example.com',
    });
    expect(user._id).toBeDefined();
    expect(user.email).toBe('test@example.com');
    expect(user.role).toBe('user');
    expect(user.isActive).toBe(true);
  });

  test('should enforce unique email constraint', async () => {
    await User.create({ googleId: 'g1', name: 'User 1', email: 'same@example.com' });
    await expect(
      User.create({ googleId: 'g2', name: 'User 2', email: 'same@example.com' })
    ).rejects.toThrow();
  });

  test('should enforce unique googleId constraint', async () => {
    await User.create({ googleId: 'same_google_id', name: 'User 1', email: 'a@a.com' });
    await expect(
      User.create({ googleId: 'same_google_id', name: 'User 2', email: 'b@b.com' })
    ).rejects.toThrow();
  });

  test('toSafeJSON should exclude sensitive fields', async () => {
    const user = await User.create({
      googleId: 'g3',
      name: 'Safe User',
      email: 'safe@example.com',
      googleRefreshToken: 'encrypted_token',
      fcmToken: 'fcm_token',
    });
    const safe = user.toSafeJSON();
    expect(safe.googleRefreshToken).toBeUndefined();
    expect(safe.fcmToken).toBeUndefined();
    expect(safe.name).toBe('Safe User');
  });
});

describe('Email Model', () => {
  const User = require('../../models/User');
  const Email = require('../../models/Email');

  let userId;
  beforeEach(async () => {
    const user = await User.create({ googleId: 'gEmail', name: 'Email User', email: 'email@test.com' });
    userId = user._id;
  });

  test('should create a valid email', async () => {
    const email = await Email.create({
      userId,
      gmailId: 'gmail_001',
      subject: 'Test Email',
      snippet: 'Test snippet',
      category: 'Placement',
      priority: 'High',
      receivedAt: new Date(),
    });
    expect(email._id).toBeDefined();
    expect(email.category).toBe('Placement');
    expect(email.priority).toBe('High');
  });

  test('should enforce category enum', async () => {
    await expect(Email.create({
      userId,
      gmailId: 'gmail_002',
      category: 'InvalidCategory',
      priority: 'High',
      receivedAt: new Date(),
    })).rejects.toThrow();
  });

  test('should enforce priority enum', async () => {
    await expect(Email.create({
      userId,
      gmailId: 'gmail_003',
      category: 'Academic',
      priority: 'Critical',
      receivedAt: new Date(),
    })).rejects.toThrow();
  });

  test('should enforce unique userId+gmailId combination', async () => {
    await Email.create({ userId, gmailId: 'dup_gmail', subject: 'First', category: 'Others', priority: 'Low', receivedAt: new Date() });
    await expect(Email.create({
      userId, gmailId: 'dup_gmail', subject: 'Second', category: 'Others', priority: 'Low', receivedAt: new Date()
    })).rejects.toThrow();
  });
});

describe('Deadline Model', () => {
  const User = require('../../models/User');
  const Deadline = require('../../models/Deadline');

  let userId;
  beforeEach(async () => {
    const user = await User.create({ googleId: 'gDeadline', name: 'DL User', email: 'dl@test.com' });
    userId = user._id;
  });

  test('should create a valid deadline', async () => {
    const dl = await Deadline.create({
      userId,
      title: 'Submit Assignment',
      dueDate: new Date(Date.now() + 24 * 60 * 60 * 1000),
    });
    expect(dl._id).toBeDefined();
    expect(dl.isCompleted).toBe(false);
    expect(dl.isOverdue).toBe(false);
  });

  test('should auto-set isOverdue for past-due deadlines on save', async () => {
    const dl = await Deadline.create({
      userId,
      title: 'Overdue Task',
      dueDate: new Date(Date.now() - 1000),
    });
    expect(dl.isOverdue).toBe(true);
  });

  test('should set completedAt when marking completed', async () => {
    const dl = await Deadline.create({
      userId,
      title: 'Task to complete',
      dueDate: new Date(Date.now() + 10000),
    });
    dl.isCompleted = true;
    await dl.save();
    expect(dl.completedAt).toBeDefined();
  });
});

describe('Application Model', () => {
  const User = require('../../models/User');
  const Application = require('../../models/Application');

  let userId;
  beforeEach(async () => {
    const user = await User.create({ googleId: 'gApp', name: 'App User', email: 'app@test.com' });
    userId = user._id;
  });

  test('should create a valid application', async () => {
    const app = await Application.create({
      userId,
      companyName: 'Google',
      role: 'SWE Intern',
      status: 'Applied',
    });
    expect(app._id).toBeDefined();
    expect(app.status).toBe('Applied');
    expect(app.companyName).toBe('Google');
  });

  test('should enforce status enum', async () => {
    await expect(Application.create({
      userId,
      companyName: 'Meta',
      role: 'Engineer',
      status: 'Pending',
    })).rejects.toThrow();
  });
});
