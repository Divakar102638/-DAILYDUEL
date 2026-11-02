const assert = require('node:assert/strict');
const { ObjectId } = require('mongodb');
const { after, test } = require('node:test');
const { createApp } = require('../src/app');

const authTokenSecret = 'test-only-admin-login-flow-secret-at-least-32-bytes';
const adminOrigin = 'https://dailyduel-admin.onrender.com';
const servers = new Set();

after(async () => {
  await Promise.all(
    [...servers].map(
      (server) =>
        new Promise((resolve, reject) => {
          server.close((error) => (error ? reject(error) : resolve()));
        }),
    ),
  );
});

test('admin login, session verification, access check, and student listing work with deployed origin', async () => {
  const admin = {
    _id: new ObjectId(),
    fullName: 'Admin User',
    username: 'admin_user',
    email: 'admin@example.test',
    passwordHash: '$argon2id$test-only-password-hash',
    role: 'admin',
  };
  const student = {
    _id: new ObjectId(),
    fullName: 'Student User',
    username: 'student_user',
    email: 'student@example.test',
    passwordHash: '$argon2id$student-password-hash',
    role: 'user',
    createdAt: new Date('2026-01-02T03:04:05.000Z'),
  };
  const users = [admin, student];
  const usersCollection = {
    async findOne(query) {
      return users.find((user) =>
        query.email
          ? user.email === query.email
          : user._id.equals(query._id),
      ) ?? null;
    },
    async countDocuments(query) {
      return users.filter((user) => user.role === query.role).length;
    },
    find(query, options) {
      assert.deepEqual(query, { role: 'user' });
      assert.deepEqual(options.projection, {
        _id: 1,
        fullName: 1,
        username: 1,
        email: 1,
        createdAt: 1,
      });
      const records = users.filter((user) => user.role === query.role);
      return {
        sort() { return this; },
        skip() { return this; },
        limit() { return this; },
        async toArray() { return records; },
      };
    },
  };
  const server = createApp({
    allowedOrigins: [adminOrigin],
    authTokenSecret,
    usersCollection: () => usersCollection,
    verifyPassword: async () => true,
    checkDatabase: async () => {},
  }).listen(0, '127.0.0.1');
  servers.add(server);
  await new Promise((resolve) => server.once('listening', resolve));
  const baseUrl = `http://127.0.0.1:${server.address().port}`;

  const preflight = await fetch(`${baseUrl}/api/v1/auth/session`, {
    method: 'OPTIONS',
    headers: {
      Origin: adminOrigin,
      'Access-Control-Request-Method': 'GET',
      'Access-Control-Request-Headers': 'authorization',
    },
  });
  assert.equal(preflight.status, 204);
  assert.equal(preflight.headers.get('access-control-allow-origin'), adminOrigin);
  assert.match(preflight.headers.get('access-control-allow-headers'), /Authorization/i);

  const login = await fetch(`${baseUrl}/api/v1/auth/login`, {
    method: 'POST',
    headers: {
      Origin: adminOrigin,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({ email: admin.email, password: 'test-only-password' }),
  });
  assert.equal(login.status, 200);
  assert.equal(login.headers.get('access-control-allow-origin'), adminOrigin);
  const loginBody = await login.json();
  assert.equal(loginBody.user.role, 'admin');
  assert.equal(typeof loginBody.token, 'string');

  const authHeaders = {
    Origin: adminOrigin,
    Authorization: `Bearer ${loginBody.token}`,
  };
  const session = await fetch(`${baseUrl}/api/v1/auth/session`, {
    headers: authHeaders,
  });
  assert.equal(session.status, 200);
  assert.equal((await session.json()).user.role, 'admin');

  const access = await fetch(`${baseUrl}/api/v1/admin/access`, {
    headers: authHeaders,
  });
  assert.equal(access.status, 200);
  assert.deepEqual(await access.json(), { authorized: true });

  const listing = await fetch(`${baseUrl}/api/v1/admin/users`, {
    headers: authHeaders,
  });
  assert.equal(listing.status, 200);
  const listingBody = await listing.json();
  assert.equal(listingBody.pagination.total, 1);
  assert.deepEqual(listingBody.users[0], {
    id: student._id.toString(),
    fullName: student.fullName,
    username: student.username,
    email: student.email,
    createdAt: student.createdAt.toISOString(),
  });
  assert.equal(JSON.stringify(listingBody).includes('passwordHash'), false);
});
