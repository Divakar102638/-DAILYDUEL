const assert = require('node:assert/strict');
const jwt = require('jsonwebtoken');
const { ObjectId } = require('mongodb');
const { after, test } = require('node:test');
const { createApp } = require('../src/app');
const { DEFAULT_CATEGORIES } = require('../src/quiz/catalog');
const {
  publicQuestion,
  scoreQuestion,
  validateQuestion,
  QuizValidationError,
} = require('../src/quiz/validation');
const { createQuestionDraftGenerator } = require('../src/quiz/question-generator');

const servers = new Set();
const authTokenSecret = 'test-only-auth-token-secret-at-least-32-bytes';

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

function question(overrides = {}) {
  return {
    categoryId: 'fun-entertainment',
    subcategory: 'Funny quizzes',
    questionText: 'Which option is the funniest?',
    type: 'multiple_choice',
    options: [
      { id: 'a', text: 'Option A' },
      { id: 'b', text: 'Option B' },
    ],
    answerKey: 'b',
    explanation: 'Option B was the configured answer.',
    difficulty: 'easy',
    modes: ['casual', 'competitive'],
    points: 10,
    ...overrides,
  };
}

test('default backend taxonomy covers the requested quiz families', () => {
  const categories = new Map(DEFAULT_CATEGORIES.map((item) => [item.id, item]));
  assert.deepEqual(
    [...categories.keys()],
    [
      'fun-entertainment',
      'entertainment',
      'brain-games',
      'general-knowledge',
      'technology-career',
      'lifestyle',
    ],
  );
  assert.ok(
    categories
      .get('fun-entertainment')
      .subcategories.includes('Guess the movie from emojis'),
  );
  assert.ok(
    categories
      .get('technology-career')
      .subcategories.includes('Docker and Kubernetes'),
  );
  assert.ok(
    categories
      .get('lifestyle')
      .subcategories.includes('Entertainment-only personality quizzes'),
  );
});

test('question validation accepts supported deterministic formats and rejects competitive personality scoring', () => {
  for (const type of [
    'multiple_choice',
    'scenario',
    'image_identification',
    'true_false',
    'riddle',
    'emoji_guess',
  ]) {
    const base = question({
      type,
      ...(type === 'image_identification'
        ? {
            image: {
              url: 'https://images.example.test/licensed.jpg',
              source: 'Licensed source',
              license: 'CC BY 4.0',
            },
          }
        : {}),
      ...(type === 'true_false'
        ? {
            options: [
              { id: 'true', text: 'True' },
              { id: 'false', text: 'False' },
            ],
            answerKey: true,
          }
        : {}),
      ...(['riddle', 'emoji_guess'].includes(type)
        ? { options: [], answerKey: 'answer' }
        : {}),
    });
    assert.equal(validateQuestion(base).type, type);
  }

  assert.throws(
    () =>
      validateQuestion(
        question({
          type: 'personality_preference',
          options: [
            { id: 'a', text: 'A' },
            { id: 'b', text: 'B' },
          ],
          answerKey: { a: 'creative', b: 'practical' },
        }),
      ),
    QuizValidationError,
  );
});

test('image question requires license provenance and duplicate fingerprint normalizes whitespace', () => {
  assert.throws(
    () =>
      validateQuestion(
        question({
          type: 'image_identification',
          image: {
            url: 'https://images.example.test/image.jpg',
            source: 'Source',
          },
        }),
      ),
    /HTTPS image URL, source, and license/,
  );
  const first = validateQuestion(question());
  const second = validateQuestion(
    question({ questionText: '  WHICH   OPTION IS THE FUNNIEST? ' }),
  );
  assert.equal(first.duplicateFingerprint, second.duplicateFingerprint);
});

test('public question representation never includes the answer key', () => {
  const privateQuestion = {
    ...validateQuestion(question()),
    _id: new ObjectId(),
  };
  const publicView = publicQuestion(privateQuestion);

  assert.equal(publicView.questionText, question().questionText);
  assert.equal(Object.hasOwn(publicView, 'answerKey'), false);
  assert.equal(Object.hasOwn(publicView, 'explanation'), false);
  assert.deepEqual(scoreQuestion(privateQuestion, 'b'), { correct: true });
  assert.deepEqual(scoreQuestion(privateQuestion, 'a'), { correct: false });
});

