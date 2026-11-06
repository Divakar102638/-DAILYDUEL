const { validateQuestion } = require('./validation');

const AI_CATEGORIES = [
  {
    id: 'sports',
    label: 'Sports',
    categoryId: 'general-knowledge',
    subcategory: 'Sports',
  },
  {
    id: 'politics',
    label: 'Politics',
    categoryId: 'general-knowledge',
    subcategory: 'Politics',
  },
  {
    id: 'cinema',
    label: 'Cinema',
    categoryId: 'entertainment',
    subcategory: 'Cinema',
  },
  {
    id: 'technology',
    label: 'Technology',
    categoryId: 'technology-career',
    subcategory: 'Programming',
  },
  {
    id: 'general-knowledge',
    label: 'General Knowledge',
    categoryId: 'general-knowledge',
    subcategory: 'General knowledge',
  },
  {
    id: 'entertainment',
    label: 'Entertainment',
    categoryId: 'entertainment',
    subcategory: 'Entertainment',
  },
];
const AI_DIFFICULTIES = new Set(['easy', 'medium', 'hard', 'mixed']);
const OPTION_IDS = ['a', 'b', 'c', 'd'];

class AiGenerationError extends Error {
  constructor(message, { status = 503, code = 'AI_GENERATION_FAILED' } = {}) {
    super(message);
    this.status = status;
    this.code = code;
    this.safeMessage = message;
  }
}

function createQuestionDraftGenerator({ generate }) {
  if (typeof generate !== 'function') {
    throw new TypeError('An AI draft generator implementation is required.');
  }

  return async function generateQuestionDrafts(request) {
    const rawDrafts = await generate(request);
    if (!Array.isArray(rawDrafts)) {
      throw new TypeError('The AI draft provider must return a question list.');
    }

    return rawDrafts.map((draft) => ({
      ...validateQuestion({ ...draft, modes: draft.modes ?? ['casual'] }),
      status: 'draft',
      generatedBy: 'ai',
      reviewedBy: null,
      publishedAt: null,
    }));
  };
}

function createOpenAIQuestionGenerator({
  apiKey,
  model = 'gpt-4o-mini',
  inputPricePerMillion,
  outputPricePerMillion,
  client,
  logger = console,
  now = () => Date.now(),
} = {}) {
  const parsedInputPrice = parsePrice(inputPricePerMillion);
  const parsedOutputPrice = parsePrice(outputPricePerMillion);
  const configuredClient =
    client ??
    (apiKey
      ? new (require('openai').default ?? require('openai'))({
          apiKey,
          timeout: 30_000,
          maxRetries: 2,
        })
      : null);

  return async function generateQuestions({
    categoryId,
    difficulty = 'mixed',
    count = 15,
    requestId = 'untracked',
    excludeQuestions = [],
  } = {}) {
    const category = AI_CATEGORIES.find((item) => item.id === categoryId);
    if (!category || !AI_DIFFICULTIES.has(difficulty) || ![1, 15].includes(count)) {
      throw new AiGenerationError('The AI question generation request is invalid.', {
        status: 400,
        code: 'INVALID_AI_GENERATION_REQUEST',
      });
    }
    if (!configuredClient) {
      throw new AiGenerationError(
        'AI question generation is not configured. Set OPENAI_API_KEY in the backend environment.',
        { code: 'AI_NOT_CONFIGURED' },
      );
    }

    const startedAt = now();
    try {
      const response = await configuredClient.responses.create({
        model,
        max_output_tokens: 10_000,
        input: [
          {
            role: 'system',
            content:
              'Create accurate, original DailyDuel multiple-choice quiz questions. Use four distinct answer choices, exactly one correct choice, and a concise factual explanation. Avoid ambiguous wording, trick answers, speculation, duplicate facts, and sensitive personal claims. Return only the requested structured data.',
          },
          {
            role: 'user',
            content: JSON.stringify({
              category: category.label,
              difficulty,
              questionCount: count,
              excludedQuestionTexts: excludeQuestions.slice(0, 100),
              requirements: [
                'Every question must match the requested category.',
                'If difficulty is mixed, distribute questions across easy, medium, and hard.',
                'Use distinct, plausible answer options; the answer key must name one option ID.',
                'Prefer verifiable, stable facts over rapidly changing current-affairs claims.',
              ],
            }),
          },
        ],
        text: {
          format: {
            type: 'json_schema',
            name: 'dailyduel_quiz_questions',
            strict: true,
            schema: createQuestionSchema(difficulty),
          },
        },
      });

      if (typeof response.output_text !== 'string') {
        throw new AiGenerationError(
          'The AI provider returned an empty response. No questions were saved.',
          { status: 502, code: 'AI_INVALID_RESPONSE' },
        );
      }

      let payload;
      try {
        payload = JSON.parse(response.output_text);
      } catch {
        throw new AiGenerationError(
          'The AI provider returned invalid structured data. No questions were saved.',
          { status: 502, code: 'AI_INVALID_RESPONSE' },
        );
      }
      const questions = validateGeneratedQuestions(
        payload,
        category,
        difficulty,
        count,
      );

      const usage = normalizeUsage(response.usage);
      const estimatedCostUsd =
        parsedInputPrice === null ||
        parsedOutputPrice === null ||
        usage.inputTokens === null ||
        usage.outputTokens === null
          ? null
          : (usage.inputTokens * parsedInputPrice +
              usage.outputTokens * parsedOutputPrice) /
            1_000_000;
      logger.info('[DailyDuel AI] question generation completed', {
        requestId,
        model,
        category: category.id,
        requestedCount: count,
        inputTokens: usage.inputTokens,
        outputTokens: usage.outputTokens,
        estimatedCostUsd,
        durationMs: Math.max(0, now() - startedAt),
      });
      return { questions, usage, model, estimatedCostUsd, provider: 'openai' };
    } catch (error) {
      const safeError = toAiGenerationError(error);
      logger.warn('[DailyDuel AI] question generation failed', {
        requestId,
        model,
        category: category.id,
        requestedCount: count,
        code: safeError.code,
        durationMs: Math.max(0, now() - startedAt),
      });
      throw safeError;
    }
  };
}

