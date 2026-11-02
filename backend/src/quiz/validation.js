const { createHash } = require('node:crypto');

const QUESTION_TYPES = new Set([
  'multiple_choice',
  'true_false',
  'riddle',
  'emoji_guess',
  'image_identification',
  'scenario',
  'personality_preference',
]);
const DIFFICULTIES = new Set(['easy', 'medium', 'hard']);
const QUIZ_MODES = new Set(['casual', 'competitive']);

class QuizValidationError extends Error {
  constructor(message) {
    super(message);
    this.status = 400;
    this.code = 'VALIDATION_ERROR';
  }
}

function requireString(value, name, { min = 1, max = 500 } = {}) {
  if (
    typeof value !== 'string' ||
    value.trim().length < min ||
    value.trim().length > max
  ) {
    throw new QuizValidationError(
      `${name} must be a string between ${min} and ${max} characters.`,
    );
  }
  return value.trim();
}

function validateQuestion(input) {
  if (!input || typeof input !== 'object' || Array.isArray(input)) {
    throw new QuizValidationError('A question object is required.');
  }
  const categoryId = requireString(input.categoryId, 'categoryId', {
    max: 80,
  });
  const subcategory = requireString(input.subcategory, 'subcategory', {
    max: 100,
  });
  const questionText = requireString(input.questionText, 'questionText');
  const type = input.type;
  if (!QUESTION_TYPES.has(type)) {
    throw new QuizValidationError('Question type is not supported.');
  }
  const difficulty = input.difficulty;
  if (!DIFFICULTIES.has(difficulty)) {
    throw new QuizValidationError('Difficulty must be easy, medium, or hard.');
  }
  const modes = Array.isArray(input.modes) ? [...new Set(input.modes)] : [];
  if (!modes.length || modes.some((mode) => !QUIZ_MODES.has(mode))) {
    throw new QuizValidationError(
      'Question modes must include casual, competitive, or both.',
    );
  }

  const options = Array.isArray(input.options)
    ? input.options.map((option, index) => {
        if (!option || typeof option !== 'object') {
          throw new QuizValidationError('Each option must be an object.');
        }
        return {
          id: requireString(option.id, `options[${index}].id`, { max: 40 }),
          text: requireString(option.text, `options[${index}].text`, {
            max: 300,
          }),
        };
      })
    : [];
  if (new Set(options.map((option) => option.id)).size !== options.length) {
    throw new QuizValidationError('Option IDs must be unique.');
  }

  const answerKey = input.answerKey;
  const deterministic = type !== 'personality_preference';

  if (['multiple_choice', 'scenario', 'image_identification'].includes(type)) {
    if (
      options.length < 2 ||
      typeof answerKey !== 'string' ||
      !options.some((option) => option.id === answerKey)
    ) {
      throw new QuizValidationError(
        'This question type requires at least two options and a valid answerKey option ID.',
      );
    }
  } else if (type === 'true_false') {
    if (
      typeof answerKey !== 'boolean' ||
      options.length !== 2 ||
      !options.some((option) => option.id === 'true') ||
      !options.some((option) => option.id === 'false')
    ) {
      throw new QuizValidationError(
        'True/false questions require true/false options and a boolean answerKey.',
      );
    }
  } else if (type === 'riddle' || type === 'emoji_guess') {
    if (
      typeof answerKey !== 'string' ||
      !answerKey.trim() ||
      (options.length > 0 &&
        !options.some((option) => option.id === answerKey))
    ) {
      throw new QuizValidationError(
        'Riddle and emoji questions require a defined string answerKey.',
      );
    }
  } else if (type === 'personality_preference') {
    if (
      modes.includes('competitive') ||
      options.length < 2 ||
      !answerKey ||
      typeof answerKey !== 'object' ||
      options.some(
        (option) =>
          typeof answerKey[option.id] !== 'string' ||
          answerKey[option.id].trim().length === 0,
      )
    ) {
      throw new QuizValidationError(
        'Personality questions are casual-only and require a result key for every option.',
      );
    }
  }

  const image = input.image;
  if (type === 'image_identification') {
    if (
      !image ||
      typeof image.url !== 'string' ||
      !/^https:\/\//i.test(image.url) ||
      typeof image.source !== 'string' ||
      !image.source.trim() ||
      typeof image.license !== 'string' ||
      !image.license.trim()
    ) {
      throw new QuizValidationError(
        'Image questions require an HTTPS image URL, source, and license.',
      );
    }
  } else if (image != null) {
    throw new QuizValidationError(
      'Image metadata is only valid for image-identification questions.',
    );
  }

  const timeLimitSeconds = input.timeLimitSeconds ?? null;
  if (
    timeLimitSeconds !== null &&
    (!Number.isInteger(timeLimitSeconds) ||
      timeLimitSeconds < 1 ||
      timeLimitSeconds > 600)
  ) {
    throw new QuizValidationError(
      'timeLimitSeconds must be null or an integer from 1 to 600.',
    );
  }
  const points = input.points ?? 10;
  if (!Number.isInteger(points) || points < 0 || points > 1000) {
    throw new QuizValidationError('points must be an integer from 0 to 1000.');
  }

  const normalized = {
    categoryId,
    subcategory,
    questionText,
    type,
    options,
    answerKey,
    explanation: requireString(input.explanation ?? 'No explanation provided.', 'explanation', {
      max: 1000,
    }),
    difficulty,
    timeLimitSeconds,
    points,
    modes,
    image: image
      ? {
          url: image.url.trim(),
          source: requireString(image.source, 'image.source', { max: 300 }),
          license: requireString(image.license, 'image.license', { max: 120 }),
        }
      : null,
  };
  normalized.deterministic = deterministic;
  normalized.duplicateFingerprint = createHash('sha256')
    .update(questionText.toLowerCase().replace(/\s+/g, ' '))
    .digest('hex');
  return normalized;
}

function publicQuestion(question) {
  return {
    id: String(question._id ?? question.id),
    categoryId: question.categoryId,
    subcategory: question.subcategory,
    questionText: question.questionText,
    type: question.type,
    options: question.options,
    difficulty: question.difficulty,
    timeLimitSeconds: question.timeLimitSeconds ?? null,
    points: question.points,
    image: question.image ?? null,
  };
}

function normalizeAnswer(value) {
  return typeof value === 'string'
    ? value.trim().toLowerCase().replace(/\s+/g, ' ')
    : value;
}

function scoreQuestion(question, submittedAnswer) {
  if (question.type === 'personality_preference') {
    return {
      correct: false,
      personality: question.answerKey[submittedAnswer] ?? null,
    };
  }
  if (question.type === 'riddle' || question.type === 'emoji_guess') {
    const accepted = Array.isArray(question.answerKey)
      ? question.answerKey
      : [question.answerKey];
    return {
      correct: accepted.some(
        (answer) => normalizeAnswer(answer) === normalizeAnswer(submittedAnswer),
      ),
    };
  }
  return { correct: submittedAnswer === question.answerKey };
}

module.exports = {
  DIFFICULTIES,
  QUESTION_TYPES,
  QuizValidationError,
  publicQuestion,
  scoreQuestion,
  validateQuestion,
};
