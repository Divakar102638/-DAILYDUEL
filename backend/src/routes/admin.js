const express = require('express');
const { createAuthMiddleware, requireAdmin } = require('../middleware/auth');
const { getUsersCollection } = require('../db/mongo');

function createAdminRouter({
  usersCollection = getUsersCollection,
  authTokenSecret = process.env.AUTH_TOKEN_SECRET,
} = {}) {
  const router = express.Router();
  const authenticate = createAuthMiddleware({ usersCollection, authTokenSecret });

  router.get('/access', authenticate, requireAdmin, (_request, response) => {
    response.status(200).json({ authorized: true });
  });

  router.get('/users', authenticate, requireAdmin, async (request, response) => {
    const page = parsePositiveInteger(request.query.page, 1, 100_000);
    const pageSize = parsePositiveInteger(request.query.pageSize, 25, 100);
    const filter = { role: 'user' };
    const users = usersCollection();
    const [total, records] = await Promise.all([
      users.countDocuments(filter),
      users
        .find(filter, {
          projection: { _id: 1, fullName: 1, username: 1, email: 1, createdAt: 1 },
        })
        .sort({ createdAt: -1, _id: -1 })
        .skip((page - 1) * pageSize)
        .limit(pageSize)
        .toArray(),
    ]);

    response.status(200).json({
      users: records.map((user) => ({
        id: user._id.toString(),
        fullName: typeof user.fullName === 'string' ? user.fullName : '',
        username: typeof user.username === 'string' ? user.username : '',
        email: typeof user.email === 'string' ? user.email : '',
        createdAt: user.createdAt instanceof Date && !Number.isNaN(user.createdAt.getTime())
          ? user.createdAt.toISOString()
          : null,
      })),
      pagination: {
        page,
        pageSize,
        total,
        pageCount: Math.ceil(total / pageSize),
      },
    });
  });

  return router;
}

function parsePositiveInteger(value, fallback, maximum) {
  if (value === undefined) return fallback;
  const parsed = Number(value);
  if (!Number.isInteger(parsed) || parsed < 1 || parsed > maximum) {
    const error = new Error('Pagination values are invalid.');
    error.status = 400;
    throw error;
  }
  return parsed;
}

module.exports = { createAdminRouter };
