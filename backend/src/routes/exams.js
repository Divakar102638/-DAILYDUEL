const express = require('express');
const { ObjectId } = require('mongodb');
const { getDatabase, getUsersCollection } = require('../db/mongo');
const { createAuthMiddleware } = require('../middleware/auth');
const { publicQuestion } = require('../quiz/validation');

const QUESTION_SECONDS = 30;
const EXAM_SECONDS = 450;

function createExamRouter({
  usersCollection = getUsersCollection,
  getCollection = (name) => getDatabase().collection(name),
  authTokenSecret = process.env.AUTH_TOKEN_SECRET,
  now = () => new Date(),
} = {}) {
  const router = express.Router();
  const authenticate = createAuthMiddleware({
    usersCollection,
    authTokenSecret,
  });

  router.get('/', async (_request, response) => {
    const currentTime = now();
    const exams = await getCollection('exams')
      .find({
        status: { $ne: 'archived' },
        scheduledAt: {
          $gte: new Date(currentTime.getTime() - EXAM_SECONDS * 1000),
        },
      })
      .project({
        title: 1,
        description: 1,
        categoryId: 1,
        scheduledAt: 1,
        status: 1,
        prize: 1,
        resultsPublishedAt: 1,
      })
      .sort({ scheduledAt: 1 })
      .limit(50)
      .toArray();
    response.json({
      exams: exams.map((exam) => ({
        id: exam._id.toString(),
        title: exam.title,
        description: exam.description,
        categoryId: exam.categoryId,
        scheduledAt: exam.scheduledAt,
        status:
          exam.resultsPublishedAt != null ||
          exam.status === 'results_published'
            ? 'results_published'
            : currentTime < exam.scheduledAt
              ? 'scheduled'
              : currentTime < new Date(exam.scheduledAt.getTime() + EXAM_SECONDS * 1000)
                ? 'open'
                : 'closed',
        prize: exam.prize ?? null,
      })),
    });
  });

  router.get('/history', authenticate, async (request, response) => {
    const userId = request.authenticatedUser.id;
    const attempts = await getCollection('exam_attempts')
      .find({ userId })
      .sort({ createdAt: -1 })
      .limit(100)
      .toArray();
    if (attempts.length === 0) {
      response.json({ history: [] });
      return;
    }

    const examIds = attempts
      .map((attempt) => attempt.examId)
      .filter((examId) => examId && ObjectId.isValid(examId));
    if (examIds.length === 0) {
      response.json({ history: [] });
      return;
    }
    const [exams, results] = await Promise.all([
      getCollection('exams').find({ _id: { $in: examIds } }).toArray(),
      getCollection('exam_results')
        .find({ userId, examId: { $in: examIds } })
        .toArray(),
    ]);
    const examsById = new Map(
      exams.map((exam) => [exam._id.toString(), exam]),
    );
    const resultsByExamId = new Map(
      results.map((result) => [result.examId.toString(), result]),
    );
    const currentTime = now();

    response.json({
      history: attempts.map((attempt) => {
        const examId = attempt.examId?.toString();
        const exam = examId ? examsById.get(examId) : null;
        const result = examId ? resultsByExamId.get(examId) : null;
        const validExam =
          exam &&
          typeof exam.title === 'string' &&
          exam.scheduledAt instanceof Date &&
          Number.isFinite(exam.scheduledAt.getTime()) &&
          Array.isArray(exam.questions);
        if (!validExam) {
          return {
            attemptId: attempt._id.toString(),
            examId: examId ?? 'unavailable',
            title: 'Exam unavailable',
            status: 'exam_unavailable',
            startedAt: attempt.createdAt ?? null,
            completedAt: attempt.scoredAt ?? result?.submittedAt ?? null,
            score: result?.score ?? null,
            totalMarks: null,
            correctCount: result?.correctCount ?? null,
            unansweredCount:
              result == null ||
              !Number.isFinite(result.totalQuestions) ||
              !Number.isFinite(result.answeredCount)
                ? null
                : Math.max(0, result.totalQuestions - result.answeredCount),
            rank: result?.rank ?? null,
            resultPublished: false,
          };
        }

        const closesAt = new Date(exam.scheduledAt.getTime() + EXAM_SECONDS * 1000);
        const resultPublished =
          exam.resultsPublishedAt != null &&
          currentTime >= exam.resultsPublishedAt &&
          result != null;
        const expired = currentTime >= closesAt;
        const status = resultPublished
          ? 'results_published'
          : expired || attempt.status === 'scored'
            ? 'results_processing'
            : 'in_progress';
        const totalMarks = exam.questions.reduce(
          (sum, question) => sum + (Number.isFinite(question.points) ? question.points : 0),
          0,
        );
        return {
          attemptId: attempt._id.toString(),
          examId: exam._id.toString(),
          title: exam.title,
          status,
          startedAt:
            attempt.createdAt instanceof Date &&
            Number.isFinite(attempt.createdAt.getTime())
              ? attempt.createdAt
              : exam.scheduledAt,
          completedAt:
            result?.submittedAt ??
            attempt.scoredAt ??
            (currentTime >= closesAt ? closesAt : null),
          score: result?.score ?? null,
          totalMarks,
          correctCount: result?.correctCount ?? null,
          unansweredCount:
            result == null ||
            !Number.isFinite(result.totalQuestions) ||
            !Number.isFinite(result.answeredCount)
              ? null
              : Math.max(0, result.totalQuestions - result.answeredCount),
          rank: resultPublished ? result.rank ?? null : null,
          resultPublished,
        };
      }),
    });
  });

  router.post('/:examId/attempts', authenticate, async (request, response) => {
    if (!ObjectId.isValid(request.params.examId)) {
      response.status(404).json({
        error: { code: 'EXAM_NOT_FOUND', message: 'Exam was not found.' },
      });
      return;
    }
    const exam = await getCollection('exams').findOne({
      _id: new ObjectId(request.params.examId),
    });
    const currentTime = now();
    if (!exam) {
      response.status(404).json({
        error: { code: 'EXAM_NOT_FOUND', message: 'Exam was not found.' },
      });
      return;
    }
    const closesAt = new Date(exam.scheduledAt.getTime() + EXAM_SECONDS * 1000);
    if (currentTime < exam.scheduledAt || currentTime >= closesAt) {
      response.status(409).json({
        error: {
          code: 'EXAM_NOT_OPEN',
          message: 'This competitive exam is not currently open.',
        },
      });
      return;
    }

    const attempts = getCollection('exam_attempts');
    await attempts.createIndex(
      { examId: 1, userId: 1 },
      { unique: true, name: 'exam_attempts_exam_user_unique' },
    );
    let attempt = await attempts.findOne({
      examId: exam._id,
      userId: request.authenticatedUser.id,
    });
    if (!attempt) {
      const newAttempt = {
        examId: exam._id,
        userId: request.authenticatedUser.id,
        fullName: request.authenticatedUser.fullName,
        username: request.authenticatedUser.username,
        answers: {},
        status: 'in_progress',
        createdAt: currentTime,
      };
      try {
        const inserted = await attempts.insertOne(newAttempt);
        attempt = { ...newAttempt, _id: inserted.insertedId };
      } catch (error) {
        if (error.code !== 11000) throw error;
        attempt = await attempts.findOne({
          examId: exam._id,
          userId: request.authenticatedUser.id,
        });
      }
    }
    response.json(attemptPayload(exam, attempt, currentTime));
  });

  router.post(
    '/:examId/attempts/:attemptId/answers',
    authenticate,
    async (request, response) => {
      if (
        !ObjectId.isValid(request.params.examId) ||
        !ObjectId.isValid(request.params.attemptId)
      ) {
        response.status(404).json({
          error: { code: 'ATTEMPT_NOT_FOUND', message: 'Attempt was not found.' },
        });
        return;
      }
      const examId = new ObjectId(request.params.examId);
      const attemptId = new ObjectId(request.params.attemptId);
      const exam = await getCollection('exams').findOne({ _id: examId });
      const attempt = await getCollection('exam_attempts').findOne({
        _id: attemptId,
        examId,
        userId: request.authenticatedUser.id,
      });
      if (!exam || !attempt || attempt.status !== 'in_progress') {
        response.status(404).json({
          error: { code: 'ATTEMPT_NOT_FOUND', message: 'Attempt was not found.' },
        });
        return;
      }
      const currentTime = now();
      const questionIndex = Math.floor(
        (currentTime.getTime() - exam.scheduledAt.getTime()) /
          (QUESTION_SECONDS * 1000),
      );
      const question = exam.questions[questionIndex];
      if (
        currentTime < exam.scheduledAt ||
        currentTime >= new Date(exam.scheduledAt.getTime() + EXAM_SECONDS * 1000) ||
        !question ||
        request.body?.questionId !== question.questionId.toString()
      ) {
        response.status(409).json({
          error: {
            code: 'QUESTION_DEADLINE_PASSED',
            message: 'This question is no longer accepting answers.',
          },
        });
        return;
      }
      const answer = request.body?.answer;
      if (!validAnswer(question, answer)) {
        response.status(400).json({
          error: {
            code: 'INVALID_ANSWER',
            message: 'Answer does not match the question response format.',
          },
        });
        return;
      }
      const key = `answers.${question.questionId.toString()}`;
      const saved = await getCollection('exam_attempts').updateOne(
        { _id: attemptId, status: 'in_progress', [key]: { $exists: false } },
        { $set: { [key]: answer } },
      );
      if (saved.modifiedCount !== 1) {
        response.status(409).json({
          error: {
            code: 'ANSWER_ALREADY_SUBMITTED',
            message: 'An answer for this question was already submitted.',
          },
        });
        return;
      }
      const updatedAttempt = await getCollection('exam_attempts').findOne({
        _id: attemptId,
      });
      response.json(attemptPayload(exam, updatedAttempt, currentTime));
    },
  );

  router.get(
    '/:examId/attempts/:attemptId',
    authenticate,
    async (request, response) => {
      if (
        !ObjectId.isValid(request.params.examId) ||
        !ObjectId.isValid(request.params.attemptId)
      ) {
        response.status(404).json({
          error: { code: 'ATTEMPT_NOT_FOUND', message: 'Attempt was not found.' },
        });
        return;
      }
      const examId = new ObjectId(request.params.examId);
      const attempt = await getCollection('exam_attempts').findOne({
        _id: new ObjectId(request.params.attemptId),
        examId,
        userId: request.authenticatedUser.id,
      });
      const exam = await getCollection('exams').findOne({ _id: examId });
      if (!attempt || !exam) {
        response.status(404).json({
          error: { code: 'ATTEMPT_NOT_FOUND', message: 'Attempt was not found.' },
        });
        return;
      }
      const payload = attemptPayload(exam, attempt, now());
      if (attempt.status === 'scored') {
        payload.result = await getCollection('exam_results').findOne({
          examId,
          userId: request.authenticatedUser.id,
        });
      }
      response.json(payload);
    },
  );

  router.get(
    '/:examId/leaderboard',
    authenticate,
    async (request, response) => {
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
      const results = await getCollection('exam_results')
        .find({ examId })
        .sort({ rank: 1 })
        .limit(100)
        .toArray();
      response.json({
        results: results.map((result) => ({
          rank: result.rank,
          fullName: result.fullName,
          username: result.username,
          score: result.score,
          correctCount: result.correctCount,
          totalQuestions: result.totalQuestions,
        })),
      });
    },
  );

  return router;
}

