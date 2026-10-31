const assert = require('node:assert/strict');
const argon2 = require('argon2');
const jwt = require('jsonwebtoken');
const { ObjectId } = require('mongodb');
const { after, test } = require('node:test');
const { createApp } = require('../src/app');
const { createRegistrationLimiter } = require('../src/routes/auth');

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

function createUsersCollection({ indexError, insertError } = {}) {
  const indexes = [];
  const insertedUsers = [];
  return {
    indexes,
    insertedUsers,
    async createIndex(keys, options) {
      if (indexError) {
        throw indexError;
      }
      indexes.push({ keys, options });
      return options.name;
    },
    async insertOne(user) {
      if (insertError) {
        throw insertError;
      }
      const insertedId = new ObjectId();
      insertedUsers.push({ ...user, _id: insertedId });
      return { insertedId };
    },
  };
}

async function postRegistration(collection, body) {
  const server = createApp({
    checkDatabase: async () => {},
    usersCollection: () => collection,
  }).listen(0, '127.0.0.1');
  servers.add(server);
  await new Promise((resolve) => server.once('listening', resolve));

  const response = await fetch(
    `http://127.0.0.1:${server.address().port}/api/v1/auth/register`,
    {
      method: 'POST',
      headers: { 'content-type': 'application/json' },
      body: JSON.stringify(body),
    },
  );

  return { response, server };
}

async function startRegistrationServer(collection) {
  const server = createApp({
    checkDatabase: async () => {},
    usersCollection: () => collection,
  }).listen(0, '127.0.0.1');
  servers.add(server);
  await new Promise((resolve) => server.once('listening', resolve));

  return {
    server,
    url: `http://127.0.0.1:${server.address().port}/api/v1/auth/register`,
  };
}

async function sendRegistration(url, body) {
  return fetch(url, {
    method: 'POST',
    headers: { 'content-type': 'application/json' },
    body: JSON.stringify(body),
  });
}

const validRegistration = {
  fullName: 'Dedicated Registration Test',
  username: `test_${Date.now().toString().slice(-10)}`,
  email: `registration-${Date.now()}@example.test`,
  password: 'a dedicated test password',
};
const testTokenSecret = 'test-only-auth-token-secret-at-least-32-bytes';

async function postLogin(collection, body, options = {}) {
  const server = createApp({
    checkDatabase: async () => {},
    usersCollection: () => collection,
    authTokenSecret: testTokenSecret,
    ...options,
  }).listen(0, '127.0.0.1');
  servers.add(server);
  await new Promise((resolve) => server.once('listening', resolve));

  const response = await fetch(
    `http://127.0.0.1:${server.address().port}/api/v1/auth/login`,
    {
      method: 'POST',
      headers: { 'content-type': 'application/json' },
      body: JSON.stringify(body),
    },
  );
  return { response, server };
}

test('registration stores a normalized user with an Argon2id hash and safe response', async () => {
  const collection = createUsersCollection();
  const { response } = await postRegistration(collection, {
    ...validRegistration,
    email: `  ${validRegistration.email.toUpperCase()}  `,
    username: `  ${validRegistration.username.toUpperCase()}  `,
  });
  const body = await response.json();

  assert.equal(response.status, 201);
  assert.equal(body.user.fullName, validRegistration.fullName);
  assert.equal(body.user.username, validRegistration.username.toLowerCase());
  assert.equal(body.user.email, validRegistration.email.toLowerCase());
  assert.equal(typeof body.user.id, 'string');
  assert.equal(JSON.stringify(body).includes('password'), false);
  assert.equal(JSON.stringify(body).includes('passwordHash'), false);

  assert.equal(collection.insertedUsers.length, 1);
  const [storedUser] = collection.insertedUsers;
  assert.equal(storedUser.email, validRegistration.email.toLowerCase());
  assert.notEqual(storedUser.passwordHash, validRegistration.password);
  assert.equal(
    await argon2.verify(storedUser.passwordHash, validRegistration.password),
    true,
  );
  assert.equal(argon2.needsRehash(storedUser.passwordHash), false);
  assert.deepEqual(
    collection.indexes.map(({ keys, options }) => ({
      keys,
      unique: options.unique,
    })),
    [
      { keys: { email: 1 }, unique: true },
      { keys: { username: 1 }, unique: true },
    ],
  );
});

test('login rejects an unknown email without inserting a user', async () => {
  const collection = createUsersCollection();
  collection.findOne = async () => null;
  const { response } = await postLogin(collection, {
    email: 'unknown@example.test',
    password: 'a valid-looking password',
  });

  assert.equal(response.status, 401);
  assert.deepEqual(await response.json(), {
    error: {
      code: 'INVALID_CREDENTIALS',
      message: 'Invalid email or password.',
    },
  });
  assert.equal(collection.insertedUsers.length, 0);
});

