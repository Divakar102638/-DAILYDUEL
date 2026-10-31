const assert = require('node:assert/strict');
const { after, test } = require('node:test');
const { createApp } = require('../src/app');
const { parseCorsOrigins } = require('../src/config');

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

async function startTestServer(allowedOrigins = []) {
  const server = createApp({
    allowedOrigins,
    checkDatabase: async () => {},
  }).listen(0, '127.0.0.1');
  servers.add(server);
  await new Promise((resolve) => server.once('listening', resolve));
  return `http://127.0.0.1:${server.address().port}`;
}

test('configured web origins receive restrictive CORS headers', async () => {
  const origin = 'https://app.example.test';
  const baseUrl = await startTestServer([origin]);
  const response = await fetch(`${baseUrl}/health`, {
    headers: { Origin: origin },
  });

  assert.equal(response.status, 200);
  assert.equal(response.headers.get('access-control-allow-origin'), origin);
  assert.match(response.headers.get('vary'), /Origin/i);
});

test('CORS preflight allows only the configured origin', async () => {
  const origin = 'https://app.example.test';
  const baseUrl = await startTestServer([origin]);
  const response = await fetch(`${baseUrl}/api/v1/auth/register`, {
    method: 'OPTIONS',
    headers: {
      Origin: origin,
      'Access-Control-Request-Method': 'POST',
      'Access-Control-Request-Headers': 'content-type',
    },
  });

  assert.equal(response.status, 204);
  assert.equal(response.headers.get('access-control-allow-origin'), origin);
  assert.equal(
    response.headers.get('access-control-allow-methods'),
    'GET, POST, OPTIONS',
  );
});

test('disallowed web origins are rejected', async () => {
  const baseUrl = await startTestServer(['https://app.example.test']);
  const response = await fetch(`${baseUrl}/health`, {
    headers: { Origin: 'https://untrusted.example.test' },
  });

  assert.equal(response.status, 403);
  assert.equal(response.headers.get('access-control-allow-origin'), null);
});

test('requests without browser origins remain available to native clients', async () => {
  const baseUrl = await startTestServer(['https://app.example.test']);
  const response = await fetch(`${baseUrl}/health`);

  assert.equal(response.status, 200);
  assert.equal(response.headers.get('access-control-allow-origin'), null);
});

test('CORS configuration accepts exact origins and rejects wildcards or paths', () => {
  assert.deepEqual(
    parseCorsOrigins('https://app.example.test, http://localhost:5000'),
    ['https://app.example.test', 'http://localhost:5000'],
  );
  assert.throws(() => parseCorsOrigins('*'), /valid web origins/);
  assert.throws(
    () => parseCorsOrigins('https://app.example.test/path'),
    /exact HTTP or HTTPS origins/,
  );
});
