const express = require('express');
const { pingMongo } = require('./db/mongo');
const { createCorsMiddleware } = require('./middleware/cors');
const { createAuthRouter } = require('./routes/auth');
const { errorHandler, notFoundHandler } = require('./middleware/error-handler');
const { createHealthRouter } = require('./routes/health');

function createApp({
  checkDatabase = pingMongo,
  allowedOrigins = [],
  authTokenSecret = process.env.AUTH_TOKEN_SECRET,
  usersCollection,
  hashPassword,
  verifyPassword,
  registrationLimiter,
  loginLimiter,
} = {}) {
  const app = express();

  app.disable('x-powered-by');
  app.set('trust proxy', 1);
  app.use(createCorsMiddleware(allowedOrigins));
  app.use(express.json({ limit: '16kb' }));
  app.use('/health', createHealthRouter({ checkDatabase }));
  app.use(
    '/api/v1/auth',
    createAuthRouter({
      usersCollection,
      hashPassword,
      verifyPassword,
      authTokenSecret,
      registrationLimiter,
      loginLimiter,
    }),
  );
  app.use(notFoundHandler);
  app.use(errorHandler);

  return app;
}

module.exports = { createApp };
