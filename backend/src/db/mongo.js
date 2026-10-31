const { MongoClient } = require('mongodb');

let client;

function getConnectionFailureReason(error) {
  const pending = [error];
  const visited = new Set();
  const errors = [];

  while (pending.length > 0) {
    const current = pending.pop();
    if (!current || typeof current !== 'object' || visited.has(current)) {
      continue;
    }

    visited.add(current);
    errors.push(current);

    for (const key of [
      'cause',
      'error',
      'errorResponse',
      'reason',
      'serverDescription',
      'topologyDescription',
    ]) {
      const nested = current[key];
      if (nested && typeof nested === 'object') {
        pending.push(nested);
      }
    }

    const servers = current.servers;
    if (servers instanceof Map) {
      pending.push(...servers.values());
    }
  }

  if (
    errors.some(
      (item) =>
        item.name === 'MongoParseError' ||
        item.codeName === 'InvalidConnectionString',
    )
  ) {
    return 'invalid connection string; verify its format and URL-encoded credentials.';
  }

  if (
    errors.some(
      (item) =>
        item.code === 18 ||
        item.code === 8000 ||
        item.codeName === 'AuthenticationFailed',
    )
  ) {
    return 'authentication failed; verify the Atlas database username and password.';
  }

  if (
    errors.some(
      (item) => item.code === 13 || item.codeName === 'Unauthorized',
    )
  ) {
    return 'database authorization failed; verify the Atlas database user roles and permissions.';
  }

  if (
    errors.some(
      (item) =>
        item.code === 'ENOTFOUND' ||
        item.code === 'EAI_AGAIN' ||
        item.code === 'ENODATA',
    )
  ) {
    return 'Atlas DNS lookup failed; verify the cluster hostname and SRV DNS access.';
  }

  if (
    errors.some(
      (item) =>
        typeof item.code === 'string' &&
        (item.code.startsWith('CERT_') || item.code.startsWith('ERR_TLS_')),
    )
  ) {
    return 'TLS verification failed; check the system clock and network TLS configuration.';
  }

  return 'server selection timed out; check Atlas Network Access, cluster availability, and network access.';
}

async function connectMongo(uri) {
  let nextClient;

  try {
    nextClient = new MongoClient(uri, {
      serverSelectionTimeoutMS: 5000,
    });
    await nextClient.connect();
    await nextClient.db('admin').command({ ping: 1 });
    client = nextClient;
  } catch (error) {
    if (nextClient) {
      try {
        await nextClient.close();
      } catch {
        throw new Error(
          'MongoDB connection failed and client cleanup was unsuccessful.',
          { cause: error },
        );
      }
    }

    throw new Error(getConnectionFailureReason(error), { cause: error });
  }
}

async function pingMongo() {
  if (!client) {
    throw new Error('MongoDB is not connected.');
  }

  await client.db('admin').command({ ping: 1 });
}

async function closeMongo() {
  const connectedClient = client;
  client = undefined;

  if (connectedClient) {
    await connectedClient.close();
  }
}

module.exports = {
  closeMongo,
  connectMongo,
  getConnectionFailureReason,
  pingMongo,
};
