const assert = require('node:assert/strict');
const argon2 = require('argon2');
const jwt = require('jsonwebtoken');
const { ObjectId } = require('mongodb');
const { after, test } = require('node:test');
const { createApp } = require('../src/app');
const { createAdminCredentialLimiter } = require('../src/routes/auth');

const authTokenSecret = 'test-only-admin-credentials-secret-at-least-32-bytes';
const currentPassword = 'current-test-password';
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

async function createHarness(role = 'admin', options = {}) {
  const admin = {
    _id: new ObjectId(),
    fullName: 'Test Admin',
    username: 'test_admin',
    email: 'admin@example.test',
    role,
    status: 'active',
    sessionVersion: 0,
    passwordHash: await argon2.hash(currentPassword, {
      type: argon2.argon2id,
    }),
  };
  const users = [admin];
  const collection = {
    async findOne(query) {
      return users.find((user) =>
        Object.entries(query).every(([key, value]) => {
          if (key === '_id') return user._id.equals(value);
          if (
            key === 'sessionVersion' &&
            value &&
            typeof value === 'object' &&
            '$exists' in value
          ) {
            return (user.sessionVersion !== undefined) === value.$exists;
          }
          return user[key] === value;
        }),
      ) ?? null;
    },
    async updateOne(query, update) {
      const user = users.find((record) =>
        Object.entries(query).every(([key, value]) => {
          if (key === '_id') return record._id.equals(value);
          if (
            key === 'sessionVersion' &&
            value &&
            typeof value === 'object' &&
            '$exists' in value
          ) {
            return (record.sessionVersion !== undefined) === value.$exists;
          }
          return record[key] === value;
        }),
      );
      if (!user) return { modifiedCount: 0 };
      if (
        update.$set.email &&
        users.some(
          (record) =>
            record !== user && record.email === update.$set.email,
        )
      ) {
        const error = new Error('Duplicate email.');
        error.code = 11000;
        throw error;
      }
      Object.assign(user, update.$set);
      return { modifiedCount: 1 };
    },
  };
  const app = createApp({
    checkDatabase: async () => {},
    authTokenSecret,
    usersCollection: () => collection,
    hashPassword: (password) =>
      argon2.hash(password, { type: argon2.argon2id }),
    verifyPassword: (password, hash) => argon2.verify(hash, password),
    ...options,
  });
  const server = app.listen(0, '127.0.0.1');
  servers.add(server);
  await new Promise((resolve) => server.once('listening', resolve));
  const token = jwt.sign({ sv: admin.sessionVersion }, authTokenSecret, {
    algorithm: 'HS256',
    audience: 'dailyduel-app',
    expiresIn: '1h',
    issuer: 'dailyduel-api',
    subject: admin._id.toString(),
  });
  return {
    admin,
    users,
    token,
    endpoint: `http://127.0.0.1:${server.address().port}/api/v1/auth/account/credentials`,
  };
}

function patch(endpoint, token, body) {
  return fetch(endpoint, {
    method: 'PATCH',
    headers: {
      'content-type': 'application/json',
      ...(token ? { authorization: `Bearer ${token}` } : {}),
    },
    body: JSON.stringify(body),
  });
}

test('admin credential update requires the current password and stores an Argon2id hash', async () => {
  const context = await createHarness();
  const nextPassword = 'a-new-secure-test-password';
  const response = await patch(context.endpoint, context.token, {
    currentPassword,
    email: '  NEW-ADMIN@example.test ',
    newPassword: nextPassword,
    confirmPassword: nextPassword,
  });
  const body = await response.json();

  assert.equal(response.status, 200);
  assert.equal(body.user.email, 'new-admin@example.test');
  assert.equal(body.user.role, 'admin');
  assert.equal(JSON.stringify(body).includes('passwordHash'), false);
  assert.equal(context.admin.email, 'new-admin@example.test');
  assert.notEqual(context.admin.passwordHash, nextPassword);
  assert.equal(context.admin.passwordHash.startsWith('$argon2id$'), true);
  assert.equal(await argon2.verify(context.admin.passwordHash, nextPassword), true);
  assert.equal(await argon2.verify(context.admin.passwordHash, currentPassword), false);
  assert.equal(context.admin.sessionVersion, 1);
  const claims = jwt.verify(body.token, authTokenSecret, {
    algorithms: ['HS256'],
    audience: 'dailyduel-app',
    issuer: 'dailyduel-api',
  });
  assert.equal(claims.sv, 1);
  const oldTokenResponse = await fetch(
    context.endpoint.replace('/account/credentials', '/session'),
    { headers: { authorization: `Bearer ${context.token}` } },
  );
  const newTokenResponse = await fetch(
    context.endpoint.replace('/account/credentials', '/session'),
    { headers: { authorization: `Bearer ${body.token}` } },
  );
  assert.equal(oldTokenResponse.status, 401);
  assert.equal(newTokenResponse.status, 200);
});

test('admin credential update rejects a wrong current password without writing', async () => {
  const context = await createHarness();
  const originalHash = context.admin.passwordHash;
  const response = await patch(context.endpoint, context.token, {
    currentPassword: 'wrong-current-password',
    email: 'changed@example.test',
  });

  assert.equal(response.status, 401);
  assert.equal(context.admin.email, 'admin@example.test');
  assert.equal(context.admin.passwordHash, originalHash);
});

test('regular users cannot update credentials through the admin account route', async () => {
  const context = await createHarness('user');
  const response = await patch(context.endpoint, context.token, {
    currentPassword,
    email: 'changed@example.test',
  });

  assert.equal(response.status, 403);
  assert.equal(context.admin.email, 'admin@example.test');
});

test('admin credential update rejects weak or mismatched passwords', async () => {
  const context = await createHarness();
  const response = await patch(context.endpoint, context.token, {
    currentPassword,
    newPassword: 'too-short',
    confirmPassword: 'not-matching',
  });

  assert.equal(response.status, 400);
  assert.equal(context.admin.passwordHash.startsWith('$argon2id$'), true);
  assert.equal(context.admin.email, 'admin@example.test');
});

test('admin credential update rejects duplicate email without changing the account', async () => {
  const context = await createHarness();
  context.users.push({
    _id: new ObjectId(),
    email: 'taken@example.test',
    role: 'user',
  });
  const response = await patch(context.endpoint, context.token, {
    currentPassword,
    email: 'taken@example.test',
  });

  assert.equal(response.status, 409);
  assert.equal(context.admin.email, 'admin@example.test');
});

test('admin credential update is rate limited by source IP', async () => {
  const context = await createHarness('admin', {
    adminCredentialLimiter: createAdminCredentialLimiter({
      limit: 1,
      windowMs: 60_000,
    }),
  });
  const first = await patch(context.endpoint, context.token, {
    currentPassword,
    email: 'admin@example.test',
  });
  const second = await patch(context.endpoint, context.token, {
    currentPassword,
    email: 'admin@example.test',
  });

  assert.equal(first.status, 400);
  assert.equal(second.status, 429);
  assert.equal(context.admin.email, 'admin@example.test');
});
