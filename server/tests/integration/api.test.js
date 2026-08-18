const request = require('supertest');
let app;

beforeAll(() => {
  app = require('../../server');
});

// Helper: create a user and return JWT
const createUserAndGetToken = async () => {
  const User = require('../../models/User');
  const { signAccessToken } = require('../../utils/tokenUtils');

  const user = await User.create({
    googleId: 'test_google_id',
    name: 'Test User',
    email: 'test@example.com',
    role: 'user',
  });

  const token = signAccessToken({ userId: user._id.toString(), email: user.email, role: user.role });
  return { user, token };
};

const createAdminAndGetToken = async () => {
  const User = require('../../models/User');
  const { signAccessToken } = require('../../utils/tokenUtils');

  const admin = await User.create({
    googleId: 'admin_google_id',
    name: 'Admin User',
    email: 'admin@example.com',
    role: 'admin',
  });

  const token = signAccessToken({ userId: admin._id.toString(), email: admin.email, role: admin.role });
  return { user: admin, token };
};

// ─── Health Check ─────────────────────────────────────────
describe('GET /health', () => {
  test('should return 200 with healthy status', async () => {
    const res = await request(app).get('/health');
    expect(res.status).toBe(200);
    expect(res.body.status).toBe('healthy');
  });
});

// ─── Auth Routes ──────────────────────────────────────────
describe('GET /api/auth/url', () => {
  test('should return Google OAuth URL', async () => {
    process.env.GOOGLE_CLIENT_ID = 'test_client_id.apps.googleusercontent.com';
    process.env.GOOGLE_CLIENT_SECRET = 'test_client_secret';
    process.env.GOOGLE_REDIRECT_URI = 'http://localhost:5000/api/auth/callback';

    const res = await request(app).get('/api/auth/url');
    expect(res.status).toBe(200);
    expect(res.body.data.url).toContain('accounts.google.com');
  });
});

describe('GET /api/auth/profile', () => {
  test('should return 401 without token', async () => {
    const res = await request(app).get('/api/auth/profile');
    expect(res.status).toBe(401);
    expect(res.body.success).toBe(false);
  });

  test('should return user profile with valid token', async () => {
    const { token } = await createUserAndGetToken();
    const res = await request(app)
      .get('/api/auth/profile')
      .set('Authorization', `Bearer ${token}`);
    expect(res.status).toBe(200);
    expect(res.body.data.user.email).toBe('test@example.com');
  });

  test('should return 401 with malformed token', async () => {
    const res = await request(app)
      .get('/api/auth/profile')
      .set('Authorization', 'Bearer invalid.token.here');
    expect(res.status).toBe(401);
  });
});

describe('POST /api/auth/refresh', () => {
  test('should return 400 when refresh token is missing', async () => {
    const res = await request(app).post('/api/auth/refresh').send({});
    expect(res.status).toBe(400);
  });

  test('should return 401 with invalid refresh token', async () => {
    const res = await request(app)
      .post('/api/auth/refresh')
      .send({ refreshToken: 'invalid_token' });
    expect(res.status).toBe(401);
  });
});

// ─── Email Routes ─────────────────────────────────────────
describe('GET /api/emails', () => {
  test('should return 401 without auth', async () => {
    const res = await request(app).get('/api/emails');
    expect(res.status).toBe(401);
  });

  test('should return empty email list for new user', async () => {
    const { token } = await createUserAndGetToken();
    const res = await request(app)
      .get('/api/emails')
      .set('Authorization', `Bearer ${token}`);
    expect(res.status).toBe(200);
    expect(res.body.data).toEqual([]);
    expect(res.body.pagination.total).toBe(0);
  });

  test('should return filtered emails by category', async () => {
    const Email = require('../../models/Email');
    const { user, token } = await createUserAndGetToken();

    await Email.create([
      { userId: user._id, gmailId: 'g1', subject: 'Job', category: 'Placement', priority: 'High', receivedAt: new Date() },
      { userId: user._id, gmailId: 'g2', subject: 'Exam', category: 'Academic', priority: 'Medium', receivedAt: new Date() },
    ]);

    const res = await request(app)
      .get('/api/emails?category=Placement')
      .set('Authorization', `Bearer ${token}`);

    expect(res.status).toBe(200);
    expect(res.body.data.length).toBe(1);
    expect(res.body.data[0].category).toBe('Placement');
  });

  test('should paginate results', async () => {
    const Email = require('../../models/Email');
    const { user, token } = await createUserAndGetToken();

    // Create 5 emails
    for (let i = 0; i < 5; i++) {
      await Email.create({
        userId: user._id,
        gmailId: `g_page_${i}`,
        subject: `Email ${i}`,
        category: 'Others',
        priority: 'Low',
        receivedAt: new Date(),
      });
    }

    const res = await request(app)
      .get('/api/emails?page=1&limit=3')
      .set('Authorization', `Bearer ${token}`);

    expect(res.status).toBe(200);
    expect(res.body.data.length).toBe(3);
    expect(res.body.pagination.totalPages).toBe(2);
    expect(res.body.pagination.hasNextPage).toBe(true);
  });
});