function createGeminiQuestionGenerator({
  apiKey,
  model = 'gemini-3.8-flash',
  inputPricePerMillion,
  outputPricePerMillion,
  client,
  logger = console,
  now = () => Date.now(),
} = {}) {
  const parsedInputPrice = parsePrice(inputPricePerMillion);
  const parsedOutputPrice = parsePrice(outputPricePerMillion);
  const configuredClient =
    client ??
    (apiKey
      ? new (require('@google/genai').GoogleGenAI)({
          apiKey,
          httpOptions: {
            timeout: 30_000,
            retryOptions: { attempts: 2 },
          },
        })
      : null);

  return async function generateQuestions({
    categoryId,
    difficulty = 'mixed',
    count = 15,
    requestId = 'untracked',
    excludeQuestions = [],
  } = {}) {
    const category = AI_CATEGORIES.find((item) => item.id === categoryId);
    if (!category || !AI_DIFFICULTIES.has(difficulty) || ![1, 15].includes(count)) {
      throw new AiGenerationError('The AI question generation request is invalid.', {
        status: 400,
        code: 'INVALID_AI_GENERATION_REQUEST',
      });
    }
    if (!configuredClient) {
      throw new AiGenerationError(
        'AI question generation is not configured. Set GEMINI_API_KEY in the backend environment.',
        { code: 'AI_NOT_CONFIGURED' },
      );
    }

    const startedAt = now();
    try {
      const response = await configuredClient.models.generateContent({
        model,
        contents: JSON.stringify({
          instructions: [
            'Create accurate, original DailyDuel multiple-choice quiz questions.',
            'Use four distinct answer choices, exactly one correct choice, and a concise factual explanation.',
            'Avoid ambiguity, trick answers, speculation, duplicate facts, and sensitive personal claims.',
            'Every question must match the requested category.',
            'If difficulty is mixed, distribute questions across easy, medium, and hard.',
            'Use option IDs a, b, c, and d exactly once; answerKey must name the correct option ID.',
            'Prefer verifiable, stable facts over rapidly changing current-affairs claims.',
          ],
          category: category.label,
          difficulty,
          questionCount: count,
          excludedQuestionTexts: excludeQuestions.slice(0, 100),
        }),
        config: {
          responseMimeType: 'application/json',
          responseJsonSchema: createQuestionSchema(difficulty),
          maxOutputTokens: 10_000,
          temperature: 0.4,
        },
      });

      if (typeof response.text !== 'string' || !response.text.trim()) {
        throw new AiGenerationError(
          'The AI provider returned an empty response. No questions were saved.',
          { status: 502, code: 'AI_INVALID_RESPONSE' },
        );
      }

      let payload;
      try {
        payload = JSON.parse(response.text);
      } catch {
        throw new AiGenerationError(
          'The AI provider returned invalid structured data. No questions were saved.',
          { status: 502, code: 'AI_INVALID_RESPONSE' },
        );
      }
      const questions = validateGeneratedQuestions(
        payload,
        category,
        difficulty,
        count,
      );
      const usage = normalizeUsage(response.usageMetadata);
      const estimatedCostUsd =
        parsedInputPrice === null ||
        parsedOutputPrice === null ||
        usage.inputTokens === null ||
        usage.outputTokens === null
          ? null
          : (usage.inputTokens * parsedInputPrice +
              usage.outputTokens * parsedOutputPrice) /
            1_000_000;
      logger.info('[DailyDuel AI] question generation completed', {
        requestId,
        provider: 'gemini',
        model,
        category: category.id,
        requestedCount: count,
        inputTokens: usage.inputTokens,
        outputTokens: usage.outputTokens,
        estimatedCostUsd,
        durationMs: Math.max(0, now() - startedAt),
      });
      return { questions, usage, model, estimatedCostUsd, provider: 'gemini' };
    } catch (error) {
      const safeError = toAiGenerationError(error);
      logger.warn('[DailyDuel AI] question generation failed', {
        requestId,
        provider: 'gemini',
        model,
        category: category.id,
        requestedCount: count,
        code: safeError.code,
        durationMs: Math.max(0, now() - startedAt),
      });
      throw safeError;
    }
  };
}

