const assert = require('node:assert/strict');
const jwt = require('jsonwebtoken');
const { ObjectId } = require('mongodb');
const { after, test } = require('node:test');
const { createApp } = require('../src/app');
const { DEFAULT_CATEGORIES } = require('../src/quiz/catalog');
const { validateQuestion } = require('../src/quiz/validation');

const authTokenSecret = 'test-only-admin-management-secret-at-least-32-bytes';
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

function matches(document, query) {
  return Object.entries(query).every(([key, expected]) => {
    const actual = document[key];
    if (expected && typeof expected === 'object' && !(expected instanceof ObjectId)) {
      if ('$ne' in expected && actual === expected.$ne) return false;
      if ('$in' in expected && !expected.$in.includes(actual)) return false;
      return true;
    }
    return actual instanceof ObjectId && expected instanceof ObjectId
      ? actual.equals(expected)
      : actual === expected;
  });
}

class Collection {
  constructor(documents = []) {
    this.documents = documents;
  }

  find(query = {}) {
    const cursor = {
      values: this.documents.filter((item) => matches(item, query)),
      sort(order) {
        this.values.sort((first, second) => {
          for (const [field, direction] of Object.entries(order)) {
            if (first[field] < second[field]) return -direction;
            if (first[field] > second[field]) return direction;
          }
          return 0;
        });
        return this;
      },
      skip(count) {
        this.values = this.values.slice(count);
        return this;
      },
      limit(count) {
        this.values = this.values.slice(0, count);
        return this;
      },
      async toArray() {
        return this.values;
      },
    };
    return cursor;
  }

  async countDocuments(query = {}) {
    return this.documents.filter((item) => matches(item, query)).length;
  }

  async findOne(query = {}) {
    return this.documents.find((item) => matches(item, query)) ?? null;
  }

  async insertOne(document) {
    const inserted = { ...document, _id: new ObjectId() };
    this.documents.push(inserted);
    return { insertedId: inserted._id };
  }

  async updateOne(query, update) {
    const document = this.documents.find((item) => matches(item, query));
    if (!document) return { modifiedCount: 0 };
    Object.assign(document, update.$set);
    return { modifiedCount: 1 };
  }
}

function makeQuestion(overrides = {}) {
  return {
    categoryId: 'fun-entertainment',
    subcategory: 'Funny quizzes',
    questionText: 'A new admin question?',
    type: 'multiple_choice',
    options: [
      { id: 'a', text: 'Option A' },
      { id: 'b', text: 'Option B' },
    ],
    answerKey: 'b',
    explanation: 'Option B is correct.',
    difficulty: 'easy',
    modes: ['casual', 'competitive'],
    points: 10,
    ...overrides,
  };
}

