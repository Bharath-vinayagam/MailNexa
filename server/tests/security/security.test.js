const request = require('supertest');
let app;

beforeAll(() => {
  app = require('../../server');
});

describe('Security Tests', () => {
  // ─── Authentication Bypass Tests ──────────────────────
  describe('Authentication', () => {
    test('should reject requests without Bearer prefix', async () => {
      const res = await request(app)
        .get('/api/auth/profile')
        .set('Authorization', 'some_token_no_bearer');
      expect(res.status).toBe(401);
    });

    test('should reject expired-looking tokens gracefully', async () => {
      // A well-formed but expired JWT
      const expiredToken = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VySWQiOiI1MDdmMWY3N2JjZjg2Y2Q3OTk0MzkwMTEiLCJlbWFpbCI6InRlc3RAZXhhbXBsZS5jb20iLCJyb2xlIjoidXNlciIsImlhdCI6MTYwMDAwMDAwMCwiZXhwIjoxNjAwMDAwOTAwfQ.invalid_sig';
      const res = await request(app)
        .get('/api/auth/profile')
        .set('Authorization', `Bearer ${expiredToken}`);
      expect(res.status).toBe(401);
    });

    test('should not expose stack traces in production-like error responses', async () => {
      const res = await request(app).get('/api/auth/profile');
      expect(res.body.stack).toBeUndefined();
    });
  });

  // ─── Input Validation / Injection Tests ───────────────
  describe('Input Sanitization', () => {
    test('should reject oversized request bodies', async () => {
      // The server limits body to 10kb
      const largeBody = { data: 'x'.repeat(20000) };
      const res = await request(app)
        .post('/api/auth/google')
        .send(largeBody);
      // Should either be 413 or 400 (validation)
      expect([400, 413, 429]).toContain(res.status);
    });

    test('should sanitize NoSQL injection in query params', async () => {
      const User = require('../../models/User');
      const { signAccessToken } = require('../../utils/tokenUtils');
      const user = await User.create({ googleId: 'g_security', name: 'Security', email: 'sec@test.com' });
      const token = signAccessToken({ userId: user._id.toString(), email: user.email, role: 'user' });

      // MongoDB injection attempt in category filter
      const res = await request(app)
        .get('/api/emails?category[$ne]=Placement')
        .set('Authorization', `Bearer ${token}`);
      // Should succeed (sanitized) or fail with validation error, NOT expose DB errors
      expect([200, 400]).toContain(res.status);
    });
  });

  // ─── RBAC Tests ───────────────────────────────────────
  describe('Role-Based Access Control', () => {
    const createUser = async (role = 'user') => {
      const User = require('../../models/User');
      const { signAccessToken } = require('../../utils/tokenUtils');
      const user = await User.create({
        googleId: `g_rbac_${role}_${Date.now()}`,
        name: 'RBAC User',
        email: `rbac_${role}_${Date.now()}@test.com`,
        role,
      });
      return signAccessToken({ userId: user._id.toString(), email: user.email, role });
    };

    test('admin route should reject user role', async () => {
      const token = await createUser('user');
      const res = await request(app)
        .get('/api/admin/users')
        .set('Authorization', `Bearer ${token}`);
      expect(res.status).toBe(403);
      expect(res.body.success).toBe(false);
    });

    test('admin route should accept admin role', async () => {
      const token = await createUser('admin');
      const res = await request(app)
        .get('/api/admin/stats')
        .set('Authorization', `Bearer ${token}`);
      expect(res.status).toBe(200);
    });

    test('audit security logs should require admin role', async () => {
      const token = await createUser('user');
      const res = await request(app)
        .get('/api/audit/security')
        .set('Authorization', `Bearer ${token}`);
      expect(res.status).toBe(403);
    });
  });

  // ─── Data Isolation Tests ─────────────────────────────
  describe('Data Isolation', () => {
    test('user should not access another user\'s emails', async () => {
      const User = require('../../models/User');
      const Email = require('../../models/Email');
      const { signAccessToken } = require('../../utils/tokenUtils');

      const user1 = await User.create({ googleId: 'g_iso1', name: 'User 1', email: 'u1@test.com' });
      const user2 = await User.create({ googleId: 'g_iso2', name: 'User 2', email: 'u2@test.com' });

      const email = await Email.create({
        userId: user1._id,
        gmailId: 'iso_email',
        subject: 'Private Email',
        category: 'Personal',
        priority: 'High',
        receivedAt: new Date(),
      });

      const token2 = signAccessToken({ userId: user2._id.toString(), email: user2.email, role: 'user' });

      // User 2 tries to access User 1's email
      const res = await request(app)
        .get(`/api/emails/${email._id}`)
        .set('Authorization', `Bearer ${token2}`);

      expect(res.status).toBe(404);
    });

    test('user should not access another user\'s deadlines', async () => {
      const User = require('../../models/User');
      const Deadline = require('../../models/Deadline');
      const { signAccessToken } = require('../../utils/tokenUtils');

      const user1 = await User.create({ googleId: 'g_diso1', name: 'DUser 1', email: 'du1@test.com' });
      const user2 = await User.create({ googleId: 'g_diso2', name: 'DUser 2', email: 'du2@test.com' });

      const dl = await Deadline.create({
        userId: user1._id,
        title: 'Private Deadline',
        dueDate: new Date(Date.now() + 1000),
      });

      const token2 = signAccessToken({ userId: user2._id.toString(), email: user2.email, role: 'user' });
      const res = await request(app)
        .get(`/api/deadlines/${dl._id}`)
        .set('Authorization', `Bearer ${token2}`);

      expect(res.status).toBe(404);
    });
  });

  // ─── HTTP Security Headers ────────────────────────────
  describe('Security Headers', () => {
    test('should include security headers from Helmet', async () => {
      const res = await request(app).get('/health');
      expect(res.headers['x-content-type-options']).toBe('nosniff');
      expect(res.headers['x-frame-options']).toBeDefined();
    });
  });
});
