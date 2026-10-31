const assert = require('node:assert/strict');
const { after, before, test } = require('node:test');
const { createApp } = require('../src/app');
const { getConnectionFailureReason } = require('../src/db/mongo');

let server;
let baseUrl;

before(async () => {
  server = createApp({
    checkDatabase: async () => {},
  }).listen(0, '127.0.0.1');

  await new Promise((resolve) => server.once('listening', resolve));
  baseUrl = `http://127.0.0.1:${server.address().port}`;
});

after(async () => {
  await new Promise((resolve, reject) => {
    server.close((error) => (error ? reject(error) : resolve()));
  });
});

test('GET /health reports application liveness', async () => {
  const response = await fetch(`${baseUrl}/health`);

  assert.equal(response.status, 200);
  assert.deepEqual(await response.json(), { status: 'ok' });
});

test('GET /health/database reports connectivity without connection details', async () => {
  const response = await fetch(`${baseUrl}/health/database`);
  const body = await response.json();

  assert.equal(response.status, 200);
  assert.deepEqual(body, { status: 'ok', database: 'connected' });
  assert.equal(JSON.stringify(body).includes('mongodb'), false);
});

test('GET /health/database returns a safe unavailable response on failure', async () => {
  const app = createApp({
    checkDatabase: async () => {
      throw new Error('sensitive database connection details');
    },
  });
  const failingServer = app.listen(0, '127.0.0.1');
  await new Promise((resolve) => failingServer.once('listening', resolve));

  try {
    const response = await fetch(
      `http://127.0.0.1:${failingServer.address().port}/health/database`,
    );

    assert.equal(response.status, 503);
    assert.deepEqual(await response.json(), {
      error: { message: 'Database is unavailable.' },
    });
  } finally {
    await new Promise((resolve, reject) => {
      failingServer.close((error) => (error ? reject(error) : resolve()));
    });
  }
});

test('unknown health checks are rejected by request validation', async () => {
  const response = await fetch(`${baseUrl}/health/credentials`);

  assert.equal(response.status, 400);
  assert.deepEqual(await response.json(), {
    error: { message: 'Unsupported health check.' },
  });
});

test('unknown routes return a not-found response', async () => {
  const response = await fetch(`${baseUrl}/not-a-route`);

  assert.equal(response.status, 404);
  assert.deepEqual(await response.json(), {
    error: { message: 'Route not found.' },
  });
});

test('malformed JSON receives a safe validation error', async () => {
  const response = await fetch(`${baseUrl}/not-a-route`, {
    method: 'POST',
    headers: { 'content-type': 'application/json' },
    body: '{"invalid"',
  });

  assert.equal(response.status, 400);
  assert.deepEqual(await response.json(), {
    error: { message: 'Request body must contain valid JSON.' },
  });
});

test('MongoDB connection diagnostics identify authentication failure without leaking errors', () => {
  const error = new Error(
    'MongoDB server returned password=sensitive-value and mongodb+srv://secret',
  );
  error.name = 'MongoServerSelectionError';
  error.reason = {
    servers: new Map([
      [
        'cluster.example.invalid',
        Object.assign(new Error('authentication failed'), {
          error: Object.assign(new Error('authentication failed'), {
            code: 18,
            codeName: 'AuthenticationFailed',
          }),
        }),
      ],
    ]),
  };

  const diagnostic = getConnectionFailureReason(error);

  assert.match(diagnostic, /authentication failed/i);
  assert.equal(diagnostic.includes('sensitive-value'), false);
  assert.equal(diagnostic.includes('mongodb+srv://'), false);
});

test('MongoDB connection diagnostics identify missing database permissions', () => {
  const error = Object.assign(new Error('not authorized'), {
    code: 13,
    codeName: 'Unauthorized',
  });

  assert.match(getConnectionFailureReason(error), /database user roles and permissions/i);
});
