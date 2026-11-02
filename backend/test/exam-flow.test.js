const assert = require('node:assert/strict');
const jwt = require('jsonwebtoken');
const { ObjectId } = require('mongodb');
const { after, test } = require('node:test');
const { createApp } = require('../src/app');
const { processDueExamResults } = require('../src/quiz/exam-processor');

const authTokenSecret = 'test-only-auth-token-secret-at-least-32-bytes';
const userId = new ObjectId();
const servers = new Set();

after(async () => {
  await Promise.all(
    [...servers].map(
      (server) =>
        new Promise((resolve, reject) => {
          server.close((error) => (error ? reject(error) : resolve()));
        }),
    ),
  );
});

function same(first, second) {
  if (first instanceof ObjectId && second instanceof ObjectId) {
    return first.equals(second);
  }
  if (first instanceof Date && second instanceof Date) {
    return first.getTime() === second.getTime();
  }
  return first === second;
}

function getPath(object, path) {
  return path.split('.').reduce((value, key) => value?.[key], object);
}

function matches(document, query) {
  return Object.entries(query).every(([key, expected]) => {
    const actual = getPath(document, key);
    if (expected && typeof expected === 'object' && !(expected instanceof ObjectId) && !(expected instanceof Date)) {
      if ('$in' in expected) {
        return expected.$in.some((item) =>
          Array.isArray(actual) ? actual.includes(item) : same(actual, item),
        );
      }
      if ('$ne' in expected && same(actual, expected.$ne)) return false;
      if ('$nin' in expected && expected.$nin.some((item) => same(actual, item))) {
        return false;
      }
      if ('$exists' in expected && (actual !== undefined) !== expected.$exists) {
        return false;
      }
      if ('$lte' in expected && !(actual <= expected.$lte)) return false;
      if ('$gte' in expected && !(actual >= expected.$gte)) return false;
      return true;
    }
    return Array.isArray(actual) ? actual.includes(expected) : same(actual, expected);
  });
}

class MemoryCollection {
  constructor(documents = []) {
    this.documents = documents;
  }

  async createIndex() {
    return 'test-index';
  }

  findOne(query) {
    return Promise.resolve(this.documents.find((document) => matches(document, query)) ?? null);
  }

  find(query = {}) {
    const cursor = {
      values: this.documents.filter((document) => matches(document, query)),
      limit(count) {
        this.values = this.values.slice(0, count);
        return this;
      },
      project(projection) {
        this.projection = projection;
        return this;
      },
      sort(order) {
        this.values.sort((first, second) => {
          for (const [field, direction] of Object.entries(order)) {
            const a = getPath(first, field);
            const b = getPath(second, field);
            if (a < b) return -direction;
            if (a > b) return direction;
          }
          return 0;
        });
        return this;
      },
      async toArray() {
        if (!this.projection) return this.values;
        const included = Object.keys(this.projection).filter(
          (field) => this.projection[field] === 1,
        );
        if (included.length) {
          return this.values.map((document) => {
            const result = {};
            for (const field of included) {
              if (document[field] !== undefined) result[field] = document[field];
            }
            if (document._id !== undefined) result._id = document._id;
            return result;
          });
        }
        return this.values.map((document) => {
          const result = { ...document };
          for (const [field, include] of Object.entries(this.projection)) {
            if (include === 0) delete result[field];
          }
          return result;
        });
      },
    };
    return cursor;
  }

  async insertOne(document) {
    const inserted = { ...document, _id: document._id ?? new ObjectId() };
    this.documents.push(inserted);
    return { insertedId: inserted._id };
  }

  async updateOne(query, update, { upsert = false } = {}) {
    let document = this.documents.find((item) => matches(item, query));
    if (!document && upsert) {
      document = { _id: new ObjectId() };
      for (const [key, value] of Object.entries(query)) {
        if (!(value && typeof value === 'object' && Object.keys(value).some((op) => op.startsWith('$')))) {
          document[key] = value;
        }
      }
      this.documents.push(document);
    }
    if (!document) return { modifiedCount: 0 };
    for (const [key, value] of Object.entries(update.$setOnInsert ?? {})) {
      if (document[key] === undefined) document[key] = value;
    }
    for (const [key, value] of Object.entries(update.$set ?? {})) {
      const parts = key.split('.');
      let target = document;
      while (parts.length > 1) {
        const part = parts.shift();
        target[part] ??= {};
        target = target[part];
      }
      target[parts[0]] = value;
    }
    return { modifiedCount: 1 };
  }
}

