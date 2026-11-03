const argon2 = require('argon2');
const express = require('express');
const { rateLimit } = require('express-rate-limit');
const jwt = require('jsonwebtoken');
const { ObjectId } = require('mongodb');
const {
  getDatabase,
  getMongoClient,
  getUsersCollection,
} = require('../db/mongo');
const {
  createAuthMiddleware,
  getSessionVersion,
  isAccountDisabled,
  requireAdmin,
  toSafeUser,
} = require('../middleware/auth');
const {
  BOOTSTRAP_MARKER_ID,
  BootstrapError,
  createFirstAdmin,
  verifyBootstrapSecret,
} = require('../admin/bootstrap');

const emailPattern = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
const usernamePattern = /^[a-z0-9_]{3,20}$/;

function createAuthRouter({
  usersCollection = getUsersCollection,
  hashPassword = (password) =>
    argon2.hash(password, { type: argon2.argon2id }),
  verifyPassword = (password, passwordHash) =>
    argon2.verify(passwordHash, password),
  authTokenSecret = process.env.AUTH_TOKEN_SECRET,
  adminBootstrapSecretHash = process.env.ADMIN_BOOTSTRAP_SECRET_HASH,
  database = getDatabase,
  mongoClient = getMongoClient,
  registrationLimiter = createRegistrationLimiter(),
  loginLimiter = createLoginLimiter(),
  adminSetupLimiter = createAdminSetupLimiter(),
  adminCredentialLimiter = createAdminCredentialLimiter(),
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

  router.get('/admin-setup/status', async (_request, response, next) => {
    try {
      const db = database();
      const [adminCount, marker] = await Promise.all([
        db.collection('users').countDocuments({ role: 'admin' }),
        db.collection('admin_bootstrap').findOne(
          { _id: BOOTSTRAP_MARKER_ID },
          { projection: { _id: 1 } },
        ),
      ]);
      response.status(200).json({
        setupAvailable:
          typeof adminBootstrapSecretHash === 'string' &&
          /^[a-f0-9]{64}$/i.test(adminBootstrapSecretHash) &&
          adminCount === 0 &&
          !marker,
      });
    } catch (error) {
      next(error);
    }
  });

  router.post(
    '/admin-setup',
    adminSetupLimiter,
    async (request, response, next) => {
      const body = request.body;
      if (!body || typeof body !== 'object' || Array.isArray(body)) {
        response.status(400).json({
          error: {
            code: 'VALIDATION_ERROR',
            message: 'A JSON object with administrator details is required.',
          },
        });
        return;
      }

      const { fullName, username, email, password, confirmPassword, setupSecret } = body;
      if (
        typeof fullName !== 'string' ||
        fullName.trim().length < 2 ||
        fullName.trim().length > 80 ||
        typeof username !== 'string' ||
        !usernamePattern.test(username.trim().toLowerCase()) ||
        typeof email !== 'string' ||
        email.trim().length > 254 ||
        !emailPattern.test(email.trim()) ||
        typeof password !== 'string' ||
        password.length < 12 ||
        password.length > 128 ||
        password !== confirmPassword ||
        typeof setupSecret !== 'string'
      ) {
        response.status(400).json({
          error: {
            code: 'VALIDATION_ERROR',
            message:
              'Enter valid account details and a matching password of at least 12 characters.',
          },
        });
        return;
      }

      if (!verifyBootstrapSecret(setupSecret, adminBootstrapSecretHash)) {
        response.status(403).json({
          error: {
            code: 'BOOTSTRAP_AUTHORIZATION_FAILED',
            message: 'Administrator setup is not authorized.',
          },
        });
        return;
      }

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

      try {
        const db = database();
        await createFirstAdmin({
          client: mongoClient(),
          database: db,
          account: {
            fullName: fullName.trim(),
            username: username.trim().toLowerCase(),
            email: email.trim().toLowerCase(),
            passwordHash,
          },
          bootstrapSecret: setupSecret,
          configuredSecretHash: adminBootstrapSecretHash,
        });
        response.status(201).json({ initialized: true });
      } catch (error) {
        if (error instanceof BootstrapError) {
          response.status(
            error.code === 'BOOTSTRAP_AUTHORIZATION_FAILED' ? 403 : 409,
          ).json({
            error: {
              code: error.code,
              message:
                error.code === 'EMAIL_ALREADY_EXISTS'
                  ? error.message
                  : 'Administrator setup is unavailable.',
            },
          });
          return;
        }
        if (error && error.code === 11000) {
          respondToDuplicate(response, error);
          return;
        }
        next(error);
      }
    },
  );

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
      const sessionVersion = getSessionVersion(user);
      if (sessionVersion === null) {
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

      const token = jwt.sign({ sv: sessionVersion }, authTokenSecret, {
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

  router.patch(
    '/account/credentials',
    authenticate,
    requireAdmin,
    adminCredentialLimiter,
    async (request, response, next) => {
      const {
        currentPassword,
        email,
        newPassword,
        confirmPassword,
      } = request.body || {};
      const normalizedEmail = typeof email === 'string'
        ? email.trim().toLowerCase()
        : undefined;
      const changesEmail = normalizedEmail !== undefined &&
        normalizedEmail !== request.authenticatedUser.email;
      const changesPassword = typeof newPassword === 'string' &&
        newPassword.length > 0;

      if (
        typeof currentPassword !== 'string' ||
        currentPassword.length === 0 ||
        currentPassword.length > 128 ||
        (email !== undefined &&
          (typeof email !== 'string' ||
            email.trim().length > 254 ||
            !emailPattern.test(email.trim()))) ||
        (newPassword !== undefined &&
          (typeof newPassword !== 'string' ||
            newPassword.length < 12 ||
            newPassword.length > 128 ||
            newPassword !== confirmPassword)) ||
        (confirmPassword !== undefined && !changesPassword) ||
        (!changesEmail && !changesPassword)
      ) {
        response.status(400).json({
          error: {
            code: 'VALIDATION_ERROR',
            message:
              'Enter your current password and a valid new email or password.',
          },
        });
        return;
      }

      let collection;
      let user;
      try {
        collection = usersCollection();
        user = await collection.findOne({
          _id: new ObjectId(request.authenticatedUser.id),
          role: 'admin',
        });
      } catch (error) {
        next(error);
        return;
      }

      if (
        !user ||
        isAccountDisabled(user) ||
        typeof user.passwordHash !== 'string' ||
        !user.passwordHash.startsWith('$argon2id$')
      ) {
        response.status(401).json({
          error: {
            code: 'UNAUTHENTICATED',
            message: 'A valid administrator login session is required.',
          },
        });
        return;
      }
      const currentSessionVersion = getSessionVersion(user);
      if (
        currentSessionVersion === null ||
        currentSessionVersion >= Number.MAX_SAFE_INTEGER
      ) {
        response.status(409).json({
          error: {
            code: 'ACCOUNT_CHANGED',
            message: 'The administrator account could not be updated safely.',
          },
        });
        return;
      }
      if (currentSessionVersion !== request.authenticatedSessionVersion) {
        response.status(401).json({
          error: {
            code: 'UNAUTHENTICATED',
            message: 'A valid administrator login session is required.',
          },
        });
        return;
      }

      let currentPasswordIsValid = false;
      try {
        currentPasswordIsValid = await verifyPassword(
          currentPassword,
          user.passwordHash,
        );
      } catch {
        currentPasswordIsValid = false;
      }
      if (!currentPasswordIsValid) {
        response.status(401).json({
          error: {
            code: 'CURRENT_PASSWORD_INVALID',
            message: 'The current password is incorrect.',
          },
        });
        return;
      }

      const updates = {};
      if (changesEmail) updates.email = normalizedEmail;
      if (changesPassword) {
        try {
          updates.passwordHash = await hashPassword(newPassword);
        } catch (error) {
          next(error);
          return;
        }
      }
      const nextSessionVersion = currentSessionVersion + 1;
      updates.sessionVersion = nextSessionVersion;

      try {
        const result = await collection.updateOne(
          {
            _id: user._id,
            role: 'admin',
            passwordHash: user.passwordHash,
            ...(user.sessionVersion === undefined
              ? { sessionVersion: { $exists: false } }
              : { sessionVersion: currentSessionVersion }),
          },
          { $set: updates },
        );
        if (result.modifiedCount !== 1) {
          response.status(409).json({
            error: {
              code: 'ACCOUNT_CHANGED',
              message: 'The administrator account changed. Sign in again.',
            },
          });
          return;
        }
      } catch (error) {
        if (error && error.code === 11000) {
          response.status(409).json({
            error: {
              code: 'EMAIL_ALREADY_EXISTS',
              message: 'An account with this email already exists.',
            },
          });
          return;
        }
        next(error);
        return;
      }

      const token = jwt.sign({ sv: nextSessionVersion }, authTokenSecret, {
        algorithm: 'HS256',
        audience: 'dailyduel-app',
        expiresIn: '1h',
        issuer: 'dailyduel-api',
        subject: user._id.toString(),
      });
      response.status(200).json({
        token,
        user: toSafeUser({
          ...user,
          ...updates,
        }),
      });
    },
  );

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

function createAdminSetupLimiter({
  limit = 5,
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
          message: 'Too many setup attempts. Please wait and try again.',
        },
      });
    },
  });
}

function createAdminCredentialLimiter({
  limit = 5,
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
          message:
            'Too many account change attempts. Please wait and try again.',
        },
      });
    },
  });
}

module.exports = {
  createAuthRouter,
  createAdminCredentialLimiter,
  createAdminSetupLimiter,
  createLoginLimiter,
  createRegistrationLimiter,
};
