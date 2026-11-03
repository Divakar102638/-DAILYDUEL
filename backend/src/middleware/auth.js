const jwt = require('jsonwebtoken');
const { ObjectId } = require('mongodb');
const { getUsersCollection } = require('../db/mongo');

const authenticationError = {
  code: 'UNAUTHENTICATED',
  message: 'A valid login session is required.',
};

function toSafeUser(user) {
  if (
    !user?._id ||
    typeof user.fullName !== 'string' ||
    typeof user.username !== 'string' ||
    typeof user.email !== 'string'
  ) {
    return null;
  }

  return {
    id: user._id.toString(),
    fullName: user.fullName,
    username: user.username,
    email: user.email,
    role: user.role === 'admin' ? 'admin' : 'user',
  };
}

function isAccountDisabled(user) {
  return (
    user.disabled === true ||
    user.isDisabled === true ||
    user.disabledAt != null ||
    user.deletedAt != null ||
    user.status === 'disabled' ||
    user.status === 'deleted'
  );
}

function getSessionVersion(user) {
  if (user.sessionVersion === undefined) return 0;
  return Number.isSafeInteger(user.sessionVersion) && user.sessionVersion >= 0
    ? user.sessionVersion
    : null;
}

function createAuthMiddleware({
  usersCollection = getUsersCollection,
  authTokenSecret = process.env.AUTH_TOKEN_SECRET,
} = {}) {
  return async function authenticate(request, response, next) {
    if (!authTokenSecret || Buffer.byteLength(authTokenSecret, 'utf8') < 32) {
      next(new Error('Authentication is temporarily unavailable.'));
      return;
    }

    const authorization = request.get('Authorization') || '';
    const tokenMatch = /^Bearer\s+(\S+)$/i.exec(authorization);
    if (!tokenMatch) {
      response.status(401).json({ error: authenticationError });
      return;
    }

    let subject;
    let tokenSessionVersion;
    try {
      const payload = jwt.verify(tokenMatch[1], authTokenSecret, {
        algorithms: ['HS256'],
        audience: 'dailyduel-app',
        issuer: 'dailyduel-api',
      });
      if (
        !payload ||
        typeof payload === 'string' ||
        typeof payload.sub !== 'string' ||
        !ObjectId.isValid(payload.sub) ||
        (payload.sv !== undefined &&
          (!Number.isSafeInteger(payload.sv) || payload.sv < 0))
      ) {
        response.status(401).json({ error: authenticationError });
        return;
      }
      subject = new ObjectId(payload.sub);
      tokenSessionVersion = payload.sv ?? 0;
    } catch {
      response.status(401).json({ error: authenticationError });
      return;
    }

    try {
      const user = await usersCollection().findOne({ _id: subject });
      const currentSessionVersion = user ? getSessionVersion(user) : null;
      const safeUser =
        user &&
        !isAccountDisabled(user) &&
        currentSessionVersion !== null &&
        currentSessionVersion === tokenSessionVersion
          ? toSafeUser(user)
          : null;
      if (!safeUser) {
        response.status(401).json({ error: authenticationError });
        return;
      }

      request.authenticatedUser = safeUser;
      request.authenticatedSessionVersion = currentSessionVersion;
      next();
    } catch (error) {
      next(error);
    }
  };
}

function requireAdmin(request, response, next) {
  if (!request.authenticatedUser) {
    response.status(401).json({ error: authenticationError });
    return;
  }

  if (request.authenticatedUser.role !== 'admin') {
    response.status(403).json({
      error: {
        code: 'FORBIDDEN',
        message: 'Administrator permissions are required.',
      },
    });
    return;
  }

  next();
}

module.exports = {
  createAuthMiddleware,
  getSessionVersion,
  isAccountDisabled,
  requireAdmin,
  toSafeUser,
};