async function setup() {
  const adminId = new ObjectId();
  const admin = {
    _id: adminId,
    fullName: 'Admin User',
    username: 'admin_user',
    email: 'admin@example.test',
    role: 'admin',
  };
  const student = {
    _id: new ObjectId(),
    fullName: 'Student One',
    username: 'student_one',
    email: 'student@example.test',
    role: 'user',
    createdAt: new Date('2026-01-02T03:04:05.000Z'),
    passwordHash: 'must-not-be-returned',
  };
  const otherRole = {
    _id: new ObjectId(),
    fullName: 'Another Admin',
    username: 'another_admin',
    email: 'other-admin@example.test',
    role: 'admin',
  };
  const draftQuestionId = new ObjectId();
  const publishedQuestionId = new ObjectId();
  const draftQuestion = {
    ...validateQuestion(makeQuestion({ questionText: 'Draft question text' })),
    _id: draftQuestionId,
    status: 'draft',
  };
  const publishedQuestion = {
    ...validateQuestion(makeQuestion({ questionText: 'Published question text' })),
    _id: publishedQuestionId,
    status: 'published',
  };
  const scheduledExamId = new ObjectId();
  const activeExamId = new ObjectId();
  const resultsExamId = new ObjectId();
  const scheduledAt = new Date(Date.now() + 60 * 60 * 1000);
  const publishedAt = new Date(Date.now() - 60 * 1000);
  const exam = (id, status, date, resultsPublishedAt = null) => ({
    _id: id,
    title: `Exam ${status}`,
    description: 'Existing exam description',
    categoryId: 'fun-entertainment',
    scheduledAt: date,
    status,
    resultsPublishedAt,
    questions: [{ points: 10 }, { points: 5 }],
  });
  const collections = {
    quiz_categories: new Collection(),
    questions: new Collection([draftQuestion, publishedQuestion]),
    exams: new Collection([
      exam(scheduledExamId, 'scheduled', scheduledAt),
      exam(activeExamId, 'open', new Date(Date.now() - 30_000)),
      exam(resultsExamId, 'results_published', publishedAt, publishedAt),
    ]),
    exam_attempts: new Collection([
      { _id: new ObjectId(), examId: activeExamId, userId: 'participant-1' },
    ]),
    exam_results: new Collection([
      {
        _id: new ObjectId(),
        examId: resultsExamId,
        rank: 1,
        fullName: 'Student One',
        username: 'student_one',
        score: 15,
        correctCount: 2,
        answeredCount: 2,
        totalQuestions: 2,
      },
    ]),
  };
  const users = new Collection([admin, student, otherRole]);
  const app = createApp({
    checkDatabase: async () => {},
    authTokenSecret,
    usersCollection: () => users,
    database: () => ({ collection: (name) => collections[name] }),
    now: () => new Date(),
  });
  const server = app.listen(0, '127.0.0.1');
  servers.add(server);
  await new Promise((resolve) => server.once('listening', resolve));
  const token = jwt.sign({}, authTokenSecret, {
    algorithm: 'HS256',
    audience: 'dailyduel-app',
    expiresIn: '1h',
    issuer: 'dailyduel-api',
    subject: adminId.toString(),
  });
  return {
    baseUrl: `http://127.0.0.1:${server.address().port}/api/v1/admin/quizzes`,
    token,
    collections,
    student,
    draftQuestionId,
    publishedQuestionId,
    scheduledExamId,
    activeExamId,
    resultsExamId,
  };
}

test('admin student listing is protected, paginated, role-filtered, and returns safe fields', async () => {
  const context = await setup();
  const endpoint = `${context.baseUrl.replace('/api/v1/admin/quizzes', '/api/v1/admin')}/users`;
  const unauthenticated = await fetch(endpoint);
  assert.equal(unauthenticated.status, 401);

  const listing = await fetch(`${endpoint}?page=1&pageSize=1`, {
    headers: { authorization: 'Bearer ' + context.token },
  });
  assert.equal(listing.status, 200);
  const body = await listing.json();
  assert.equal(body.users.length, 1);
  assert.deepEqual(body.users[0], {
    id: context.student._id.toString(),
    fullName: 'Student One',
    username: 'student_one',
    email: 'student@example.test',
    createdAt: '2026-01-02T03:04:05.000Z',
  });
  assert.equal(body.pagination.total, 1);
  assert.equal(body.pagination.page, 1);
  assert.equal(body.pagination.pageSize, 1);
  assert.equal(JSON.stringify(body).includes('must-not-be-returned'), false);

  const nonAdminToken = jwt.sign({}, authTokenSecret, {
    algorithm: 'HS256',
    audience: 'dailyduel-app',
    expiresIn: '1h',
    issuer: 'dailyduel-api',
    subject: context.student._id.toString(),
  });
  const forbidden = await fetch(endpoint, {
    headers: { authorization: 'Bearer ' + nonAdminToken },
  });
  assert.equal(forbidden.status, 403);
});

