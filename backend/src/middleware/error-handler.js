function notFoundHandler(_request, response) {
  response.status(404).json({
    error: {
      message: 'Route not found.',
    },
  });
}

function errorHandler(error, request, response, _next) {
  if (response.headersSent) {
    return;
  }

  if (error.type === 'entity.parse.failed') {
    response.status(400).json({
      error: {
        message: 'Request body must contain valid JSON.',
      },
    });
    return;
  }

  if (error.type === 'entity.too.large') {
    response.status(413).json({
      error: {
        message: 'Request body is too large.',
      },
    });
    return;
  }

  const status = Number.isInteger(error.status) ? error.status : 500;
  if (status >= 500) {
    console.error('Request failed.', {
      method: request.method,
      path: request.path,
    });
  }

  response.status(status).json({
    error: {
      message:
        status === 503
          ? 'Database is unavailable.'
          : status >= 500
            ? 'An unexpected server error occurred.'
            : error.message,
    },
  });
}

module.exports = { errorHandler, notFoundHandler };
