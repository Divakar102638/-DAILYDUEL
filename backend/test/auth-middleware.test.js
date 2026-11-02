const assert = require('node:assert/strict');
const jwt = require('jsonwebtoken');
const { ObjectId } = require('mongodb');
const { after, test } = require('node:test');
const { createApp } = require('../src/app');

const authTokenSecret = 'test-only-auth-token-secret-at-least-32-bytes';
const userId = new ObjectId();
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

function createToken({
  subject = userId.toString(),
  expiresIn = '1h',
  secret = authTokenSecret,
  claims = {},
} = {}) {
  return jwt.sign(claims, secret, {
    algorithm: 'HS256',
    audience: 'dailyduel-app',
    expiresIn,
    issuer: 'dailyduel-api',
    subject,
  });
}

async function startAdminServer(getUser) {
  const server = createApp({
    checkDatabase: async () => {},
    usersCollection: () => ({
      findOne: async ({ _id }) =>
        _id.toString() === userId.toString() ? getUser() : null,
    }),
    authTokenSecret,
  }).listen(0, '127.0.0.1');
  servers.add(server);
  await new Promise((resolve) => server.once('listening', resolve));
  return `http://127.0.0.1:${server.address().port}/api/v1/admin/access`;
}

function activeUser(role = 'user') {
  return {
    _id: userId,
    fullName: 'Test User',
    username: 'test_user',
    email: 'test@example.test',
    passwordHash: 'never-returned',
    role,
  };
}

test('administrator endpoint rejects missing, malformed, invalid, and expired JWTs', async () => {
  const url = await startAdminServer(() => activeUser('admin'));
  const authorizations = [
    null,
    'not-a-bearer-token',
    'Bearer not.a.jwt',
    `Bearer ${createToken({
      secret: 'a-different-test-secret-with-enough-bytes',
    })}`,
    `Bearer ${createToken({ expiresIn: '-1s' })}`,
  ];

  for (const authorization of authorizations) {
    const response = await fetch(url, {
      headers: authorization ? { authorization } : {},
    });
    assert.equal(response.status, 401);
    assert.deepEqual(await response.json(), {
      error: {
        code: 'UNAUTHENTICATED',
        message: 'A valid login session is required.',
      },
    });
  }
});

test('administrator endpoint denies normal users and ignores JWT role claims', async () => {
  const url = await startAdminServer(() => activeUser('user'));
  const token = createToken({ claims: { role: 'admin' } });

  const response = await fetch(url, {
    headers: { authorization: `Bearer ${token}` },
  });

  assert.equal(response.status, 403);
  assert.deepEqual(await response.json(), {
    error: {
      code: 'FORBIDDEN',
      message: 'Administrator permissions are required.',
    },
  });
});

test('administrator endpoint permits current admins without exposing sensitive fields', async () => {
  const url = await startAdminServer(() => activeUser('admin'));
  const response = await fetch(url, {
    headers: { authorization: `Bearer ${createToken()}` },
  });

  assert.equal(response.status, 200);
  assert.deepEqual(await response.json(), { authorized: true });
  assert.equal(response.headers.get('content-type'), 'application/json; charset=utf-8');
});

test('deleted or disabled users cannot continue using existing tokens', async () => {
  let user = activeUser('admin');
  const url = await startAdminServer(() => user);
  const headers = { authorization: `Bearer ${createToken()}` };

  assert.equal((await fetch(url, { headers })).status, 200);
  user = null;
  assert.equal((await fetch(url, { headers })).status, 401);
  user = { ...activeUser('admin'), disabled: true };
  assert.equal((await fetch(url, { headers })).status, 401);
});

test('administrator access reflects current database role after demotion', async () => {
  let user = activeUser('admin');
  const url = await startAdminServer(() => user);
  const headers = { authorization: `Bearer ${createToken()}` };

  assert.equal((await fetch(url, { headers })).status, 200);
  user = activeUser('user');
  assert.equal((await fetch(url, { headers })).status, 403);
});