function validAnswer(question, answer) {
  if (answer === null) return true;
  if (['multiple_choice', 'scenario', 'image_identification'].includes(question.type)) {
    return (
      typeof answer === 'string' &&
      question.options.some((option) => option.id === answer)
    );
  }
  if (question.type === 'true_false') return typeof answer === 'boolean';
  return (
    ['riddle', 'emoji_guess'].includes(question.type) &&
    typeof answer === 'string' &&
    answer.trim().length > 0 &&
    answer.length <= 300
  );
}

function attemptPayload(exam, attempt, currentTime) {
  const elapsed = currentTime.getTime() - exam.scheduledAt.getTime();
  const index = Math.max(
    0,
    Math.min(
      exam.questions.length - 1,
      Math.floor(elapsed / (QUESTION_SECONDS * 1000)),
    ),
  );
  const question = exam.questions[index];
  const deadlineAt = new Date(
    exam.scheduledAt.getTime() + (index + 1) * QUESTION_SECONDS * 1000,
  );
  const closesAt = new Date(exam.scheduledAt.getTime() + EXAM_SECONDS * 1000);
  const remainingUntil = Math.min(deadlineAt.getTime(), closesAt.getTime());
  return {
    attemptId: attempt._id.toString(),
    examId: exam._id.toString(),
    status: currentTime >= new Date(exam.scheduledAt.getTime() + EXAM_SECONDS * 1000)
      ? 'closed'
      : 'in_progress',
    questionIndex: index,
    totalQuestions: 15,
    remainingSeconds:
      currentTime >= closesAt
        ? 0
        : Math.max(0, Math.ceil((remainingUntil - currentTime.getTime()) / 1000)),
    deadlineAt,
    closesAt,
    question: question ? publicQuestion(question) : null,
    answered:
      question != null &&
      Object.prototype.hasOwnProperty.call(
        attempt.answers ?? {},
        question.questionId.toString(),
      ),
  };
}

module.exports = { EXAM_SECONDS, QUESTION_SECONDS, createExamRouter };
