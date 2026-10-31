const fs = require('node:fs');
const dotenv = require('dotenv');
const { envPath } = require('./config');
const {
  closeMongo,
  connectMongo,
  getConnectionFailureReason,
  pingMongo,
} = require('./db/mongo');

async function verifyAtlas() {
  let isConnected = false;
  let exitCode = 0;

  try {
    const env = dotenv.parse(fs.readFileSync(envPath));
    if (!env.MONGODB_URI) {
      throw new Error(
        'MONGODB_URI is required in backend/.env before checking Atlas.',
      );
    }

    await connectMongo(env.MONGODB_URI);
    isConnected = true;
    await pingMongo();
    console.log('MongoDB Atlas connection verified.');
  } catch (error) {
    console.error(
      `MongoDB Atlas connection failed: ${
        error.cause ? getConnectionFailureReason(error) : error.message
      }`,
    );
    exitCode = 1;
  }

  if (isConnected) {
    try {
      await closeMongo();
    } catch {
      console.error('MongoDB Atlas verification cleanup failed.');
      exitCode = 1;
    }
  }

  process.exitCode = exitCode;
}

if (require.main === module) {
  verifyAtlas();
}

module.exports = { verifyAtlas };
