const assert = require('node:assert/strict');
const jwt = require('jsonwebtoken');
const { ObjectId } = require('mongodb');
const { after, test } = require('node:test');
const { createApp } = require('../src/app');
const { createOpenAIQuestionGenerator } = require('../src/quiz/question-generator');

const authTokenSecret = 'test-only-ai-quiz-secret-at-least-32-bytes';
const adminId = new ObjectId();
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

function matches(document, query) {
  return Object.entries(query).every(([key, expected]) => {
    const actual = document[key];
    if (expected instanceof ObjectId) {
      return actual instanceof ObjectId && actual.equals(expected);
    }
    if (expected && typeof expected === 'object' && !Array.isArray(expected)) {
      if ('$ne' in expected && actual === expected.$ne) return false;
      if ('$in' in expected) {
        return expected.$in.some((value) =>
          value instanceof ObjectId && actual instanceof ObjectId
            ? value.equals(actual)
            : value === actual,
        );
      }
      if ('$nin' in expected && expected.$nin.includes(actual)) return false;
      return true;
    }
    return actual === expected;
  });
}

class MemoryCollection {
  constructor(documents = []) {
    this.documents = documents;
    this.uniqueAiFingerprint = false;
  }

  async createIndex(keys, options) {
    if (
      keys.aiDuplicateFingerprint === 1 &&
      options.unique === true &&
      options.partialFilterExpression?.aiDuplicateFingerprint?.$exists === true
    ) {
      this.uniqueAiFingerprint = true;
    }
    return options.name;
  }

  findOne(query) {
    return Promise.resolve(
      this.documents.find((document) => matches(document, query)) ?? null,
    );
  }

  find(query = {}) {
    const cursor = {
      documents: this.documents.filter((document) => matches(document, query)),
      projection: null,
      sort() {
        return this;
      },
      limit(count) {
        this.documents = this.documents.slice(0, count);
        return this;
      },
      project(projection) {
        this.projection = projection;
        return this;
      },
      async toArray() {
        if (!this.projection) return this.documents;
        const fields = Object.keys(this.projection);
        return this.documents.map((document) =>
          Object.fromEntries(
            fields
              .filter((field) => document[field] !== undefined)
              .map((field) => [field, document[field]]),
          ),
        );
      },
    };
    return cursor;
  }

  async insertOne(document) {
    if (this.documents.some((item) => item._id === document._id)) {
      throw Object.assign(new Error('duplicate key'), { code: 11000 });
    }
    const inserted = { ...document, _id: document._id ?? new ObjectId() };
    this.documents.push(inserted);
    return { insertedId: inserted._id };
  }

  async insertMany(documents) {
    const insertedIds = {};
    for (const [index, document] of documents.entries()) {
      if (
        this.uniqueAiFingerprint &&
        document.aiDuplicateFingerprint !== undefined &&
        this.documents.some(
          (existing) =>
            existing.aiDuplicateFingerprint === document.aiDuplicateFingerprint,
        )
      ) {
        throw Object.assign(new Error('duplicate AI question fingerprint'), {
          code: 11000,
          keyPattern: { aiDuplicateFingerprint: 1 },
        });
      }
      const inserted = { ...document, _id: new ObjectId() };
      this.documents.push(inserted);
      insertedIds[index] = inserted._id;
    }
    return { insertedIds };
  }

  async deleteMany(query) {
    const retained = this.documents.filter((document) => !matches(document, query));
    const deletedCount = this.documents.length - retained.length;
    this.documents.splice(0, this.documents.length, ...retained);
    return { deletedCount };
  }

  async updateOne(query, update) {
    const document = this.documents.find((item) => matches(item, query));
    if (!document) return { matchedCount: 0, modifiedCount: 0 };
    Object.assign(document, update.$set);
    return { matchedCount: 1, modifiedCount: 1 };
  }
}

function buildDraft(index, categoryId = 'general-knowledge') {
  return {
    categoryId,
    subcategory: categoryId === 'general-knowledge' ? 'Sports' : 'Cinema',
    questionText: `Unique generated question ${index}?`,
    type: 'multiple_choice',
    options: [
      { id: 'a', text: `Choice A ${index}` },
      { id: 'b', text: `Choice B ${index}` },
      { id: 'c', text: `Choice C ${index}` },
      { id: 'd', text: `Choice D ${index}` },
    ],
    answerKey: 'b',
    explanation: 'Choice B is the verified correct answer.',
    difficulty: 'medium',
    modes: ['competitive'],
    points: 10,
    deterministic: true,
    duplicateFingerprint: `fingerprint-${index}`,
    aiCategory: categoryId === 'general-knowledge' ? 'sports' : 'cinema',
  };
}