function createConfiguredQuestionGenerator({
  geminiApiKey,
  geminiModel,
  geminiInputPricePerMillion,
  geminiOutputPricePerMillion,
  geminiClient,
  openAiApiKey,
  openAiModel,
  openAiInputPricePerMillion,
  openAiOutputPricePerMillion,
  openAiClient,
  logger,
  now,
} = {}) {
  if (geminiApiKey) {
    return createGeminiQuestionGenerator({
      apiKey: geminiApiKey,
      model: geminiModel,
      inputPricePerMillion: geminiInputPricePerMillion,
      outputPricePerMillion: geminiOutputPricePerMillion,
      client: geminiClient,
      logger,
      now,
    });
  }
  return createOpenAIQuestionGenerator({
    apiKey: openAiApiKey,
    model: openAiModel,
    inputPricePerMillion: openAiInputPricePerMillion,
    outputPricePerMillion: openAiOutputPricePerMillion,
    client: openAiClient,
    logger,
    now,
  });
}

function validateGeneratedQuestions(payload, category, difficulty, count) {
  if (!Array.isArray(payload?.questions) || payload.questions.length !== count) {
    throw new AiGenerationError(
      `The AI provider must return exactly ${count} questions. No questions were saved.`,
      { status: 502, code: 'AI_INVALID_RESPONSE' },
    );
  }

  const fingerprints = new Set();
  return payload.questions.map((item) => {
    if (
      item.category !== category.label ||
      (difficulty !== 'mixed' && item.difficulty !== difficulty) ||
      !Array.isArray(item.options) ||
      item.options.length !== 4 ||
      new Set(
        item.options.map((option) =>
          typeof option?.text === 'string'
            ? option.text.trim().toLowerCase()
            : '',
        ),
      ).size !== 4 ||
      !OPTION_IDS.every((id) => item.options.some((option) => option.id === id)) ||
      typeof item.explanation !== 'string' ||
      item.explanation.trim().length < 10
    ) {
      throw new AiGenerationError(
        'The AI provider returned a question with invalid metadata or answer options. No questions were saved.',
        { status: 502, code: 'AI_INVALID_RESPONSE' },
      );
    }

    const question = validateQuestion({
      categoryId: category.categoryId,
      subcategory: category.subcategory,
      questionText: item.questionText,
      type: 'multiple_choice',
      options: item.options,
      answerKey: item.answerKey,
      explanation: item.explanation,
      difficulty: item.difficulty,
      modes: ['competitive'],
      points: 10,
    });
    if (fingerprints.has(question.duplicateFingerprint)) {
      throw new AiGenerationError(
        'The AI provider returned duplicate questions. No questions were saved.',
        { status: 409, code: 'DUPLICATE_GENERATED_QUESTIONS' },
      );
    }
    fingerprints.add(question.duplicateFingerprint);
    return { ...question, aiCategory: category.id };
  });
}

