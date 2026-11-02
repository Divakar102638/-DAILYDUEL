const express = require('express');
const { getDatabase, pingMongo } = require('./db/mongo');
const { createCorsMiddleware } = require('./middleware/cors');
const { createAuthRouter } = require('./routes/auth');
const { createAdminRouter } = require('./routes/admin');
const { createQuizRouter } = require('./routes/quizzes');
const { createAdminQuizRouter } = require('./routes/admin-quizzes');
const { createExamRouter } = require('./routes/exams');
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
  database = getDatabase,
  now = () => new Date(),
} = {}) {
  const app = express();

  app.disable('x-powered-by');
  app.set('trust proxy', 1);
  app.use(createCorsMiddleware(allowedOrigins));
  app.use(express.json({ limit: '1mb' }));
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
  app.use(
    '/api/v1/admin',
    createAdminRouter({ usersCollection, authTokenSecret }),
  );
  const getCollection = (name) => database().collection(name);
  app.use(
    '/api/v1/quizzes',
    createQuizRouter({
      usersCollection,
      authTokenSecret,
      getCollection,
      now,
    }),
  );
  app.use(
    '/api/v1/admin/quizzes',
    createAdminQuizRouter({
      usersCollection,
      authTokenSecret,
      getCollection,
      now,
    }),
  );
  app.use(
    '/api/v1/exams',
    createExamRouter({
      usersCollection,
      authTokenSecret,
      getCollection,
      now,
    }),
  );
  app.use(notFoundHandler);
  app.use(errorHandler);

  return app;
}

module.exports = { createApp };
