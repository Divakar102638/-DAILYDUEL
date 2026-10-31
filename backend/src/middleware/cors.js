function createCorsMiddleware(allowedOrigins = []) {
  const allowed = new Set(allowedOrigins);

  return (request, response, next) => {
    const origin = request.get('Origin');
    if (!origin) {
      next();
      return;
    }

    if (!allowed.has(origin)) {
      response.status(403).json({
        error: {
          message: 'This origin is not allowed.',
        },
      });
      return;
    }

    response.vary('Origin');
    response.set('Access-Control-Allow-Origin', origin);
    response.set('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
    response.set('Access-Control-Allow-Headers', 'Accept, Content-Type');

    if (request.method === 'OPTIONS') {
      response.status(204).end();
      return;
    }

    next();
  };
}

module.exports = { createCorsMiddleware };