test('competitive exam creation, timed answers, and leaderboard are backend-controlled', async () => {
  let clock = new Date('2026-01-01T00:00:00.000Z');
  const examQuestions = Array.from({ length: 15 }, (_, index) => ({
    _id: new ObjectId(),
    categoryId: 'fun-entertainment',
    subcategory: 'Funny quizzes',
    questionText: `Question ${index + 1}`,
    type: 'multiple_choice',
    options: [
      { id: 'a', text: 'Wrong' },
      { id: 'b', text: 'Right' },
    ],
    answerKey: 'b',
    explanation: 'Server-side answer explanation.',
    difficulty: 'easy',
    modes: ['casual', 'competitive'],
    deterministic: true,
    points: 10,
    status: 'published',
  }));
  const collections = {
    quiz_categories: new MemoryCollection(),
    questions: new MemoryCollection(examQuestions),
    exams: new MemoryCollection(),
    exam_attempts: new MemoryCollection(),
    exam_results: new MemoryCollection(),
    exam_achievements: new MemoryCollection(),
  };
  const adminUser = {
    _id: userId,
    fullName: 'Exam Admin',
    username: 'exam_admin',
    email: 'admin@example.test',
    role: 'admin',
  };
  const app = createApp({
    checkDatabase: async () => {},
    authTokenSecret,
    usersCollection: () => ({ findOne: async () => adminUser }),
    database: () => ({
      collection: (name) => collections[name],
    }),
    now: () => new Date(clock),
  });
  const server = app.listen(0, '127.0.0.1');
  servers.add(server);
  await new Promise((resolve) => server.once('listening', resolve));
  const baseUrl = `http://127.0.0.1:${server.address().port}`;
  const token = jwt.sign({}, authTokenSecret, {
    algorithm: 'HS256',
    audience: 'dailyduel-app',
    expiresIn: '1h',
    issuer: 'dailyduel-api',
    subject: userId.toString(),
  });
  const headers = {
    authorization: `Bearer ${token}`,
    'content-type': 'application/json',
  };
  const scheduledAt = new Date(clock.getTime() + 60_000);
  const createResponse = await fetch(`${baseUrl}/api/v1/admin/quizzes/exams`, {
    method: 'POST',
    headers,
    body: JSON.stringify({
      title: 'Scheduled fun exam',
      description: 'A controlled server-side competition.',
      categoryId: 'fun-entertainment',
      scheduledAt: scheduledAt.toISOString(),
      questionIds: examQuestions.map((question) => question._id.toString()),
    }),
  });
  assert.equal(createResponse.status, 201);
  const created = await createResponse.json();
  assert.equal(created.questionCount, 15);
  assert.equal(created.durationSeconds, 450);

  clock = new Date(scheduledAt.getTime() + 500);
  const startResponse = await fetch(
    `${baseUrl}/api/v1/exams/${created.examId}/attempts`,
    { method: 'POST', headers },
  );
  assert.equal(startResponse.status, 200);
  const started = await startResponse.json();
  assert.equal(started.questionIndex, 0);
  assert.equal(started.question.id, examQuestions[0]._id.toString());
  assert.equal(Object.hasOwn(started.question, 'answerKey'), false);

  const answerPath =
    `${baseUrl}/api/v1/exams/${created.examId}/attempts/` +
    `${started.attemptId}/answers`;
  const answerResponse = await fetch(answerPath, {
    method: 'POST',
    headers,
    body: JSON.stringify({
      questionId: examQuestions[0]._id.toString(),
      answer: 'b',
    }),
  });
  assert.equal(answerResponse.status, 200);
  assert.equal((await answerResponse.json()).questionIndex, 0);

  const duplicateAnswer = await fetch(answerPath, {
    method: 'POST',
    headers,
    body: JSON.stringify({
      questionId: examQuestions[0]._id.toString(),
      answer: 'a',
    }),
  });
  assert.equal(duplicateAnswer.status, 409);

  clock = new Date(scheduledAt.getTime() + 30_001);
  const restored = await fetch(
    `${baseUrl}/api/v1/exams/${created.examId}/attempts/${started.attemptId}`,
    { headers },
  );
  assert.equal(restored.status, 200);
  assert.equal((await restored.json()).questionIndex, 1);

  clock = new Date(scheduledAt.getTime() + 450_000);
  const getCollection = (name) => collections[name];
  assert.equal(await processDueExamResults({ getCollection, now: () => clock }), 1);
  assert.equal(await processDueExamResults({ getCollection, now: () => clock }), 0);
  assert.equal(collections.exam_results.documents.length, 1);
  assert.equal(collections.exam_achievements.documents.length, 1);
  assert.equal(collections.exam_results.documents[0].score, 10);

  const leaderboard = await fetch(
    `${baseUrl}/api/v1/exams/${created.examId}/leaderboard`,
    { headers },
  );
  assert.equal(leaderboard.status, 200);
  assert.deepEqual((await leaderboard.json()).results, [
    {
      rank: 1,
      fullName: 'Exam Admin',
      username: 'exam_admin',
      score: 10,
      correctCount: 1,
      totalQuestions: 15,
    },
  ]);
});