test('login rejects a wrong password with the same safe response', async () => {
  const user = {
    _id: new ObjectId(),
    fullName: 'Registered User',
    username: 'registered_user',
    email: 'registered@example.test',
    passwordHash: '$argon2id$stored-hash',
  };
  const collection = createUsersCollection();
  collection.findOne = async (query) => {
    assert.deepEqual(query, { email: user.email });
    return user;
  };
  const { response } = await postLogin(
    collection,
    { email: ' REGISTERED@example.test ', password: 'wrong password' },
    { verifyPassword: async () => false },
  );

  assert.equal(response.status, 401);
  assert.deepEqual(await response.json(), {
    error: {
      code: 'INVALID_CREDENTIALS',
      message: 'Invalid email or password.',
    },
  });
});

test('login database failures return a generic error without internal details', async () => {
  const collection = createUsersCollection();
  collection.findOne = async () => {
    throw new Error('private database connection detail');
  };
  const { response } = await postLogin(collection, {
    email: 'registered@example.test',
    password: 'a valid-looking password',
  });
  const body = await response.json();

  assert.equal(response.status, 500);
  assert.equal(body.error.message, 'An unexpected server error occurred.');
  assert.equal(JSON.stringify(body).includes('private database'), false);
});

test('login verifies Argon2id and returns a short-lived signed token without the hash', async () => {
  const password = "registered user's correct password";
  const user = {
    _id: new ObjectId(),
    fullName: 'Registered User',
    username: 'registered_user',
    email: 'registered@example.test',
    passwordHash: await argon2.hash(password, { type: argon2.argon2id }),
  };
  const collection = createUsersCollection();
  collection.findOne = async (query) => {
    assert.deepEqual(query, { email: user.email });
    return user;
  };
  const { response } = await postLogin(collection, {
    email: ' REGISTERED@example.test ',
    password,
  });
  const body = await response.json();

  assert.equal(response.status, 200);
  assert.deepEqual(body.user, {
    id: user._id.toString(),
    fullName: user.fullName,
    username: user.username,
    email: user.email,
  });
  assert.equal(JSON.stringify(body).includes('passwordHash'), false);
  const claims = jwt.verify(body.token, testTokenSecret, {
    algorithms: ['HS256'],
    audience: 'dailyduel-app',
    issuer: 'dailyduel-api',
  });
  assert.equal(claims.sub, user._id.toString());
  assert.equal(claims.exp - claims.iat, 3600);
  assert.equal(collection.insertedUsers.length, 0);
});

test('a successfully registered user can log in with the stored Argon2id hash', async () => {
  const collection = createUsersCollection();
  collection.findOne = async (query) =>
    collection.insertedUsers.find(
      (user) =>
        user.email === query.email ||
        user._id.toString() === query._id?.toString(),
    ) || null;

  const registration = await postRegistration(collection, validRegistration);
  assert.equal(registration.response.status, 201);

  const login = await postLogin(collection, {
    email: validRegistration.email.toUpperCase(),
    password: validRegistration.password,
  });
  const responseBody = await login.response.json();

  assert.equal(login.response.status, 200);
  assert.equal(responseBody.user.email, validRegistration.email);
  assert.equal(collection.insertedUsers.length, 1);
});

test('session endpoint requires and verifies a bearer token against MongoDB', async () => {
  const user = {
    _id: new ObjectId(),
    fullName: 'Registered User',
    username: 'registered_user',
    email: 'registered@example.test',
    passwordHash: 'never-returned',
  };
  const collection = createUsersCollection();
  collection.findOne = async (query) =>
    query._id.toString() === user._id.toString() ? user : null;
  const server = createApp({
    checkDatabase: async () => {},
    usersCollection: () => collection,
    authTokenSecret: testTokenSecret,
  }).listen(0, '127.0.0.1');
  servers.add(server);
  await new Promise((resolve) => server.once('listening', resolve));
  const url = `http://127.0.0.1:${server.address().port}/api/v1/auth/session`;

  const unauthorized = await fetch(url);
  assert.equal(unauthorized.status, 401);

  const token = jwt.sign({}, testTokenSecret, {
    algorithm: 'HS256',
    audience: 'dailyduel-app',
    expiresIn: '1h',
    issuer: 'dailyduel-api',
    subject: user._id.toString(),
  });
  const authorized = await fetch(url, {
    headers: { authorization: `Bearer ${token}` },
  });
  assert.equal(authorized.status, 200);
  assert.deepEqual(await authorized.json(), {
    user: {
      id: user._id.toString(),
      fullName: user.fullName,
      username: user.username,
      email: user.email,
    },
  });

  const expiredToken = jwt.sign({}, testTokenSecret, {
    algorithm: 'HS256',
    audience: 'dailyduel-app',
    expiresIn: '-1s',
    issuer: 'dailyduel-api',
    subject: user._id.toString(),
  });
  const expired = await fetch(url, {
    headers: { authorization: `Bearer ${expiredToken}` },
  });
  assert.equal(expired.status, 401);
});