async function setup({ role = 'admin', questionGenerator } = {}) {
  const collections = {
    quiz_categories: new MemoryCollection(),
    questions: new MemoryCollection(),
    exams: new MemoryCollection(),
    exam_attempts: new MemoryCollection(),
    exam_results: new MemoryCollection(),
    exam_achievements: new MemoryCollection(),
    ai_generation_jobs: new MemoryCollection(),
  };
  const users = new MemoryCollection([
    {
      _id: adminId,
      fullName: 'Test Admin',
      username: 'test_admin',
      email: 'admin@example.test',
      role,
    },
  ]);
  if (role !== 'admin') {
    users.documents[0]._id = userId;
  }
  const app = createApp({
    authTokenSecret,
    usersCollection: () => users,
    database: () => ({ collection: (name) => collections[name] }),
    questionGenerator:
      questionGenerator ??
      (async ({ count, categoryId }) => ({
        questions: Array.from({ length: count }, (_, index) =>
          buildDraft(index, categoryId === 'sports' ? 'general-knowledge' : 'entertainment'),
        ),
        usage: { inputTokens: 10, outputTokens: 20 },
        model: 'test-model',
        estimatedCostUsd: 0.0001,
      })),
  });
  const server = app.listen(0, '127.0.0.1');
  servers.add(server);
  await new Promise((resolve) => server.once('listening', resolve));
  const subject = role === 'admin' ? adminId : userId;
  const token = jwt.sign({}, authTokenSecret, {
    algorithm: 'HS256',
    audience: 'dailyduel-app',
    expiresIn: '1h',
    issuer: 'dailyduel-api',
    subject: subject.toString(),
  });
  return {
    collections,
    baseUrl: `http://127.0.0.1:${server.address().port}/api/v1/admin/quizzes`,
    headers: {
      authorization: `Bearer ${token}`,
      'content-type': 'application/json',
    },
  };
}

test('admin AI generation saves exactly fifteen drafts and replays idempotently', async () => {
  let generationCalls = 0;
  const context = await setup({
    questionGenerator: async ({ count, categoryId }) => {
      generationCalls += 1;
      return {
        questions: Array.from({ length: count }, (_, index) =>
          buildDraft(index, categoryId === 'sports' ? 'general-knowledge' : 'entertainment'),
        ),
        usage: { inputTokens: 10, outputTokens: 20 },
        model: 'test-model',
        estimatedCostUsd: 0.0001,
      };
    },
  });
  const request = {
    requestId: 'c844c5ab-1aef-4a2d-b95b-23fb479feb2e',
    category: 'sports',
    difficulty: 'mixed',
  };
  const first = await fetch(`${context.baseUrl}/questions/generate`, {
    method: 'POST',
    headers: context.headers,
    body: JSON.stringify(request),
  });
  const result = await first.json();

  assert.equal(first.status, 201);
  assert.equal(result.questionsCreated, 15);
  assert.equal(context.collections.questions.documents.length, 15);
  assert.ok(
    context.collections.questions.documents.every(
      (question) =>
        question.status === 'draft' &&
        question.generatedBy === 'ai' &&
        question.options.length === 4,
    ),
  );
  assert.equal(JSON.stringify(result).includes('OPENAI_API_KEY'), false);

  const replay = await fetch(`${context.baseUrl}/questions/generate`, {
    method: 'POST',
    headers: context.headers,
    body: JSON.stringify(request),
  });
  assert.equal(replay.status, 200);
  assert.equal((await replay.json()).replayed, true);
  assert.equal(generationCalls, 1);
  assert.equal(context.collections.questions.documents.length, 15);

  const schedule = await fetch(`${context.baseUrl}/exams`, {
    method: 'POST',
    headers: context.headers,
    body: JSON.stringify({
      title: 'Future exam',
      description: '',
      categoryId: 'general-knowledge',
      scheduledAt: new Date(Date.now() + 60_000).toISOString(),
      questionIds: result.questionIds,
    }),
  });
  assert.equal(schedule.status, 400);
});

test('simultaneous AI generation requests cannot persist duplicate fingerprints', async () => {
  let generatorCalls = 0;
  let releaseGenerators;
  const bothGeneratorsStarted = new Promise((resolve) => {
    releaseGenerators = resolve;
  });
  const setupResult = await setup({
    questionGenerator: async ({ count, categoryId }) => {
      const generation = ++generatorCalls;
      if (generatorCalls === 2) releaseGenerators();
      await bothGeneratorsStarted;
      return {
        questions: Array.from({ length: count }, (_, index) => {
          const sharedQuestion = index === 7;
          return buildDraft(
            sharedQuestion ? 'shared' : `${generation}-${index}`,
            categoryId === 'sports' ? 'general-knowledge' : 'entertainment',
          );
        }),
        provider: 'gemini',
        model: 'test-model',
      };
    },
  });

  const request = (requestId) =>
    fetch(`${setupResult.baseUrl}/questions/generate`, {
      method: 'POST',
      headers: setupResult.headers,
      body: JSON.stringify({
        requestId,
        category: 'sports',
        difficulty: 'mixed',
      }),
    });
  const responses = await Promise.all([
    request('60000000-0000-4000-8000-000000000001'),
    request('60000000-0000-4000-8000-000000000002'),
  ]);
  const results = await Promise.all(
    responses.map(async (response) => ({
      status: response.status,
      body: await response.json(),
    })),
  );

  assert.deepEqual(results.map((result) => result.status).sort(), [201, 409]);
  assert.equal(
    results.find((result) => result.status === 409).body.error.code,
    'DUPLICATE_GENERATED_QUESTIONS',
  );
  const savedQuestions = setupResult.collections.questions.documents;
  assert.equal(savedQuestions.length, 15);
  assert.equal(
    new Set(savedQuestions.map((question) => question.aiDuplicateFingerprint)).size,
    15,
  );
  assert.equal(
    savedQuestions.filter((question) =>
      question.questionText.includes('shared'),
    ).length,
    1,
  );
  assert.equal(
    savedQuestions.filter(
      (question) =>
        question.generationRequestId ===
        '60000000-0000-4000-8000-000000000002',
    ).length,
    0,
  );
});

