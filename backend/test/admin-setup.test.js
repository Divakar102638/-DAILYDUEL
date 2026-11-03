const assert = require('node:assert/strict');
const argon2 = require('argon2');
const { createHash } = require('node:crypto');
const { ObjectId } = require('mongodb');
const { after, test } = require('node:test');
const { createApp } = require('../src/app');

const authTokenSecret = 'test-only-admin-setup-auth-secret-at-least-32-bytes';
const setupSecret = 'test-only-one-time-setup-secret-at-least-32-bytes';
const setupSecretHash = createHash('sha256')
  .update(setupSecret)
  .digest('hex');
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

function createHarness({ users = [], markers = [] } = {}) {
  let transactionTail = Promise.resolve();
  const usersCollection = {
    async createIndex() {},
    async countDocuments(query) {
      return users.filter((user) => user.role === query.role).length;
    },
    async findOne(query) {
      return users.find((user) =>
        query.email
          ? user.email === query.email
          : user._id.equals(query._id),
      ) ?? null;
    },
    async insertOne(user) {
      const emailExists = users.some((entry) => entry.email === user.email);
      if (emailExists) {
        const error = new Error('Duplicate email.');
        error.code = 11000;
        error.keyPattern = { email: 1 };
        throw error;
      }
      const usernameExists = users.some(
        (entry) => entry.username === user.username,
      );
      if (usernameExists) {
        const error = new Error('Duplicate username.');
        error.code = 11000;
        error.keyPattern = { username: 1 };
        throw error;
      }
      const record = { ...user, _id: new ObjectId() };
      users.push(record);
      return { insertedId: record._id };
    },
  };
  const markersCollection = {
    async findOne(query) {
      return markers.find((marker) => marker._id === query._id) ?? null;
    },
    async insertOne(marker) {
      if (markers.some((entry) => entry._id === marker._id)) {
        const error = new Error('Duplicate marker.');
        error.code = 11000;
        error.keyPattern = { _id: 1 };
        throw error;
      }
      markers.push(marker);
      return { insertedId: marker._id };
    },
  };
  const database = {
    collection(name) {
      return name === 'users' ? usersCollection : markersCollection;
    },
  };
  const client = {
    startSession() {
      return {
        async withTransaction(operation) {
          const previous = transactionTail;
          let release;
          transactionTail = new Promise((resolve) => {
            release = resolve;
          });
          await previous;
          const usersSnapshot = users.slice();
          const markersSnapshot = markers.slice();
          try {
            await operation();
          } catch (error) {
            users.splice(0, users.length, ...usersSnapshot);
            markers.splice(0, markers.length, ...markersSnapshot);
            throw error;
          } finally {
            release();
          }
        },
        async endSession() {},
      };
    },
  };
  return { client, database, users, markers, usersCollection };
}

async function startServer(harness, options = {}) {
  const server = createApp({
    authTokenSecret,
    adminBootstrapSecretHash: setupSecretHash,
    database: () => harness.database,
    mongoClient: () => harness.client,
    usersCollection: () => harness.usersCollection,
    hashPassword: (password) =>
      argon2.hash(password, { type: argon2.argon2id }),
    verifyPassword: (password, passwordHash) =>
      argon2.verify(passwordHash, password),
    checkDatabase: async () => {},
    ...options,
  }).listen(0, '127.0.0.1');
  servers.add(server);
  await new Promise((resolve) => server.once('listening', resolve));
  return `http://127.0.0.1:${server.address().port}/api/v1/auth`;
}

function setupBody(overrides = {}) {
  return {
    fullName: 'New Admin',
    username: 'new_admin',
    email: 'new-admin@example.test',
    password: 'a-strong-test-password',
    confirmPassword: 'a-strong-test-password',
    setupSecret,
    ...overrides,
  };
}

async function postSetup(baseUrl, body) {
  return fetch(`${baseUrl}/admin-setup`, {
    method: 'POST',
    headers: { 'content-type': 'application/json' },
    body: JSON.stringify(body),
  });
}