test('registration rejects invalid fields before database writes', async () => {
  const invalidCases = [
    { ...validRegistration, fullName: ' ' },
    { ...validRegistration, username: 'no spaces' },
    { ...validRegistration, email: 'invalid-email' },
    { ...validRegistration, password: 'short' },
    { ...validRegistration, password: 'a'.repeat(129) },
  ];

  for (const body of invalidCases) {
    const collection = createUsersCollection();
    const { response } = await postRegistration(collection, body);
    const result = await response.json();

    assert.equal(response.status, 400);
    assert.equal(result.error.code, 'VALIDATION_ERROR');
    assert.equal(collection.insertedUsers.length, 0);
    assert.equal(collection.indexes.length, 0);
  }
});

test('registration reports duplicate emails safely', async () => {
  const collection = createUsersCollection({
    insertError: Object.assign(new Error('private database details'), {
      code: 11000,
      keyPattern: { email: 1 },
    }),
  });
  const { response } = await postRegistration(collection, validRegistration);
  const body = await response.json();

  assert.equal(response.status, 409);
  assert.deepEqual(body, {
    error: {
      code: 'EMAIL_ALREADY_EXISTS',
      message: 'An account with this email already exists.',
    },
  });
  assert.equal(JSON.stringify(body).includes('private database details'), false);
});

test('registration reports duplicate usernames safely', async () => {
  const collection = createUsersCollection({
    insertError: Object.assign(new Error('private database details'), {
      code: 11000,
      keyPattern: { username: 1 },
    }),
  });
  const { response } = await postRegistration(collection, validRegistration);
  const body = await response.json();

  assert.equal(response.status, 409);
  assert.equal(body.error.code, 'USERNAME_TAKEN');
});

test('concurrent duplicate registrations are serialized by unique indexes', async () => {
  const indexes = [];
  const users = [];
  let indexCreations = 0;
  let indexesReady = false;
  const collection = {
    async createIndex(keys, options) {
      await new Promise((resolve) => setTimeout(resolve, 5));
      indexes.push({ keys, options });
      indexCreations += 1;
      indexesReady = indexCreations === 2;
      return options.name;
    },
    async insertOne(user) {
      assert.equal(indexesReady, true);
      const duplicateField = users.some((existing) => existing.email === user.email)
        ? 'email'
        : users.some((existing) => existing.username === user.username)
          ? 'username'
          : null;

      if (duplicateField) {
        throw Object.assign(new Error('duplicate key'), {
          code: 11000,
          keyPattern: { [duplicateField]: 1 },
        });
      }

      users.push(user);
      return { insertedId: new ObjectId() };
    },
  };

  const { url } = await startRegistrationServer(collection);
  const responses = await Promise.all([
    sendRegistration(url, validRegistration),
    sendRegistration(url, validRegistration),
  ]);
  const statuses = responses.map((response) => response.status).sort();

  assert.deepEqual(statuses, [201, 409]);
  assert.equal(users.length, 1);
  assert.equal(indexesReady, true);
  assert.equal(indexCreations, 2);
});

test('failed index initialization can be retried on a later registration', async () => {
  let failuresRemaining = 1;
  const collection = createUsersCollection();
  const createIndex = collection.createIndex.bind(collection);
  collection.createIndex = async (...args) => {
    if (failuresRemaining > 0) {
      failuresRemaining -= 1;
      throw new Error('temporary index initialization failure');
    }

    return createIndex(...args);
  };
  const { url } = await startRegistrationServer(collection);

  const first = await sendRegistration(url, validRegistration);
  const second = await sendRegistration(url, validRegistration);

  assert.equal(first.status, 500);
  assert.equal(second.status, 201);
  assert.equal(collection.insertedUsers.length, 1);
});

test('database index failures return a generic server error', async () => {
  const collection = createUsersCollection({
    indexError: Object.assign(new Error('private index details'), {
      code: 11000,
    }),
  });
  const { response } = await postRegistration(collection, validRegistration);
  const body = await response.json();

  assert.equal(response.status, 500);
  assert.equal(body.error.message, 'An unexpected server error occurred.');
  assert.equal(JSON.stringify(body).includes('private index details'), false);
  assert.equal(collection.insertedUsers.length, 0);
});

test('registration attempts are rate limited with a safe response', async () => {
  const collection = createUsersCollection();
  const server = createApp({
    checkDatabase: async () => {},
    usersCollection: () => collection,
    hashPassword: async () => 'test-hash',
    registrationLimiter: createRegistrationLimiter({
      limit: 2,
      windowMs: 60_000,
    }),
  }).listen(0, '127.0.0.1');
  servers.add(server);
  await new Promise((resolve) => server.once('listening', resolve));

  const url = `http://127.0.0.1:${server.address().port}/api/v1/auth/register`;
  const request = () =>
    fetch(url, {
      method: 'POST',
      headers: { 'content-type': 'application/json' },
      body: JSON.stringify(validRegistration),
    });

  assert.equal((await request()).status, 201);
  assert.equal((await request()).status, 201);
  const limited = await request();

  assert.equal(limited.status, 429);
  assert.deepEqual(await limited.json(), {
    error: {
      code: 'RATE_LIMITED',
      message: 'Too many registration attempts. Please wait and try again.',
    },
  });
});
