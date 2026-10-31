const express = require('express');

function createHealthRouter({ checkDatabase }) {
  const router = express.Router();

  router.get('/', (_request, response) => {
    response.status(200).json({ status: 'ok' });
  });

  router.get('/:component', async (request, response, next) => {
    if (request.params.component !== 'database') {
      const error = new Error('Unsupported health check.');
      error.status = 400;
      next(error);
      return;
    }

    try {
      await checkDatabase();
      response.status(200).json({
        status: 'ok',
        database: 'connected',
      });
    } catch {
      const error = new Error('Database is unavailable.');
      error.status = 503;
      next(error);
    }
  });

  return router;
}

module.exports = { createHealthRouter };
