const express = require('express');
const { ObjectId } = require('mongodb');
const { getDatabase, getUsersCollection } = require('../db/mongo');
const { createAuthMiddleware, requireAdmin } = require('../middleware/auth');
const { DEFAULT_CATEGORIES, publicCategory } = require('../quiz/catalog');
const {
  QuizValidationError,
  validateQuestion,
} = require('../quiz/validation');

const QUESTION_STATUSES = new Set([
  'draft',
  'pending_review',
  'published',
  'archived',
]);
const EXAM_STATUSES = new Set([
  'scheduled',
  'open',
  'closed',
  'results_published',
  'archived',
]);

function createAdminQuizRouter({
  usersCollection = getUsersCollection,
  getCollection = (name) => getDatabase().collection(name),
  authTokenSecret = process.env.AUTH_TOKEN_SECRET,
  now = () => new Date(),
} = {}) {
  const router = express.Router();
  router.use(createAuthMiddleware({ usersCollection, authTokenSecret }), requireAdmin);

  router.get('/categories', async (_request, response) => {
    const stored = await getCollection('quiz_categories').find({}).toArray();
    const configured = new Map(DEFAULT_CATEGORIES.map((item) => [item.id, item]));
    for (const category of stored) {
      configured.set(String(category._id), category);
    }
    response.json({ categories: [...configured.values()].map(publicCategory) });
  });

  router.put('/categories/:categoryId', async (request, response) => {
    const categoryId = request.params.categoryId;
    const { name, subcategories, active } = request.body || {};
    if (
      !/^[a-z0-9][a-z0-9-]{1,79}$/.test(categoryId) ||
      typeof name !== 'string' ||
      name.trim().length < 2 ||
      name.trim().length > 80 ||
      !Array.isArray(subcategories) ||
      subcategories.length > 100 ||
      subcategories.some(
        (item) =>
          typeof item !== 'string' ||
          item.trim().length < 1 ||
          item.trim().length > 100,
      ) ||
      (active !== undefined && typeof active !== 'boolean')
    ) {
      throw new QuizValidationError('Category configuration is invalid.');
    }
    const category = {
      name: name.trim(),
      subcategories: [...new Set(subcategories.map((item) => item.trim()))],
      active: active ?? true,
      updatedAt: now(),
    };
    await getCollection('quiz_categories').updateOne(
      { _id: categoryId },
      {
        $set: category,
        $setOnInsert: { createdAt: category.updatedAt },
      },
      { upsert: true },
    );
    response.json({ category: publicCategory({ _id: categoryId, ...category }) });
  });

  router.get('/exams', async (request, response) => {
    const page = parsePositiveInteger(request.query.page, 1, 100_000);
    const pageSize = parsePositiveInteger(request.query.pageSize, 25, 100);
    const status = request.query.status;
    if (status !== undefined && (typeof status !== 'string' || !EXAM_STATUSES.has(status))) {
      throw new QuizValidationError('Exam status filter is invalid.');
    }
    const search =
      typeof request.query.search === 'string'
        ? request.query.search.trim().slice(0, 100)
        : '';
    const filter = {
      ...(status ? { status } : {}),
      ...(search ? { title: new RegExp(escapeRegExp(search), 'i') } : {}),
    };
    const examsCollection = getCollection('exams');
    const currentTime = now();
    const timeWindowStart = new Date(currentTime.getTime() - 450_000);
    if (status === 'scheduled') {
      filter.status = 'scheduled';
      filter.scheduledAt = { $gt: currentTime };
    } else if (status === 'open') {
      filter.status = { $nin: ['results_published', 'archived'] };
      filter.scheduledAt = { $lte: currentTime, $gt: timeWindowStart };
    } else if (status === 'closed') {
      filter.status = { $nin: ['results_published', 'archived'] };
      filter.scheduledAt = { $lte: timeWindowStart };
    }
    const [exams, total] = await Promise.all([
      examsCollection
        .find(filter)
        .sort({ scheduledAt: -1 })
        .skip((page - 1) * pageSize)
        .limit(pageSize)
        .toArray(),
      examsCollection.countDocuments(filter),
    ]);
    const mapped = await Promise.all(
      exams.map(async (exam) => {
        const attempts = await getCollection('exam_attempts').countDocuments({
          examId: exam._id,
        });
        const isPublished = exam.resultsPublishedAt != null;
        const isScheduled = new Date(exam.scheduledAt) > currentTime;
        const isOpen =
          !isPublished &&
          exam.status !== 'archived' &&
          !isScheduled &&
          currentTime < new Date(new Date(exam.scheduledAt).getTime() + 450_000);
        return {
          id: exam._id.toString(),
          title: exam.title,
          description: exam.description,
          categoryId: exam.categoryId,
          scheduledAt: exam.scheduledAt,
          status: isPublished
            ? 'results_published'
            : exam.status === 'archived'
              ? 'archived'
              : isScheduled
                ? 'scheduled'
                : isOpen
                  ? 'open'
                  : 'closed',
          questionCount: exam.questions?.length ?? 0,
          totalMarks: (exam.questions ?? []).reduce(
            (sum, question) =>
              sum + (Number.isFinite(question.points) ? question.points : 0),
            0,
          ),
          attempts,
          prize: exam.prize ?? null,
        };
      }),
    );
    response.json({
      exams: mapped,
      pagination: { page, pageSize, total, pageCount: Math.ceil(total / pageSize) },
    });
  });

  router.patch('/exams/:examId', async (request, response) => {
    if (!ObjectId.isValid(request.params.examId)) {
      response.status(404).json({
        error: { code: 'EXAM_NOT_FOUND', message: 'Exam was not found.' },
      });
      return;
    }
    const exams = getCollection('exams');
    const exam = await exams.findOne({
      _id: new ObjectId(request.params.examId),
    });
    const editableBefore = now();
    if (!exam) {
      response.status(404).json({
        error: { code: 'EXAM_NOT_FOUND', message: 'Exam was not found.' },
      });
      return;
    }
    if (
      exam.status !== 'scheduled' ||
      exam.scheduledAt <= editableBefore ||
      (await getCollection('exam_attempts').countDocuments({
        examId: exam._id,
      })) > 0
    ) {
      response.status(409).json({
        error: {
          code: 'EXAM_LOCKED',
          message: 'Only scheduled exams without attempts can be edited.',
        },
      });
      return;
    }
    const body = request.body || {};
    const title = body.title ?? exam.title;
    const description = body.description ?? exam.description;
    const categoryId = body.categoryId ?? exam.categoryId;
    const scheduledAt = body.scheduledAt ?? exam.scheduledAt;
    if (categoryId !== exam.categoryId) {
      throw new QuizValidationError(
        'An exam category cannot change without replacing its question set.',
      );
    }
    if (
      typeof title !== 'string' ||
      title.trim().length < 3 ||
      title.trim().length > 120 ||
      typeof description !== 'string' ||
      description.trim().length > 1000 ||
      typeof categoryId !== 'string' ||
      typeof scheduledAt !== 'string' && !(scheduledAt instanceof Date) ||
      !Number.isFinite(new Date(scheduledAt).getTime()) ||
      new Date(scheduledAt) <= now()
    ) {
      throw new QuizValidationError('Exam update details are invalid.');
    }
    const category = await findCategory(getCollection, categoryId);
    if (!category || category.active === false) {
      throw new QuizValidationError('Exam category is not configured or active.');
    }
    const update = {
      title: title.trim(),
      description: description.trim(),
      categoryId,
      scheduledAt: new Date(scheduledAt),
      updatedAt: now(),
    };
    const saved = await exams.updateOne(
      {
        _id: exam._id,
        status: 'scheduled',
        scheduledAt: { $gt: editableBefore },
      },
      { $set: update },
    );
    if (saved.modifiedCount !== 1) {
      response.status(409).json({
        error: {
          code: 'EXAM_LOCKED',
          message: 'The exam can no longer be edited.',
        },
      });
      return;
    }
    response.json({ examId: exam._id.toString(), ...update });
  });

  router.patch('/exams/:examId/archive', async (request, response) => {
    if (!ObjectId.isValid(request.params.examId)) {
      response.status(404).json({
        error: { code: 'EXAM_NOT_FOUND', message: 'Exam was not found.' },
      });
      return;
    }
    const exams = getCollection('exams');
    const exam = await exams.findOne({
      _id: new ObjectId(request.params.examId),
    });
    const editableBefore = now();
    if (!exam) {
      response.status(404).json({
        error: { code: 'EXAM_NOT_FOUND', message: 'Exam was not found.' },
      });
      return;
    }
    if (
      exam.status !== 'scheduled' ||
      exam.scheduledAt <= editableBefore ||
      (await getCollection('exam_attempts').countDocuments({
        examId: exam._id,
      })) > 0
    ) {
      response.status(409).json({
        error: {
          code: 'EXAM_LOCKED',
          message: 'Only scheduled exams without attempts can be archived.',
        },
      });
      return;
    }
    const archived = await exams.updateOne(
      {
        _id: exam._id,
        status: 'scheduled',
        scheduledAt: { $gt: editableBefore },
      },
      { $set: { status: 'archived', archivedAt: now() } },
    );
    if (archived.modifiedCount !== 1) {
      response.status(409).json({
        error: {
          code: 'EXAM_LOCKED',
          message: 'The exam can no longer be archived.',
        },
      });
      return;
    }
    response.json({ examId: exam._id.toString(), status: 'archived' });
  });

  router.get('/exams/:examId/results', async (request, response) => {
    if (!ObjectId.isValid(request.params.examId)) {
      response.status(404).json({
        error: { code: 'EXAM_NOT_FOUND', message: 'Exam was not found.' },
      });
      return;
    }
    const examId = new ObjectId(request.params.examId);
    const exam = await getCollection('exams').findOne({ _id: examId });
    if (!exam) {
      response.status(404).json({
        error: { code: 'EXAM_NOT_FOUND', message: 'Exam was not found.' },
      });
      return;
    }
    if (!exam.resultsPublishedAt || now() < exam.resultsPublishedAt) {
      response.status(409).json({
        error: {
          code: 'RESULTS_NOT_PUBLISHED',
          message: 'Exam results are not available yet.',
        },
      });
      return;
    }
    const page = parsePositiveInteger(request.query.page, 1, 100_000);
    const pageSize = parsePositiveInteger(request.query.pageSize, 25, 100);
    const resultsCollection = getCollection('exam_results');
    const [results, total] = await Promise.all([
      resultsCollection
        .find({ examId })
        .sort({ rank: 1 })
        .skip((page - 1) * pageSize)
        .limit(pageSize)
        .toArray(),
      resultsCollection.countDocuments({ examId }),
    ]);
    response.json({
      exam: {
        id: exam._id.toString(),
        title: exam.title,
        categoryId: exam.categoryId,
        resultsPublishedAt: exam.resultsPublishedAt,
      },
      results: results.map((result) => ({
        rank: result.rank,
        fullName: result.fullName,
        username: result.username,
        score: result.score,
        correctCount: result.correctCount,
        answeredCount: result.answeredCount,
        totalQuestions: result.totalQuestions,
        submittedAt: result.submittedAt,
      })),
      pagination: { page, pageSize, total, pageCount: Math.ceil(total / pageSize) },
    });
  });

  router.post('/questions', async (request, response) => {
    const question = validateQuestion(request.body);
    const storedCategory = await getCollection('quiz_categories').findOne({
      _id: question.categoryId,
    });
    const category =
      storedCategory ?? DEFAULT_CATEGORIES.find((item) => item.id === question.categoryId);
    if (
      !category ||
      category.active === false ||
      !category.subcategories?.includes(question.subcategory)
    ) {
      response.status(400).json({
        error: {
          code: 'UNKNOWN_CATEGORY',
          message: 'Question category or subcategory is not configured or active.',
        },
      });
      return;
    }
    const questions = getCollection('questions');
    const duplicate = await questions.findOne({
      duplicateFingerprint: question.duplicateFingerprint,
      status: { $ne: 'rejected' },
    });
    if (duplicate) {
      response.status(409).json({
        error: {
          code: 'DUPLICATE_QUESTION',
          message: 'A matching question already exists.',
        },
      });
      return;
    }
    const document = {
      ...question,
      status: 'draft',
      createdBy: request.authenticatedUser.id,
      createdAt: now(),
      updatedAt: now(),
    };
    const inserted = await questions.insertOne(document);
    response.status(201).json({
      questionId: inserted.insertedId.toString(),
      status: document.status,
    });
  });

  router.post('/questions/bulk', async (request, response) => {
    const entries = request.body?.questions;
    if (!Array.isArray(entries) || entries.length < 1 || entries.length > 100) {
      throw new QuizValidationError(
        'Bulk import requires between 1 and 100 questions.',
      );
    }
    const created = [];
    const duplicates = [];
    const invalid = [];
    const fingerprints = new Set();
    const questions = getCollection('questions');
    for (const [index, input] of entries.entries()) {
      try {
        const question = validateQuestion(input);
        const fingerprint = question.duplicateFingerprint;
        if (
          fingerprints.has(fingerprint) ||
          (await questions.findOne({
            duplicateFingerprint: fingerprint,
            status: { $ne: 'rejected' },
          }))
        ) {
          duplicates.push({ index, questionText: question.questionText });
          continue;
        }
        fingerprints.add(fingerprint);
        const category = await findCategory(getCollection, question.categoryId);
        if (
          !category ||
          category.active === false ||
          !category.subcategories?.includes(question.subcategory)
        ) {
          invalid.push({
            index,
            message: 'Question category or subcategory is not configured or active.',
          });
          continue;
        }
        const document = {
          ...question,
          status: 'draft',
          createdBy: request.authenticatedUser.id,
          createdAt: now(),
          updatedAt: now(),
        };
        const inserted = await questions.insertOne(document);
        created.push({
          index,
          questionId: inserted.insertedId.toString(),
          status: document.status,
        });
      } catch (error) {
        if (!(error instanceof QuizValidationError)) throw error;
        invalid.push({ index, message: error.message });
      }
    }
    response.status(201).json({ created, duplicates, invalid });
  });

  router.get('/questions', async (request, response) => {
    const status = request.query.status;
    if (
      status !== undefined &&
      (typeof status !== 'string' ||
        (status !== 'all' && !QUESTION_STATUSES.has(status)))
    ) {
      throw new QuizValidationError('Question status filter is invalid.');
    }
    const page = parsePositiveInteger(request.query.page, 1, 100_000);
    const pageSize = parsePositiveInteger(request.query.pageSize, 25, 100);
    const search =
      typeof request.query.search === 'string'
        ? request.query.search.trim().slice(0, 100)
        : '';
    const filter = {
      ...(status && status !== 'all'
        ? { status }
        : status === 'all'
          ? {}
          : { status: { $in: ['draft', 'pending_review'] } }),
      ...(search ? { questionText: new RegExp(escapeRegExp(search), 'i') } : {}),
    };
    const questionCollection = getCollection('questions');
    const [documents, total] = await Promise.all([
      questionCollection
        .find(filter)
        .sort({ updatedAt: -1 })
        .skip((page - 1) * pageSize)
        .limit(pageSize)
        .toArray(),
      questionCollection.countDocuments(filter),
    ]);
    response.json({
      questions: documents.map((question) => ({
        ...question,
        id: question._id.toString(),
        _id: undefined,
        createdBy: undefined,
        reviewedBy: undefined,
        duplicateFingerprint: undefined,
      })),
      pagination: { page, pageSize, total, pageCount: Math.ceil(total / pageSize) },
    });
  });

  router.patch('/questions/:questionId', async (request, response) => {
    if (!ObjectId.isValid(request.params.questionId)) {
      response.status(404).json({
        error: { code: 'QUESTION_NOT_FOUND', message: 'Question not found.' },
      });
      return;
    }
    const questions = getCollection('questions');
    const questionId = new ObjectId(request.params.questionId);
    const existing = await questions.findOne({ _id: questionId });
    if (!existing) {
      response.status(404).json({
        error: { code: 'QUESTION_NOT_FOUND', message: 'Question not found.' },
      });
      return;
    }
    if (!['draft', 'pending_review'].includes(existing.status)) {
      response.status(409).json({
        error: {
          code: 'QUESTION_LOCKED',
          message: 'Published or archived questions cannot be edited.',
        },
      });
      return;
    }
    const question = validateQuestion(request.body);
    const category = await findCategory(getCollection, question.categoryId);
    if (
      !category ||
      category.active === false ||
      !category.subcategories?.includes(question.subcategory)
    ) {
      throw new QuizValidationError(
        'Question category or subcategory is not configured or active.',
      );
    }
    const duplicate = await questions.findOne({
      _id: { $ne: questionId },
      duplicateFingerprint: question.duplicateFingerprint,
      status: { $ne: 'rejected' },
    });
    if (duplicate) {
      response.status(409).json({
        error: {
          code: 'DUPLICATE_QUESTION',
          message: 'A matching question already exists.',
        },
      });
      return;
    }
    await questions.updateOne(
      { _id: questionId, status: existing.status },
      { $set: { ...question, updatedAt: now() } },
    );
    response.json({ questionId: questionId.toString(), status: existing.status });
  });

  router.patch('/questions/:questionId/archive', async (request, response) => {
    if (!ObjectId.isValid(request.params.questionId)) {
      response.status(404).json({
        error: { code: 'QUESTION_NOT_FOUND', message: 'Question not found.' },
      });
      return;
    }
    const questions = getCollection('questions');
    const questionId = new ObjectId(request.params.questionId);
    const question = await questions.findOne({ _id: questionId });
    if (!question) {
      response.status(404).json({
        error: { code: 'QUESTION_NOT_FOUND', message: 'Question not found.' },
      });
      return;
    }
    if (question.status === 'archived') {
      response.json({ questionId: questionId.toString(), status: 'archived' });
      return;
    }
    await questions.updateOne(
      { _id: questionId, status: question.status },
      { $set: { status: 'archived', updatedAt: now() } },
    );
    response.json({ questionId: questionId.toString(), status: 'archived' });
  });

  router.post('/questions/:questionId/publish', async (request, response) => {
    if (!ObjectId.isValid(request.params.questionId)) {
      response.status(404).json({
        error: { code: 'QUESTION_NOT_FOUND', message: 'Question not found.' },
      });
      return;
    }
    const questions = getCollection('questions');
    const question = await questions.findOne({
      _id: new ObjectId(request.params.questionId),
    });
    if (!question) {
      response.status(404).json({
        error: { code: 'QUESTION_NOT_FOUND', message: 'Question not found.' },
      });
      return;
    }
    if (question.modes.includes('competitive') && !question.deterministic) {
      response.status(400).json({
        error: {
          code: 'NON_DETERMINISTIC_COMPETITIVE_QUESTION',
          message: 'Competitive questions must have deterministic scoring.',
        },
      });
      return;
    }
    await questions.updateOne(
      { _id: question._id, status: { $in: ['draft', 'pending_review'] } },
      {
        $set: {
          status: 'published',
          reviewedBy: request.authenticatedUser.id,
          reviewedAt: now(),
          updatedAt: now(),
        },
      },
    );
    response.json({ questionId: question._id.toString(), status: 'published' });
  });

  router.post('/exams', async (request, response) => {
    const body = request.body || {};
    if (
      typeof body.title !== 'string' ||
      body.title.trim().length < 3 ||
      body.title.trim().length > 120 ||
      typeof body.description !== 'string' ||
      body.description.trim().length > 1000 ||
      typeof body.categoryId !== 'string' ||
      !Array.isArray(body.questionIds) ||
      body.questionIds.length !== 15 ||
      body.questionIds.some((id) => typeof id !== 'string' || !ObjectId.isValid(id)) ||
      new Set(body.questionIds).size !== 15 ||
      typeof body.scheduledAt !== 'string' ||
      !Number.isFinite(Date.parse(body.scheduledAt)) ||
      new Date(body.scheduledAt) <= now()
    ) {
      throw new QuizValidationError(
        'Exam requires a title, category, future start time, and exactly 15 distinct question IDs.',
      );
    }

    let prize = null;
    if (body.prize != null) {
      if (
        !body.prize ||
        typeof body.prize !== 'object' ||
        typeof body.prize.description !== 'string' ||
        body.prize.description.trim().length < 3 ||
        body.prize.description.trim().length > 500 ||
        body.prize.legalReviewConfirmed !== true
      ) {
        throw new QuizValidationError(
          'Prize configuration requires a description and confirmed legal review.',
        );
      }
      prize = {
        description: body.prize.description.trim(),
        legalReviewConfirmed: true,
      };
    }

    const questionIds = body.questionIds.map((id) => new ObjectId(id));
    const storedQuestions = await getCollection('questions')
      .find({
        _id: { $in: questionIds },
        status: 'published',
        modes: 'competitive',
        deterministic: true,
      })
      .toArray();
    const questionsById = new Map(
      storedQuestions.map((question) => [question._id.toString(), question]),
    );
    if (questionsById.size !== questionIds.length) {
      throw new QuizValidationError(
        'All exam questions must be published, competitive, and deterministic.',
      );
    }
    const storedCategory = await getCollection('quiz_categories').findOne({
      _id: body.categoryId,
    });
    const category =
      storedCategory ?? DEFAULT_CATEGORIES.find((item) => item.id === body.categoryId);
    if (!category || category.active === false) {
      throw new QuizValidationError('Exam category is not configured or active.');
    }

    const exam = {
      title: body.title.trim(),
      description: body.description.trim(),
      categoryId: body.categoryId,
      scheduledAt: new Date(body.scheduledAt),
      durationSeconds: 450,
      questionSeconds: 30,
      questionCount: 15,
      questions: questionIds.map((questionId) => {
        const source = questionsById.get(questionId.toString());
        return {
          _id: questionId,
          questionId,
          categoryId: source.categoryId,
          subcategory: source.subcategory,
          questionText: source.questionText,
          type: source.type,
          options: source.options,
          answerKey: source.answerKey,
          explanation: source.explanation,
          difficulty: source.difficulty,
          timeLimitSeconds: 30,
          points: source.points,
          image: source.image,
          deterministic: source.deterministic,
        };
      }),
      prize,
      status: 'scheduled',
      resultsPublishedAt: null,
      createdBy: request.authenticatedUser.id,
      createdAt: now(),
    };
    const inserted = await getCollection('exams').insertOne(exam);
    response.status(201).json({
      examId: inserted.insertedId.toString(),
      status: exam.status,
      scheduledAt: exam.scheduledAt,
      questionCount: exam.questionCount,
      durationSeconds: exam.durationSeconds,
    });
  });

  return router;
}

function parsePositiveInteger(value, fallback, maximum) {
  if (value === undefined) return fallback;
  const parsed = Number(value);
  if (!Number.isInteger(parsed) || parsed < 1 || parsed > maximum) {
    throw new QuizValidationError('Pagination values are invalid.');
  }
  return parsed;
}

function escapeRegExp(value) {
  return value.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
}

async function findCategory(getCollection, categoryId) {
  const stored = await getCollection('quiz_categories').findOne({
    _id: categoryId,
  });
  return stored ?? DEFAULT_CATEGORIES.find((item) => item.id === categoryId);
}

module.exports = { createAdminQuizRouter };