test('AI generator interface returns drafts and does not publish them', async () => {
  const generate = createQuestionDraftGenerator({
    generate: async () => [question({ modes: ['casual'] })],
  });
  const [draft] = await generate({ topic: 'fun' });

  assert.equal(draft.status, 'draft');
  assert.equal(draft.generatedBy, 'ai');
  assert.equal(draft.publishedAt, null);
});

test('quiz categories are served from backend configuration and custom categories', async () => {
  const categories = [
    {
      _id: 'my-new-category',
      name: 'Community Picks',
      subcategories: ['Local trivia'],
      active: true,
    },
    {
      _id: 'lifestyle',
      name: 'Lifestyle',
      subcategories: ['Travel'],
      active: false,
    },
  ];
  const app = createApp({
    checkDatabase: async () => {},
    authTokenSecret,
    usersCollection: () => ({ findOne: async () => null }),
    database: () => ({
      collection: (name) => ({
        find: () => ({
          toArray: async () => (name === 'quiz_categories' ? categories : []),
        }),
      }),
    }),
  });
  const server = app.listen(0, '127.0.0.1');
  servers.add(server);
  await new Promise((resolve) => server.once('listening', resolve));

  const response = await fetch(
    `http://127.0.0.1:${server.address().port}/api/v1/quizzes/categories`,
  );
  const body = await response.json();

  assert.equal(response.status, 200);
  assert.ok(body.categories.some((category) => category.id === 'my-new-category'));
  assert.equal(body.categories.some((category) => category.id === 'lifestyle'), false);
});

test('only administrators can create and publish quiz questions', async () => {
  const userId = new ObjectId();
  const questionId = new ObjectId();
  const document = { ...validateQuestion(question()), _id: questionId };
  let user = {
    _id: userId,
    fullName: 'Quiz User',
    username: 'quiz_user',
    email: 'quiz@example.test',
    role: 'user',
  };
  const questions = {
    async findOne(query) {
      return query._id?.equals(questionId) ? document : null;
    },
    async insertOne(value) {
      Object.assign(document, value);
      return { insertedId: questionId };
    },
    async updateOne(_query, update) {
      Object.assign(document, update.$set);
      return { modifiedCount: 1 };
    },
    find() {
      return {
        limit() {
          return this;
        },
        async toArray() {
          return [document];
        },
      };
    },
  };
  const app = createApp({
    checkDatabase: async () => {},
    authTokenSecret,
    usersCollection: () => ({ findOne: async () => user }),
    database: () => ({
      collection: (name) =>
        name === 'questions'
          ? questions
          : {
              findOne: async () => null,
              find: () => ({ toArray: async () => [] }),
            },
    }),
  });
  const server = app.listen(0, '127.0.0.1');
  servers.add(server);
  await new Promise((resolve) => server.once('listening', resolve));
  const endpoint = `http://127.0.0.1:${server.address().port}/api/v1/admin/quizzes/questions`;
  const token = (subject) =>
    jwt.sign({}, authTokenSecret, {
      algorithm: 'HS256',
      audience: 'dailyduel-app',
      expiresIn: '1h',
      issuer: 'dailyduel-api',
      subject,
    });

  const denied = await fetch(endpoint, {
    method: 'POST',
    headers: {
      authorization: `Bearer ${token(userId.toString())}`,
      'content-type': 'application/json',
    },
    body: JSON.stringify(question()),
  });
  assert.equal(denied.status, 403);

  user = { ...user, role: 'admin' };
  const created = await fetch(endpoint, {
    method: 'POST',
    headers: {
      authorization: `Bearer ${token(userId.toString())}`,
      'content-type': 'application/json',
    },
    body: JSON.stringify(question()),
  });
  assert.equal(created.status, 201);
  assert.equal(document.status, 'draft');

  const published = await fetch(
    `${endpoint}/${questionId.toString()}/publish`,
    {
      method: 'POST',
      headers: { authorization: `Bearer ${token(userId.toString())}` },
    },
  );
  assert.equal(published.status, 200);
  assert.equal(document.status, 'published');
  assert.equal(document.reviewedBy, userId.toString());
});