test('exam history is authenticated, user-scoped, and includes active and published results', async () => {
  const firstUserId = new ObjectId();
  const secondUserId = new ObjectId();
  const activeExamId = new ObjectId();
  const completedExamId = new ObjectId();
  const missingExamId = new ObjectId();
  const invalidExamId = new ObjectId();
  const processingExamId = new ObjectId();
  const firstAttemptId = new ObjectId();
  const secondAttemptId = new ObjectId();
  const missingExamAttemptId = new ObjectId();
  const scheduledAt = new Date('2026-01-01T00:00:00.000Z');
  const activeScheduledAt = new Date('2026-01-01T00:09:40.000Z');
  const completedAt = new Date('2026-01-01T00:03:00.000Z');
  const clock = new Date('2026-01-01T00:10:00.000Z');
  const users = new Map([
    [firstUserId.toString(), {
      _id: firstUserId,
      fullName: 'First User',
      username: 'first_user',
      email: 'first@example.test',
      role: 'user',
    }],
    [secondUserId.toString(), {
      _id: secondUserId,
      fullName: 'Second User',
      username: 'second_user',
      email: 'second@example.test',
      role: 'user',
    }],
  ]);
  const collections = {
    exam_attempts: new MemoryCollection([
      {
        _id: firstAttemptId,
        examId: activeExamId,
        userId: firstUserId.toString(),
        status: 'in_progress',
        createdAt: activeScheduledAt,
        answers: {},
      },
      {
        _id: secondAttemptId,
        examId: completedExamId,
        userId: firstUserId.toString(),
        status: 'scored',
        createdAt: scheduledAt,
        scoredAt: completedAt,
      },
      {
        _id: new ObjectId(),
        examId: completedExamId,
        userId: secondUserId.toString(),
        status: 'scored',
        createdAt: scheduledAt,
      },
      {
        _id: new ObjectId(),
        examId: processingExamId,
        userId: firstUserId.toString(),
        status: 'in_progress',
        createdAt: new Date(scheduledAt.getTime() + 1_000),
        answers: {},
      },
      {
        _id: missingExamAttemptId,
        examId: missingExamId,
        userId: firstUserId.toString(),
        status: 'scored',
        createdAt: scheduledAt,
      },
      {
        _id: new ObjectId(),
        examId: invalidExamId,
        userId: firstUserId.toString(),
        status: 'scored',
        createdAt: scheduledAt,
      },
    ]),
    exams: new MemoryCollection([
      {
        _id: activeExamId,
        title: 'Active exam',
        scheduledAt: activeScheduledAt,
        questions: [{ points: 10 }, { points: 5 }],
        resultsPublishedAt: null,
      },
      {
        _id: completedExamId,
        title: 'Completed exam',
        scheduledAt,
        questions: [{ points: 10 }, { points: 10 }],
        resultsPublishedAt: completedAt,
      },
      {
        _id: invalidExamId,
        title: 'Incomplete exam',
        scheduledAt: 'not-a-date',
        questions: [],
        resultsPublishedAt: null,
      },
      {
        _id: processingExamId,
        title: 'Processing exam',
        scheduledAt,
        questions: [{ points: 10 }],
        resultsPublishedAt: null,
      },
    ]),
    exam_results: new MemoryCollection([
      {
        _id: new ObjectId(),
        examId: completedExamId,
        userId: firstUserId.toString(),
        score: 10,
        correctCount: 1,
        answeredCount: 1,
        totalQuestions: 2,
        rank: 2,
        submittedAt: completedAt,
      },
      {
        _id: new ObjectId(),
        examId: completedExamId,
        userId: secondUserId.toString(),
        score: 20,
        correctCount: 2,
        answeredCount: 2,
        totalQuestions: 2,
        rank: 1,
        submittedAt: completedAt,
      },
    ]),
  };
  const app = createApp({
    checkDatabase: async () => {},
    authTokenSecret,
    usersCollection: () => ({
      findOne: async ({ _id }) => users.get(_id.toString()) ?? null,
    }),
    database: () => ({
      collection: (name) => collections[name],
    }),
    now: () => clock,
  });
  const server = app.listen(0, '127.0.0.1');
  servers.add(server);
  await new Promise((resolve) => server.once('listening', resolve));
  const endpoint = `http://127.0.0.1:${server.address().port}/api/v1/exams/history`;
  const createToken = (id) => jwt.sign({}, authTokenSecret, {
    algorithm: 'HS256',
    audience: 'dailyduel-app',
    expiresIn: '1h',
    issuer: 'dailyduel-api',
    subject: id.toString(),
  });

  const unauthenticated = await fetch(endpoint);
  assert.equal(unauthenticated.status, 401);

  const firstResponse = await fetch(endpoint, {
    headers: { authorization: `Bearer ${createToken(firstUserId)}` },
  });
  assert.equal(firstResponse.status, 200);
  const firstHistory = (await firstResponse.json()).history;
  assert.equal(firstHistory.length, 5);
  assert.deepEqual(
    firstHistory.map(({ status }) => status),
    [
      'in_progress',
      'results_processing',
      'results_published',
      'exam_unavailable',
      'exam_unavailable',
    ],
  );
  assert.equal(firstHistory[0].attemptId, firstAttemptId.toString());
  assert.equal(firstHistory[0].totalMarks, 15);
  assert.equal(firstHistory[2].score, 10);
  assert.equal(firstHistory[2].correctCount, 1);
  assert.equal(firstHistory[2].unansweredCount, 1);
  assert.equal(firstHistory[2].rank, 2);
  assert.equal(firstHistory[2].resultPublished, true);
  assert.equal(firstHistory[3].title, 'Exam unavailable');

  const otherUserAttempt = await fetch(
    `http://127.0.0.1:${server.address().port}/api/v1/exams/` +
      `${activeExamId.toString()}/attempts/${firstAttemptId.toString()}`,
    { headers: { authorization: `Bearer ${createToken(secondUserId)}` } },
  );
  assert.equal(otherUserAttempt.status, 404);

  const secondResponse = await fetch(endpoint, {
    headers: { authorization: `Bearer ${createToken(secondUserId)}` },
  });
  assert.equal(secondResponse.status, 200);
  const secondHistory = (await secondResponse.json()).history;
  assert.equal(secondHistory.length, 1);
  assert.equal(secondHistory[0].score, 20);
  assert.notEqual(secondHistory[0].attemptId, firstAttemptId.toString());
});

test('exam history returns an empty list for a signed-in user without attempts', async () => {
  const isolatedUserId = new ObjectId();
  const app = createApp({
    checkDatabase: async () => {},
    authTokenSecret,
    usersCollection: () => ({
      findOne: async ({ _id }) =>
        _id.equals(isolatedUserId)
          ? {
              _id: isolatedUserId,
              fullName: 'New User',
              username: 'new_user',
              email: 'new@example.test',
              role: 'user',
            }
          : null,
    }),
    database: () => ({
      collection: () => new MemoryCollection(),
    }),
  });
  const server = app.listen(0, '127.0.0.1');
  servers.add(server);
  await new Promise((resolve) => server.once('listening', resolve));
  const token = jwt.sign({}, authTokenSecret, {
    algorithm: 'HS256',
    audience: 'dailyduel-app',
    expiresIn: '1h',
    issuer: 'dailyduel-api',
    subject: isolatedUserId.toString(),
  });

  const response = await fetch(
    `http://127.0.0.1:${server.address().port}/api/v1/exams/history`,
    { headers: { authorization: `Bearer ${token}` } },
  );
  assert.equal(response.status, 200);
  assert.deepEqual(await response.json(), { history: [] });
});