test('rejected questions can only be regenerated into drafts for later approval', async () => {
  let callCount = 0;
  const context = await setup({
    questionGenerator: async ({ count, categoryId }) => {
      callCount += 1;
      return {
        questions: Array.from({ length: count }, (_, index) =>
          buildDraft(index + callCount * 100, categoryId === 'sports' ? 'general-knowledge' : 'entertainment'),
        ),
        model: 'test-model',
      };
    },
  });
  const generate = await fetch(`${context.baseUrl}/questions/generate`, {
    method: 'POST',
    headers: context.headers,
    body: JSON.stringify({
      requestId: '3eef5d46-2870-4b3b-b448-720744d295d0',
      category: 'sports',
    }),
  });
  const generated = await generate.json();
  const questionId = generated.questionIds[0];

  const reject = await fetch(`${context.baseUrl}/questions/${questionId}/reject`, {
    method: 'POST',
    headers: context.headers,
    body: JSON.stringify({}),
  });
  assert.equal(reject.status, 200);
  const replacement = await fetch(
    `${context.baseUrl}/questions/${questionId}/regenerate`,
    {
      method: 'POST',
      headers: context.headers,
      body: JSON.stringify({
        requestId: '0e41b0f4-8660-4e06-9cdb-bcd80b3b1a9c',
      }),
    },
  );
  const replacementBody = await replacement.json();

  assert.equal(replacement.status, 201);
  assert.equal(replacementBody.questionsCreated, 1);
  assert.equal(callCount, 2);
  const replacementDraft = context.collections.questions.documents.find(
    (question) => question._id.toString() === replacementBody.questionIds[0],
  );
  assert.equal(replacementDraft.status, 'draft');
  assert.equal(replacementDraft.regeneratedFrom, questionId);

  const approve = await fetch(`${context.baseUrl}/questions/${questionId}/publish`, {
    method: 'POST',
    headers: context.headers,
    body: JSON.stringify({}),
  });
  assert.equal(approve.status, 409);
  assert.equal(replacementDraft.status, 'draft');
});

test('AI generation endpoints remain protected by administrator authentication', async () => {
  let generationCalls = 0;
  const context = await setup({
    role: 'user',
    questionGenerator: async () => {
      generationCalls += 1;
      return { questions: [] };
    },
  });
  const response = await fetch(`${context.baseUrl}/questions/generate`, {
    method: 'POST',
    headers: context.headers,
    body: JSON.stringify({
      requestId: 'c844c5ab-1aef-4a2d-b95b-23fb479feb2e',
      category: 'sports',
    }),
  });

  assert.equal(response.status, 403);
  assert.equal(generationCalls, 0);
});

test('AI generation without a key returns a safe configuration error and saves no questions', async () => {
  const context = await setup({
    questionGenerator: createOpenAIQuestionGenerator({
      logger: { info() {}, warn() {} },
    }),
  });
  const response = await fetch(`${context.baseUrl}/questions/generate`, {
    method: 'POST',
    headers: context.headers,
    body: JSON.stringify({
      requestId: '4a91a1e2-25e5-4e15-8f00-39b850f29037',
      category: 'sports',
    }),
  });
  const body = await response.json();

  assert.equal(response.status, 503);
  assert.equal(body.error.code, 'AI_NOT_CONFIGURED');
  assert.match(body.error.message, /Set OPENAI_API_KEY in the backend environment/);
  assert.equal(context.collections.questions.documents.length, 0);
  assert.equal(JSON.stringify(body).includes('apiKey'), false);
});

test('invalid generated category data is rejected before any question is saved', async () => {
  const context = await setup({
    questionGenerator: async ({ count }) => ({
      questions: Array.from({ length: count }, (_, index) => ({
        ...buildDraft(index),
        subcategory: 'Politics',
      })),
    }),
  });
  const response = await fetch(`${context.baseUrl}/questions/generate`, {
    method: 'POST',
    headers: context.headers,
    body: JSON.stringify({
      requestId: '4a91a1e2-25e5-4e15-8f00-39b850f29037',
      category: 'sports',
    }),
  });
  const body = await response.json();

  assert.equal(response.status, 502);
  assert.equal(body.error.code, 'AI_INVALID_RESPONSE');
  assert.equal(context.collections.questions.documents.length, 0);
  assert.equal(
    context.collections.ai_generation_jobs.documents[0].status,
    'failed',
  );
});