test('casual sessions hide answer keys and return server-scored explanations', async () => {
  const userId = new ObjectId();
  const questionId = new ObjectId();
  const questionDocument = {
    _id: questionId,
    categoryId: 'fun-entertainment',
    subcategory: 'Funny quizzes',
    questionText: 'Which answer is configured as correct?',
    type: 'multiple_choice',
    options: [
      { id: 'a', text: 'Not this one' },
      { id: 'b', text: 'This one' },
    ],
    answerKey: 'b',
    explanation: 'The server evaluates the answer key.',
    difficulty: 'easy',
    timeLimitSeconds: null,
    points: 10,
    modes: ['casual'],
    status: 'published',
  };
  const sessions = [];
  const questions = {
    find(query, options = {}) {
      const filter = (question) =>
        (!query.categoryId || question.categoryId === query.categoryId) &&
        (!query.status || question.status === query.status) &&
        (!query.modes || question.modes.includes(query.modes)) &&
        (!query._id?.$in || query._id.$in.some((id) => id.equals(question._id)));
      return {
        limit() {
          return this;
        },
        async toArray() {
          const found = [questionDocument].filter(filter);
          if (options.projection?.answerKey === 0) {
            return found.map(({ answerKey, duplicateFingerprint, createdBy, ...safe }) => safe);
          }
          return found;
        },
      };
    },
    async findOne(query) {
      return query._id.equals(questionId) ? questionDocument : null;
    },
  };
  const sessionCollection = {
    async insertOne(document) {
      const stored = { ...document, _id: new ObjectId() };
      sessions.push(stored);
      return { insertedId: stored._id };
    },
    async findOne(query) {
      return (
        sessions.find(
          (session) =>
            session._id.equals(query._id) && session.userId === query.userId,
        ) ?? null
      );
    },
    async updateOne(query, update) {
      const session = sessions.find(
        (item) => item._id.equals(query._id) && item.result === query.result,
      );
      if (!session) return { modifiedCount: 0 };
      for (const [path, value] of Object.entries(update.$set)) {
        const [, answerId] = path.split('.');
        if (answerId) session.answers[answerId] = value;
        else session[path] = value;
      }
      return { modifiedCount: 1 };
    },
  };
  const user = {
    _id: userId,
    fullName: 'Quiz User',
    username: 'quiz_user',
    email: 'quiz@example.test',
    role: 'user',
  };
  const app = createApp({
    checkDatabase: async () => {},
    authTokenSecret,
    usersCollection: () => ({ findOne: async () => user }),
    database: () => ({
      collection: (name) =>
        name === 'questions' ? questions : sessionCollection,
    }),
  });
  const server = app.listen(0, '127.0.0.1');
  servers.add(server);
  await new Promise((resolve) => server.once('listening', resolve));
  const baseUrl = `http://127.0.0.1:${server.address().port}/api/v1`;
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

  const start = await fetch(`${baseUrl}/quizzes/casual/sessions`, {
    method: 'POST',
    headers,
    body: JSON.stringify({
      categoryId: 'fun-entertainment',
      questionCount: 1,
      timerSeconds: 60,
    }),
  });
  assert.equal(start.status, 201);
  const session = await start.json();
  assert.equal(Object.hasOwn(session.questions[0], 'answerKey'), false);

  const save = await fetch(
    `${baseUrl}/quizzes/casual/sessions/${session.sessionId}/answers`,
    {
      method: 'POST',
      headers,
      body: JSON.stringify({ questionId: questionId.toString(), answer: 'b' }),
    },
  );
  assert.equal(save.status, 200);

  const submit = await fetch(
    `${baseUrl}/quizzes/casual/sessions/${session.sessionId}/submit`,
    { method: 'POST', headers },
  );
  const result = await submit.json();
  assert.equal(submit.status, 200);
  assert.equal(result.score, 10);
  assert.equal(result.correctCount, 1);
  assert.equal(result.review[0].correctAnswer, 'This one');
  assert.equal(result.review[0].explanation, questionDocument.explanation);
});
