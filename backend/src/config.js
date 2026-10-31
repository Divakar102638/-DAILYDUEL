const path = require('node:path');
const dotenv = require('dotenv');

const envPath = path.resolve(__dirname, '..', '.env');

function parseCorsOrigins(value = '') {
  return (value || '')
    .split(',')
    .map((origin) => origin.trim())
    .filter(Boolean)
    .map((origin) => {
      let parsed;
      try {
        parsed = new URL(origin);
      } catch {
        throw new Error('CORS_ORIGINS must contain valid web origins.');
      }

      if (
        !['http:', 'https:'].includes(parsed.protocol) ||
        parsed.origin !== origin
      ) {
        throw new Error(
          'CORS_ORIGINS must contain exact HTTP or HTTPS origins without paths.',
        );
      }

      return parsed.origin;
    });
}

function loadConfig() {
  dotenv.config({ path: envPath });

  const uri = process.env.MONGODB_URI;
  if (!uri) {
    throw new Error(
      'MONGODB_URI is required. Set it in backend/.env using backend/.env.example.',
    );
  }

  const authTokenSecret = process.env.AUTH_TOKEN_SECRET;
  if (!authTokenSecret || Buffer.byteLength(authTokenSecret, 'utf8') < 32) {
    throw new Error(
      'AUTH_TOKEN_SECRET is required and must be at least 32 bytes. Configure it in the backend environment.',
    );
  }

  const host = process.env.HOST || '0.0.0.0';
  const port = Number(process.env.PORT || 3000);
  if (!Number.isInteger(port) || port < 1 || port > 65535) {
    throw new Error('PORT must be an integer between 1 and 65535.');
  }

  const corsOrigins = parseCorsOrigins(process.env.CORS_ORIGINS);

  return { host, port, uri, corsOrigins, authTokenSecret };
}

module.exports = { envPath, loadConfig, parseCorsOrigins };
