const express = require('express');
const { pingMongo } = require('./db/mongo');
const { errorHandler, notFoundHandler } = require('./middleware/error-handler');
const { createHealthRouter } = require('./routes/health');

function createApp({ checkDatabase = pingMongo } = {}) {
  const app = express();

  app.disable('x-powered-by');
  app.use(express.json({ limit: '16kb' }));
  app.use('/health', createHealthRouter({ checkDatabase }));
  app.use(notFoundHandler);
  app.use(errorHandler);

  return app;
}

module.exports = { createApp };