test('first-admin setup creates an Argon2id admin and leaves regular users unchanged', async () => {
  const regularUser = {
    _id: new ObjectId(),
    fullName: 'Mobile User',
    username: 'mobile_user',
    email: 'mobile-user@example.test',
    passwordHash: '$argon2id$existing-test-hash',
    role: 'user',
  };
  const regularUserSnapshot = { ...regularUser };
  const harness = createHarness({ users: [regularUser] });
  const baseUrl = await startServer(harness);

  const status = await fetch(`${baseUrl}/admin-setup/status`);
  assert.equal(status.status, 200);
  assert.deepEqual(await status.json(), { setupAvailable: true });

  const setup = await postSetup(baseUrl, setupBody());
  assert.equal(setup.status, 201);
  assert.deepEqual(await setup.json(), { initialized: true });
  assert.equal(harness.users.length, 2);

  const admin = harness.users.find((user) => user.email === 'new-admin@example.test');
  assert.equal(admin.role, 'admin');
  assert.equal(admin.status, 'active');
  assert.notEqual(admin.passwordHash, 'a-strong-test-password');
  assert.equal(
    await argon2.verify(admin.passwordHash, 'a-strong-test-password'),
    true,
  );
  assert.deepEqual(harness.users[0], regularUserSnapshot);
  assert.equal(harness.markers.length, 1);
  assert.equal(harness.markers[0].adminEmail, admin.email);
  assert.equal(JSON.stringify(harness.markers).includes(setupSecret), false);

  const login = await fetch(`${baseUrl}/login`, {
    method: 'POST',
    headers: { 'content-type': 'application/json' },
    body: JSON.stringify({
      email: admin.email,
      password: 'a-strong-test-password',
    }),
  });
  assert.equal(login.status, 200);
  const session = await login.json();
  const access = await fetch('http://127.0.0.1:' + new URL(baseUrl).port + '/api/v1/admin/access', {
    headers: { authorization: `Bearer ${session.token}` },
  });
  assert.equal(access.status, 200);
});

test('first-admin setup is unavailable when an administrator or marker exists', async () => {
  const existingAdmin = {
    _id: new ObjectId(),
    fullName: 'Existing Admin',
    username: 'existing_admin',
    email: 'existing-admin@example.test',
    passwordHash: '$argon2id$existing-test-hash',
    role: 'admin',
  };
  const adminHarness = createHarness({ users: [existingAdmin] });
  const adminUrl = await startServer(adminHarness);
  const adminStatus = await fetch(`${adminUrl}/admin-setup/status`);
  assert.deepEqual(await adminStatus.json(), { setupAvailable: false });
  const blockedByAdmin = await postSetup(adminUrl, setupBody());
  assert.equal(blockedByAdmin.status, 409);
  assert.deepEqual(adminHarness.users, [existingAdmin]);
  assert.equal(adminHarness.markers.length, 0);

  const markerHarness = createHarness({
    markers: [{ _id: 'first-admin-bootstrap' }],
  });
  const markerUrl = await startServer(markerHarness);
  const markerStatus = await fetch(`${markerUrl}/admin-setup/status`);
  assert.deepEqual(await markerStatus.json(), { setupAvailable: false });
  const blockedByMarker = await postSetup(markerUrl, setupBody());
  assert.equal(blockedByMarker.status, 409);
  assert.equal(markerHarness.users.length, 0);
});

test('first-admin setup rejects an invalid secret and invalid password input', async () => {
  const harness = createHarness();
  const baseUrl = await startServer(harness);

  const invalidSecret = await postSetup(
    baseUrl,
    setupBody({ setupSecret: 'wrong-secret-that-is-long-enough-123456' }),
  );
  assert.equal(invalidSecret.status, 403);
  assert.equal(harness.users.length, 0);

  const shortPassword = await postSetup(
    baseUrl,
    setupBody({ password: 'short', confirmPassword: 'short' }),
  );
  assert.equal(shortPassword.status, 400);
  const mismatch = await postSetup(
    baseUrl,
    setupBody({ confirmPassword: 'a-different-test-password' }),
  );
  assert.equal(mismatch.status, 400);
  assert.equal(harness.users.length, 0);
});

test('first-admin setup refuses duplicate account email without changing that user', async () => {
  const existingUser = {
    _id: new ObjectId(),
    fullName: 'Regular User',
    username: 'regular_user',
    email: 'new-admin@example.test',
    passwordHash: '$argon2id$existing-test-hash',
    role: 'user',
  };
  const harness = createHarness({ users: [existingUser] });
  const baseUrl = await startServer(harness);

  const response = await postSetup(baseUrl, setupBody());

  assert.equal(response.status, 409);
  assert.equal((await response.json()).error.code, 'EMAIL_ALREADY_EXISTS');
  assert.deepEqual(harness.users, [existingUser]);
  assert.equal(harness.markers.length, 0);
});

test('concurrent first-admin setup requests create at most one administrator', async () => {
  const harness = createHarness();
  const baseUrl = await startServer(harness);

  const [first, second] = await Promise.all([
    postSetup(baseUrl, setupBody()),
    postSetup(baseUrl, setupBody({
      fullName: 'Second Admin',
      username: 'second_admin',
      email: 'second-admin@example.test',
    })),
  ]);
  const statuses = [first.status, second.status].sort();

  assert.deepEqual(statuses, [201, 409]);
  assert.equal(harness.users.filter((user) => user.role === 'admin').length, 1);
  assert.equal(harness.markers.length, 1);
});
