const { createApp } = require('./app');
const { loadConfig } = require('./config');
const {
  closeMongo,
  connectMongo,
  getConnectionFailureReason,
} = require('./db/mongo');

async function startServer() {
  const { host, port, uri, corsOrigins, authTokenSecret } = loadConfig();
  await connectMongo(uri);

  let server;
  try {
    server = await new Promise((resolve, reject) => {
      const appServer = createApp({
        allowedOrigins: corsOrigins,
        authTokenSecret,
      }).listen(port, host, () => resolve(appServer));
      appServer.once('error', reject);
    });
  } catch (error) {
    await closeMongo();
    throw error;
  }

  console.log(`DailyDuel backend listening at http://${host}:${port}`);

  let isClosing = false;
  const shutdown = () => {
    if (isClosing) {
      return;
    }
    isClosing = true;

    server.close(async () => {
      try {
        await closeMongo();
        process.exitCode = 0;
      } catch {
        console.error('MongoDB connection could not be closed cleanly.');
        process.exitCode = 1;
      }
    });
  };

  process.once('SIGINT', shutdown);
  process.once('SIGTERM', shutdown);

  return server;
}

if (require.main === module) {
  startServer().catch((error) => {
    const reason = error.cause
      ? getConnectionFailureReason(error)
      : error.message;
    console.error(`DailyDuel backend failed to start: ${reason}`);
    process.exitCode = 1;
  });
}

module.exports = { startServer };