test('admin exam listing exposes real records and blocks unsafe edits or archives', async () => {
  const context = await setup();
  const headers = { authorization: `Bearer ${context.token}` };
  const unauthenticated = await fetch(`${context.baseUrl}/exams`);
  assert.equal(unauthenticated.status, 401);

  const listing = await fetch(`${context.baseUrl}/exams?page=1&pageSize=1`, {
    headers,
  });
  assert.equal(listing.status, 200);
  const body = await listing.json();
  assert.equal(body.exams.length, 1);
  assert.equal(body.pagination.total, 3);

  const unsafeEdit = await fetch(
    `${context.baseUrl}/exams/${context.activeExamId}`,
    {
      method: 'PATCH',
      headers: { ...headers, 'content-type': 'application/json' },
      body: JSON.stringify({ title: 'Changed title' }),
    },
  );
  assert.equal(unsafeEdit.status, 409);

  const unsafeArchive = await fetch(
    `${context.baseUrl}/exams/${context.activeExamId}/archive`,
    { method: 'PATCH', headers },
  );
  assert.equal(unsafeArchive.status, 409);
  assert.equal(
    (await context.collections.exam_attempts.countDocuments({
      examId: context.activeExamId,
    })),
    1,
  );

  const safeEdit = await fetch(
    `${context.baseUrl}/exams/${context.scheduledExamId}`,
    {
      method: 'PATCH',
      headers: { ...headers, 'content-type': 'application/json' },
      body: JSON.stringify({ title: 'Updated scheduled exam' }),
    },
  );
  assert.equal(safeEdit.status, 200);
  assert.equal(
    (await context.collections.exams.findOne({
      _id: context.scheduledExamId,
    })).title,
    'Updated scheduled exam',
  );

  const archive = await fetch(
    `${context.baseUrl}/exams/${context.scheduledExamId}/archive`,
    { method: 'PATCH', headers },
  );
  assert.equal(archive.status, 200);
  assert.equal(
    (await context.collections.exams.findOne({
      _id: context.scheduledExamId,
    })).status,
    'archived',
  );
});

test('admin question APIs support safe review, edits, archive, and validated bulk import', async () => {
  const context = await setup();
  const headers = {
    authorization: `Bearer ${context.token}`,
    'content-type': 'application/json',
  };
  const list = await fetch(`${context.baseUrl}/questions?status=draft`, {
    headers,
  });
  const draft = (await list.json()).questions[0];
  assert.equal(draft.answerKey, 'b');
  assert.equal(draft.questionText, 'Draft question text');

  const edit = await fetch(
    `${context.baseUrl}/questions/${context.draftQuestionId}`,
    {
      method: 'PATCH',
      headers,
      body: JSON.stringify(makeQuestion({ questionText: 'Edited draft question' })),
    },
  );
  assert.equal(edit.status, 200);

  const publishedEdit = await fetch(
    `${context.baseUrl}/questions/${context.publishedQuestionId}`,
    {
      method: 'PATCH',
      headers,
      body: JSON.stringify(makeQuestion({ questionText: 'Unsafe change' })),
    },
  );
  assert.equal(publishedEdit.status, 409);

  const duplicate = makeQuestion({ questionText: 'Bulk question duplicate' });
  const unique = makeQuestion({ questionText: 'Unique imported question' });
  const bulk = await fetch(`${context.baseUrl}/questions/bulk`, {
    method: 'POST',
    headers,
    body: JSON.stringify({
      questions: [duplicate, { ...duplicate }, unique, {}],
    }),
  });
  assert.equal(bulk.status, 201);
  const report = await bulk.json();
  assert.equal(report.created.length, 2);
  assert.equal(report.duplicates.length, 1);
  assert.equal(report.invalid.length, 1);

  const archive = await fetch(
    `${context.baseUrl}/questions/${context.draftQuestionId}/archive`,
    { method: 'PATCH', headers },
  );
  assert.equal(archive.status, 200);
});

test('admin results are unavailable before publication and scoped to the selected exam', async () => {
  const context = await setup();
  const headers = { authorization: `Bearer ${context.token}` };
  const response = await fetch(
    `${context.baseUrl}/exams/${context.resultsExamId}/results`,
    { headers },
  );
  assert.equal(response.status, 200);
  const results = await response.json();
  assert.equal(results.results.length, 1);
  assert.equal(results.results[0].username, 'student_one');

  const unpublishedExamId = context.activeExamId;
  const unavailable = await fetch(
    `${context.baseUrl}/exams/${unpublishedExamId}/results`,
    { headers },
  );
  assert.equal(unavailable.status, 409);
});
