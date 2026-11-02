const argon2 = require('argon2');
const express = require('express');
const { rateLimit } = require('express-rate-limit');
const jwt = require('jsonwebtoken');
const { getUsersCollection } = require('../db/mongo');
const {
  createAuthMiddleware,
  isAccountDisabled,
  toSafeUser,
} = require('../middleware/auth');

const emailPattern = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
const usernamePattern = /^[a-z0-9_]{3,20}$/;

function createAuthRouter({
  usersCollection = getUsersCollection,
  hashPassword = (password) =>
    argon2.hash(password, { type: argon2.argon2id }),
  verifyPassword = (password, passwordHash) =>
    argon2.verify(passwordHash, password),
  authTokenSecret = process.env.AUTH_TOKEN_SECRET,
  registrationLimiter = createRegistrationLimiter(),
  loginLimiter = createLoginLimiter(),
} = {}) {
  const router = express.Router();
  const authenticate = createAuthMiddleware({
    usersCollection,
    authTokenSecret,
  });
  let indexesPromise;

  async function ensureUserIndexes(collection) {
    if (!indexesPromise) {
      indexesPromise = Promise.all([
        collection.createIndex(
          { email: 1 },
          { unique: true, name: 'users_email_unique' },
        ),
        collection.createIndex(
          { username: 1 },
          { unique: true, name: 'users_username_unique' },
        ),
      ]);
    }

    try {
      await indexesPromise;
    } catch (error) {
      indexesPromise = undefined;
      throw error;
    }
  }

  function respondToDuplicate(response, error) {
    const duplicateFields = Object.keys(error.keyPattern || {});
    const code = duplicateFields.includes('email')
      ? 'EMAIL_ALREADY_EXISTS'
      : duplicateFields.includes('username')
        ? 'USERNAME_TAKEN'
        : 'ACCOUNT_ALREADY_EXISTS';
    const message = {
      EMAIL_ALREADY_EXISTS: 'An account with this email already exists.',
      USERNAME_TAKEN: 'Username is already taken. Please choose another.',
      ACCOUNT_ALREADY_EXISTS:
        'An account with these registration details already exists.',
    }[code];

    response.status(409).json({ error: { code, message } });
  }

  router.post(
    '/register',
    registrationLimiter,
    async (request, response, next) => {
      const body = request.body;
      if (!body || typeof body !== 'object' || Array.isArray(body)) {
        response.status(400).json({
          error: {
            code: 'VALIDATION_ERROR',
            message: 'A JSON object with registration details is required.',
          },
        });
        return;
      }

      const { fullName, username, email, password } = body;
      if (
        typeof fullName !== 'string' ||
        fullName.trim().length < 2 ||
        fullName.trim().length > 80
      ) {
        response.status(400).json({
          error: {
            code: 'VALIDATION_ERROR',
            message: 'Full name must be between 2 and 80 characters.',
          },
        });
        return;
      }

      if (typeof username !== 'string') {
        response.status(400).json({
          error: {
            code: 'VALIDATION_ERROR',
            message:
              'Username must be 3 to 20 letters, numbers, or underscores.',
          },
        });
        return;
      }

      const normalizedUsername = username.trim().toLowerCase();
      if (!usernamePattern.test(normalizedUsername)) {
        response.status(400).json({
          error: {
            code: 'VALIDATION_ERROR',
            message:
              'Username must be 3 to 20 letters, numbers, or underscores.',
          },
        });
        return;
      }

      if (
        typeof email !== 'string' ||
        email.trim().length > 254 ||
        !emailPattern.test(email.trim())
      ) {
        response.status(400).json({
          error: {
            code: 'VALIDATION_ERROR',
            message: 'Enter a valid email address.',
          },
        });
        return;
      }

      if (
        typeof password !== 'string' ||
        password.length < 8 ||
        password.length > 128
      ) {
        response.status(400).json({
          error: {
            code: 'VALIDATION_ERROR',
            message: 'Password must be between 8 and 128 characters.',
          },
        });
        return;
      }

      const normalizedEmail = email.trim().toLowerCase();
      let collection;
      let passwordHash;
      try {
        collection = usersCollection();
        await ensureUserIndexes(collection);
        passwordHash = await hashPassword(password);
      } catch (error) {
        next(error);
        return;
      }

      const user = {
        fullName: fullName.trim(),
        username: normalizedUsername,
        email: normalizedEmail,
        passwordHash,
        role: 'user',
        createdAt: new Date(),
      };

      let result;
      try {
        result = await collection.insertOne(user);
      } catch (error) {
        if (error && error.code === 11000) {
          respondToDuplicate(response, error);
          return;
        }

        next(error);
        return;
      }

      response.status(201).json({
        user: {
          id: result.insertedId.toString(),
          fullName: user.fullName,
          username: user.username,
          email: user.email,
        },
      });
    },
  );

  router.post(
    '/login',
    loginLimiter,
    async (request, response, next) => {
      const { email, password } = request.body || {};
      if (
        typeof email !== 'string' ||
        email.trim().length > 254 ||
        !emailPattern.test(email.trim()) ||
        typeof password !== 'string' ||
        password.length < 1 ||
        password.length > 128
      ) {
        response.status(400).json({
          error: {
            code: 'VALIDATION_ERROR',
            message: 'Enter a valid email address and password.',
          },
        });
        return;
      }

      if (!authTokenSecret || Buffer.byteLength(authTokenSecret, 'utf8') < 32) {
        next(new Error('Authentication is temporarily unavailable.'));
        return;
      }

      let user;
      let passwordIsValid = false;
      try {
        user = await usersCollection().findOne({
          email: email.trim().toLowerCase(),
        });
      } catch (error) {
        next(error);
        return;
      }

      if (
        user &&
        !isAccountDisabled(user) &&
        typeof user.passwordHash === 'string' &&
        user.passwordHash.startsWith('$argon2id$')
      ) {
        try {
          passwordIsValid = await verifyPassword(password, user.passwordHash);
        } catch {
          passwordIsValid = false;
        }
      }

      if (!user || !passwordIsValid || !user._id) {
        response.status(401).json({
          error: {
            code: 'INVALID_CREDENTIALS',
            message: 'Invalid email or password.',
          },
        });
        return;
      }

      const userResponse = toSafeUser(user);
      if (!userResponse) {
        response.status(401).json({
          error: {
            code: 'INVALID_CREDENTIALS',
            message: 'Invalid email or password.',
          },
        });
        return;
      }

      const token = jwt.sign({}, authTokenSecret, {
        algorithm: 'HS256',
        audience: 'dailyduel-app',
        expiresIn: '1h',
        issuer: 'dailyduel-api',
        subject: user._id.toString(),
      });

      response.status(200).json({ token, user: userResponse });
    },
  );

  router.get('/session', authenticate, (request, response) => {
    response.status(200).json({ user: request.authenticatedUser });
  });

  return router;
}

function createRegistrationLimiter({
  limit = 10,
  windowMs = 15 * 60 * 1000,
} = {}) {
  return rateLimit({
    windowMs,
    limit,
    standardHeaders: 'draft-8',
    legacyHeaders: false,
    handler(_request, response) {
      response.status(429).json({
        error: {
          code: 'RATE_LIMITED',
          message: 'Too many registration attempts. Please wait and try again.',
        },
      });
    },
  });
}

function createLoginLimiter({
  limit = 10,
  windowMs = 15 * 60 * 1000,
} = {}) {
  return rateLimit({
    windowMs,
    limit,
    standardHeaders: 'draft-8',
    legacyHeaders: false,
    handler(_request, response) {
      response.status(429).json({
        error: {
          code: 'RATE_LIMITED',
          message: 'Too many login attempts. Please wait and try again.',
        },
      });
    },
  });
}

module.exports = {
  createAuthRouter,
  createLoginLimiter,
  createRegistrationLimiter,
};