function createQuestionSchema(difficulty) {
  const difficultyValues =
    difficulty === 'mixed' ? ['easy', 'medium', 'hard'] : [difficulty];
  return {
    type: 'object',
    additionalProperties: false,
    properties: {
      questions: {
        type: 'array',
        items: {
          type: 'object',
          additionalProperties: false,
          properties: {
            category: {
              type: 'string',
              enum: AI_CATEGORIES.map((item) => item.label),
            },
            questionText: { type: 'string' },
            options: {
              type: 'array',
              items: {
                type: 'object',
                additionalProperties: false,
                properties: {
                  id: { type: 'string', enum: OPTION_IDS },
                  text: { type: 'string' },
                },
                required: ['id', 'text'],
              },
            },
            answerKey: { type: 'string', enum: OPTION_IDS },
            explanation: { type: 'string' },
            difficulty: { type: 'string', enum: difficultyValues },
          },
          required: [
            'category',
            'questionText',
            'options',
            'answerKey',
            'explanation',
            'difficulty',
          ],
        },
      },
    },
    required: ['questions'],
  };
}

function normalizeUsage(usage) {
  return {
    inputTokens: Number.isSafeInteger(usage?.input_tokens ?? usage?.promptTokenCount)
      ? (usage.input_tokens ?? usage.promptTokenCount)
      : null,
    outputTokens: Number.isSafeInteger(
      usage?.output_tokens ?? usage?.candidatesTokenCount,
    )
      ? (usage.output_tokens ?? usage.candidatesTokenCount)
      : null,
  };
}

function parsePrice(value) {
  if (value === undefined || value === null || value === '') return null;
  const parsed = Number(value);
  return Number.isFinite(parsed) && parsed >= 0 ? parsed : null;
}

function toAiGenerationError(error) {
  if (error instanceof AiGenerationError) return error;
  if (error?.name === 'APIConnectionTimeoutError') {
    return new AiGenerationError(
      'The AI provider timed out. Try again shortly.',
      { status: 504, code: 'AI_TIMEOUT' },
    );
  }
  const status =
    Number.isInteger(error?.status) ? error.status : Number(error?.code);
  if (status === 429) {
    return new AiGenerationError(
      'The AI provider rate limit was reached. Try again shortly.',
      { status: 429, code: 'AI_PROVIDER_RATE_LIMITED' },
    );
  }
  if (status === 401 || status === 403) {
    return new AiGenerationError(
      'The AI provider API key is invalid or does not have permission to use this model. Check the backend API key and provider access.',
      { status: 503, code: 'AI_AUTHENTICATION_FAILED' },
    );
  }
  if (status === 400 || status === 404) {
    return new AiGenerationError(
      'The AI provider rejected the configured model or request. Check the configured model and structured-output support.',
      { status: 503, code: 'AI_CONFIGURATION_REJECTED' },
    );
  }
  if (
    status === 408 ||
    status === 500 ||
    status === 502 ||
    status === 503 ||
    error?.name === 'TimeoutError' ||
    error?.name === 'AbortError' ||
    error?.name === 'APIConnectionError'
  ) {
    return new AiGenerationError(
      'The AI provider is temporarily unavailable. Try again shortly.',
      { status: 503, code: 'AI_PROVIDER_UNAVAILABLE' },
    );
  }
  return new AiGenerationError(
    'AI question generation failed. No questions were saved.',
    { status: 502, code: 'AI_GENERATION_FAILED' },
  );
}

module.exports = {
  AI_CATEGORIES,
  AiGenerationError,
  createConfiguredQuestionGenerator,
  createGeminiQuestionGenerator,
  createOpenAIQuestionGenerator,
  createQuestionDraftGenerator,
};