// ─── Deadline Routes ──────────────────────────────────────
describe('Deadline CRUD', () => {
  test('POST /api/deadlines – should create deadline', async () => {
    const { token } = await createUserAndGetToken();
    const res = await request(app)
      .post('/api/deadlines')
      .set('Authorization', `Bearer ${token}`)
      .send({
        title: 'Submit Project',
        dueDate: new Date(Date.now() + 3 * 24 * 60 * 60 * 1000).toISOString(),
        source: 'University Portal',
      });
    expect(res.status).toBe(201);
    expect(res.body.data.deadline.title).toBe('Submit Project');
  });

  test('GET /api/deadlines – should list deadlines', async () => {
    const { user, token } = await createUserAndGetToken();
    const Deadline = require('../../models/Deadline');
    await Deadline.create({ userId: user._id, title: 'Test', dueDate: new Date(Date.now() + 1000) });

    const res = await request(app)
      .get('/api/deadlines')
      .set('Authorization', `Bearer ${token}`);
    expect(res.status).toBe(200);
    expect(res.body.data.length).toBe(1);
  });

  test('POST /api/deadlines/:id/complete – should complete deadline', async () => {
    const { user, token } = await createUserAndGetToken();
    const Deadline = require('../../models/Deadline');
    const dl = await Deadline.create({ userId: user._id, title: 'Complete Me', dueDate: new Date(Date.now() + 1000) });

    const res = await request(app)
      .post(`/api/deadlines/${dl._id}/complete`)
      .set('Authorization', `Bearer ${token}`);
    expect(res.status).toBe(200);
    expect(res.body.data.deadline.isCompleted).toBe(true);
  });

  test('DELETE /api/deadlines/:id – should delete deadline', async () => {
    const { user, token } = await createUserAndGetToken();
    const Deadline = require('../../models/Deadline');
    const dl = await Deadline.create({ userId: user._id, title: 'Delete Me', dueDate: new Date(Date.now() + 1000) });

    const res = await request(app)
      .delete(`/api/deadlines/${dl._id}`)
      .set('Authorization', `Bearer ${token}`);
    expect(res.status).toBe(200);

    const check = await Deadline.findById(dl._id);
    expect(check).toBeNull();
  });
});

// ─── Application Routes ───────────────────────────────────
describe('Application CRUD', () => {
  test('POST /api/applications – should create application', async () => {
    const { token } = await createUserAndGetToken();
    const res = await request(app)
      .post('/api/applications')
      .set('Authorization', `Bearer ${token}`)
      .send({ companyName: 'Google', role: 'SWE Intern', status: 'Applied' });
    expect(res.status).toBe(201);
    expect(res.body.data.application.companyName).toBe('Google');
  });

  test('PATCH /api/applications/:id/status – should update status', async () => {
    const { user, token } = await createUserAndGetToken();
    const Application = require('../../models/Application');
    const app2 = await Application.create({ userId: user._id, companyName: 'Meta', role: 'PM', status: 'Applied' });

    const res = await request(app)
      .patch(`/api/applications/${app2._id}/status`)
      .set('Authorization', `Bearer ${token}`)
      .send({ status: 'Interview', note: 'First round scheduled' });
    expect(res.status).toBe(200);
    expect(res.body.data.application.status).toBe('Interview');
  });

  test('GET /api/applications/stats – should return stats', async () => {
    const { user, token } = await createUserAndGetToken();
    const Application = require('../../models/Application');
    await Application.insertMany([
      { userId: user._id, companyName: 'A', role: 'R1', status: 'Applied' },
      { userId: user._id, companyName: 'B', role: 'R2', status: 'Interview' },
      { userId: user._id, companyName: 'C', role: 'R3', status: 'Offer' },
    ]);

    const res = await request(app)
      .get('/api/applications/stats')
      .set('Authorization', `Bearer ${token}`);
    expect(res.status).toBe(200);
    expect(res.body.data.stats.total).toBe(3);
    expect(res.body.data.stats.offer).toBe(1);
  });
});

// ─── Admin Routes ─────────────────────────────────────────
describe('Admin Routes – RBAC', () => {
  test('GET /api/admin/users – should return 403 for regular user', async () => {
    const { token } = await createUserAndGetToken();
    const res = await request(app)
      .get('/api/admin/users')
      .set('Authorization', `Bearer ${token}`);
    expect(res.status).toBe(403);
  });

  test('GET /api/admin/users – should return users for admin', async () => {
    const { token } = await createAdminAndGetToken();
    const res = await request(app)
      .get('/api/admin/users')
      .set('Authorization', `Bearer ${token}`);
    expect(res.status).toBe(200);
    expect(Array.isArray(res.body.data)).toBe(true);
  });

  test('GET /api/admin/stats – should return system stats for admin', async () => {
    const { token } = await createAdminAndGetToken();
    const res = await request(app)
      .get('/api/admin/stats')
      .set('Authorization', `Bearer ${token}`);
    expect(res.status).toBe(200);
    expect(res.body.data.stats.totalUsers).toBeDefined();
  });
});

// ─── Search Route ─────────────────────────────────────────
describe('GET /api/emails/search', () => {
  test('should search emails by query', async () => {
    const Email = require('../../models/Email');
    const { user, token } = await createUserAndGetToken();

    await Email.create({
      userId: user._id,
      gmailId: 'search_001',
      subject: 'Interview Invitation',
      snippet: 'Technical interview for software engineer role',
      sender: 'HR TechCorp',
      category: 'Placement',
      priority: 'High',
      receivedAt: new Date(),
    });

    const res = await request(app)
      .get('/api/emails/search?q=interview')
      .set('Authorization', `Bearer ${token}`);

    expect(res.status).toBe(200);
  });
});

// ─── 404 Route ────────────────────────────────────────────
describe('404 Handler', () => {
  test('should return 404 for unknown routes', async () => {
    const res = await request(app).get('/api/nonexistent-route');
    expect(res.status).toBe(404);
    expect(res.body.success).toBe(false);
  });
});
