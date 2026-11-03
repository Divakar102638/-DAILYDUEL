const { createHash, timingSafeEqual } = require('node:crypto');
const { isAccountDisabled } = require('../middleware/auth');

const BOOTSTRAP_MARKER_ID = 'first-admin-bootstrap';

class BootstrapError extends Error {
  constructor(message, code = 'ADMIN_SETUP_UNAVAILABLE') {
    super(message);
    this.safeMessage = message;
    this.code = code;
  }
}

function verifyBootstrapSecret(bootstrapSecret, configuredSecretHash) {
  if (
    typeof bootstrapSecret !== 'string' ||
    Buffer.byteLength(bootstrapSecret, 'utf8') < 32 ||
    typeof configuredSecretHash !== 'string' ||
    !/^[a-f0-9]{64}$/i.test(configuredSecretHash)
  ) {
    return false;
  }

  const suppliedHash = createHash('sha256')
    .update(bootstrapSecret, 'utf8')
    .digest();
  const expectedHash = Buffer.from(configuredSecretHash, 'hex');
  return timingSafeEqual(suppliedHash, expectedHash);
}

async function bootstrapFirstAdmin({
  client,
  database,
  email,
  bootstrapSecret,
  configuredSecretHash,
}) {
  if (typeof email !== 'string' || email !== email.trim().toLowerCase()) {
    throw new BootstrapError(
      'ADMIN_BOOTSTRAP_EMAIL must be a normalized existing account email.',
    );
  }
  if (!verifyBootstrapSecret(bootstrapSecret, configuredSecretHash)) {
    throw new BootstrapError(
      'Administrator bootstrap authorization failed.',
      'BOOTSTRAP_AUTHORIZATION_FAILED',
    );
  }

  const users = database.collection('users');
  const markers = database.collection('admin_bootstrap');
  const session = client.startSession();
  try {
    await session.withTransaction(async () => {
      const marker = await markers.findOne(
        { _id: BOOTSTRAP_MARKER_ID },
        { session },
      );
      if (marker) {
        const previouslyPromotedUser = await users.findOne(
          { email },
          { session },
        );
        if (
          previouslyPromotedUser &&
          !isAccountDisabled(previouslyPromotedUser) &&
          previouslyPromotedUser.role === 'admin' &&
          String(previouslyPromotedUser._id) === String(marker.userId)
        ) {
          return;
        }
        throw new BootstrapError(
          'Administrator bootstrap has already been completed.',
        );
      }

      if ((await users.countDocuments({ role: 'admin' }, { session })) > 0) {
        throw new BootstrapError(
          'An administrator already exists; bootstrap is not available.',
        );
      }

      const user = await users.findOne({ email }, { session });
      if (!user || isAccountDisabled(user)) {
        throw new BootstrapError(
          'The configured active account was not found in dailyduel.users.',
        );
      }
      if (
        typeof user.passwordHash !== 'string' ||
        !user.passwordHash.startsWith('$argon2id$')
      ) {
        throw new BootstrapError(
          'The configured account must have a valid Argon2id password hash.',
        );
      }

      const update = await users.updateOne(
        { _id: user._id, role: { $ne: 'admin' } },
        { $set: { role: 'admin' } },
        { session },
      );
      if (update.modifiedCount !== 1) {
        throw new BootstrapError(
          'The configured account could not be promoted safely.',
        );
      }

      await markers.insertOne(
        {
          _id: BOOTSTRAP_MARKER_ID,
          userId: user._id,
          completedAt: new Date(),
        },
        { session },
      );
    });
  } finally {
    await session.endSession();
  }
}

async function createFirstAdmin({
  client,
  database,
  account,
  bootstrapSecret,
  configuredSecretHash,
  now = () => new Date(),
}) {
  if (!verifyBootstrapSecret(bootstrapSecret, configuredSecretHash)) {
    throw new BootstrapError(
      'Administrator setup authorization failed.',
      'BOOTSTRAP_AUTHORIZATION_FAILED',
    );
  }

  const users = database.collection('users');
  const markers = database.collection('admin_bootstrap');
  const session = client.startSession();
  try {
    await session.withTransaction(async () => {
      const marker = await markers.findOne(
        { _id: BOOTSTRAP_MARKER_ID },
        { session },
      );
      if (marker) {
        throw new BootstrapError('Admin setup is unavailable.');
      }

      if ((await users.countDocuments({ role: 'admin' }, { session })) > 0) {
        throw new BootstrapError('Admin setup is unavailable.');
      }

      if (await users.findOne({ email: account.email }, { session })) {
        throw new BootstrapError(
          'An account already uses this email address.',
          'EMAIL_ALREADY_EXISTS',
        );
      }

      const timestamp = now();
      const result = await users.insertOne(
        {
          ...account,
          role: 'admin',
          status: 'active',
          createdAt: timestamp,
          updatedAt: timestamp,
        },
        { session },
      );
      await markers.insertOne(
        {
          _id: BOOTSTRAP_MARKER_ID,
          adminEmail: account.email,
          userId: result.insertedId,
          completedAt: timestamp,
          status: 'completed',
        },
        { session },
      );
    });
  } finally {
    await session.endSession();
  }
}

module.exports = {
  BootstrapError,
  BOOTSTRAP_MARKER_ID,
  bootstrapFirstAdmin,
  createFirstAdmin,
  verifyBootstrapSecret,
};
