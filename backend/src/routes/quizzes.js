const express = require('express');
const { ObjectId } = require('mongodb');
const { getDatabase, getUsersCollection } = require('../db/mongo');
const { createAuthMiddleware } = require('../middleware/auth');
const { DEFAULT_CATEGORIES, publicCategory } = require('../quiz/catalog');
const {
  publicQuestion,
  scoreQuestion,
} = require('../quiz/validation');

function createQuizRouter({
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

  router.get('/categories', async (_request, response) => {
    const stored = await getCollection('quiz_categories').find({}).toArray();
    const configured = new Map(DEFAULT_CATEGORIES.map((item) => [item.id, item]));
    for (const category of stored) {
      configured.set(String(category._id), category);
    }
    response.json({
      categories: [...configured.values()]
        .filter((category) => category.active !== false)
        .map(publicCategory),
    });
  });

  router.post('/casual/sessions', authenticate, async (request, response) => {
    const { categoryId, difficulty, questionCount, timerSeconds } =
      request.body || {};
    if (
      typeof categoryId !== 'string' ||
      !categoryId.trim() ||
      (difficulty !== undefined &&
        !['easy', 'medium', 'hard'].includes(difficulty)) ||
      (questionCount !== undefined &&
        (!Number.isInteger(questionCount) ||
          questionCount < 1 ||
          questionCount > 50)) ||
      (timerSeconds !== undefined &&
        timerSeconds !== null &&
        (!Number.isInteger(timerSeconds) ||
          timerSeconds < 1 ||
          timerSeconds > 600))
    ) {
      response.status(400).json({
        error: {
          code: 'VALIDATION_ERROR',
          message: 'Casual quiz settings are invalid.',
        },
      });
      return;
    }

    const count = questionCount ?? 10;
    const filter = {
      categoryId: categoryId.trim(),
      modes: 'casual',
      status: 'published',
      ...(difficulty ? { difficulty } : {}),
    };
    const questions = await getCollection('questions')
      .find(filter, {
        projection: { answerKey: 0, duplicateFingerprint: 0, createdBy: 0 },
      })
      .limit(count)
      .toArray();
    if (questions.length === 0) {
      response.status(404).json({
        error: {
          code: 'NO_QUESTIONS_AVAILABLE',
          message: 'No published casual questions match those settings.',
        },
      });
      return;
    }

    const session = {
      userId: request.authenticatedUser.id,
      questionIds: questions.map((question) => question._id),
      categoryId: categoryId.trim(),
      startedAt: now(),
      timerSeconds: timerSeconds ?? null,
      answers: {},
      result: null,
    };
    const inserted = await getCollection('casual_sessions').insertOne(session);
    response.status(201).json({
      sessionId: inserted.insertedId.toString(),
      startedAt: session.startedAt.toISOString(),
      timerSeconds: session.timerSeconds,
      questions: questions.map(publicQuestion),
    });
  });

  router.post(
    '/casual/sessions/:sessionId/answers',
    authenticate,
    async (request, response) => {
      if (!ObjectId.isValid(request.params.sessionId)) {
        response.status(404).json({
          error: {
            code: 'SESSION_NOT_FOUND',
            message: 'Quiz session was not found.',
          },
        });
        return;
      }
      const sessions = getCollection('casual_sessions');
      const session = await sessions.findOne({
        _id: new ObjectId(request.params.sessionId),
        userId: request.authenticatedUser.id,
      });
      if (!session || session.result) {
        response.status(404).json({
          error: {
            code: 'SESSION_NOT_FOUND',
            message: 'Quiz session was not found.',
          },
        });
        return;
      }
      if (
        session.timerSeconds !== null &&
        now().getTime() >
          session.startedAt.getTime() + session.timerSeconds * 1000
      ) {
        response.status(409).json({
          error: {
            code: 'CASUAL_SESSION_EXPIRED',
            message: 'The casual quiz timer has expired.',
          },
        });
        return;
      }
      const questionId = request.body?.questionId;
      const questionObjectId =
        typeof questionId === 'string' && ObjectId.isValid(questionId)
          ? new ObjectId(questionId)
          : null;
      if (
        !questionObjectId ||
        !session.questionIds.some((id) => id.equals(questionObjectId))
      ) {
        response.status(400).json({
          error: {
            code: 'INVALID_ANSWER',
            message: 'Question does not belong to this quiz session.',
          },
        });
        return;
      }
      const question = await getCollection('questions').findOne({
        _id: questionObjectId,
        status: 'published',
      });
      const answer = request.body?.answer;
      if (!question || !isValidAnswer(question, answer)) {
        response.status(400).json({
          error: {
            code: 'INVALID_ANSWER',
            message: 'Answer does not match the question response format.',
          },
        });
        return;
      }
      const saved = await sessions.updateOne(
        { _id: session._id, result: null },
        { $set: { [`answers.${questionId}`]: answer } },
      );
      if (saved.modifiedCount !== 1) {
        response.status(409).json({
          error: {
            code: 'CASUAL_SESSION_CLOSED',
            message: 'This quiz session is already closed.',
          },
        });
        return;
      }
      response.json({ saved: true });
    },
  );

  router.post(
    '/casual/sessions/:sessionId/submit',
    authenticate,
    async (request, response) => {
      if (!ObjectId.isValid(request.params.sessionId)) {
        response.status(404).json({
          error: {
            code: 'SESSION_NOT_FOUND',
            message: 'Quiz session was not found.',
          },
        });
        return;
      }

      const sessions = getCollection('casual_sessions');
      const session = await sessions.findOne({
        _id: new ObjectId(request.params.sessionId),
        userId: request.authenticatedUser.id,
      });
      if (!session) {
        response.status(404).json({
          error: {
            code: 'SESSION_NOT_FOUND',
            message: 'Quiz session was not found.',
          },
        });
        return;
      }
      if (session.result) {
        response.json(session.result);
        return;
      }
      const answers = session.answers ?? {};
      const questions = await getCollection('questions')
        .find({ _id: { $in: session.questionIds } })
        .toArray();
      const questionsById = new Map(
        questions.map((question) => [question._id.toString(), question]),
      );
      let score = 0;
      let correctCount = 0;
      const personalityResults = {};
      const review = [];
      for (const questionId of session.questionIds) {
        const key = questionId.toString();
        const question = questionsById.get(key);
        if (!question) continue;
        const answer = answers[key];
        const evaluation = scoreQuestion(question, answer);
        if (evaluation.correct) {
          correctCount += 1;
          score += question.points;
        }
        if (evaluation.personality) {
          personalityResults[evaluation.personality] =
            (personalityResults[evaluation.personality] || 0) + 1;
        }
        const correctOption = question.options?.find(
          (option) => option.id === question.answerKey,
        );
        review.push({
          questionId: key,
          correct: evaluation.correct,
          explanation: question.explanation,
          correctAnswer:
            question.type === 'personality_preference'
              ? null
              : question.type === 'true_false'
                ? question.answerKey
                : correctOption?.text ?? question.answerKey,
        });
      }
      const result = {
        score,
        correctCount,
        totalQuestions: questions.length,
        personalityResults,
        review,
        submittedAt: now(),
      };
      const update = await sessions.updateOne(
        { _id: session._id, result: null },
        { $set: { answers, result } },
      );
      if (update.modifiedCount === 0) {
        const latest = await sessions.findOne({ _id: session._id });
        response.json(latest?.result ?? result);
        return;
      }
      response.json(result);
    },
  );

  return router;
}

function isValidAnswer(question, answer) {
  if (answer === null) return true;
  if (['multiple_choice', 'scenario', 'image_identification', 'personality_preference'].includes(question.type)) {
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

module.exports = { createQuizRouter };
