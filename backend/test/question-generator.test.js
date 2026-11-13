const assert = require('node:assert/strict');
const { test } = require('node:test');
const {
  AI_CATEGORIES,
  createConfiguredQuestionGenerator,
  createGeminiQuestionGenerator,
  createOpenAIQuestionGenerator,
} = require('../src/quiz/question-generator');

function providerQuestion(index, category) {
  return {
    category,
    questionText: `Unique question ${index}?`,
    options: [
      { id: 'a', text: `First ${index}` },
      { id: 'b', text: `Second ${index}` },
      { id: 'c', text: `Third ${index}` },
      { id: 'd', text: `Fourth ${index}` },
    ],
    answerKey: 'b',
    explanation: 'This is a concise explanation of the verified answer.',
    difficulty: ['easy', 'medium', 'hard'][index % 3],
  };
}

test('OpenAI generator requests strict structured output and validates fifteen questions', async () => {
  const calls = [];
  const logs = [];
  const category = AI_CATEGORIES.find((item) => item.id === 'sports');
  const generator = createOpenAIQuestionGenerator({
    apiKey: 'private-test-openai-api-key-that-must-not-be-logged',
    model: 'test-model',
    inputPricePerMillion: 0.15,
    outputPricePerMillion: 0.6,
    logger: {
      info: (...args) => logs.push(args),
      warn: (...args) => logs.push(args),
    },
    now: (() => {
      let value = 10;
      return () => value++;
    })(),
    client: {
      responses: {
        create: async (request) => {
          calls.push(request);
          return {
            output_text: JSON.stringify({
              questions: Array.from({ length: 15 }, (_, index) =>
                providerQuestion(index, category.label),
              ),
            }),
            usage: { input_tokens: 1000, output_tokens: 2500 },
          };
        },
      },
    },
  });

  const result = await generator({
    categoryId: 'sports',
    difficulty: 'mixed',
    count: 15,
    requestId: 'test-generation-id',
  });

  assert.equal(result.questions.length, 15);
  assert.equal(result.questions[0].categoryId, 'general-knowledge');
  assert.equal(result.questions[0].subcategory, 'Sports');
  assert.equal(result.questions[0].options.length, 4);
  assert.equal(result.questions[0].answerKey, 'b');
  assert.equal(result.questions[0].modes[0], 'competitive');
  assert.equal(result.usage.inputTokens, 1000);
  assert.equal(result.usage.outputTokens, 2500);
  assert.equal(result.estimatedCostUsd, 0.00165);
  assert.equal(calls[0].model, 'test-model');
  assert.equal(calls[0].text.format.type, 'json_schema');
  assert.equal(calls[0].text.format.strict, true);
  assert.equal(calls[0].text.format.schema.additionalProperties, false);
  assert.equal(logs[0][0], '[DailyDuel AI] question generation completed');
  assert.equal(JSON.stringify(logs).includes('private-test-openai-api-key'), false);
});

test('OpenAI generator rejects wrong question counts and duplicate output', async () => {
  const category = AI_CATEGORIES.find((item) => item.id === 'cinema');
  const makeGenerator = (questions) =>
    createOpenAIQuestionGenerator({
      apiKey: 'private-test-openai-api-key-that-must-not-be-logged',
      client: {
        responses: {
          create: async () => ({
            output_text: JSON.stringify({ questions }),
          }),
        },
      },
      logger: { info() {}, warn() {} },
    });

  await assert.rejects(
    makeGenerator([providerQuestion(0, category.label)])({
      categoryId: 'cinema',
      count: 15,
    }),
    { code: 'AI_INVALID_RESPONSE', status: 502 },
  );
  await assert.rejects(
    makeGenerator(
      Array.from({ length: 15 }, () => providerQuestion(1, category.label)),
    )({ categoryId: 'cinema', count: 15 }),
    { code: 'DUPLICATE_GENERATED_QUESTIONS', status: 409 },
  );
});

test('OpenAI generator maps provider failures to safe errors without exposing details', async () => {
  const generator = createOpenAIQuestionGenerator({
    apiKey: 'private-test-openai-api-key-that-must-not-be-logged',
    client: {
      responses: {
        create: async () => {
          const error = new Error('private provider response');
          error.status = 429;
          throw error;
        },
      },
    },
    logger: { info() {}, warn() {} },
  });

  await assert.rejects(
    generator({ categoryId: 'technology', count: 15 }),
    (error) => {
      assert.equal(error.status, 429);
      assert.equal(error.code, 'AI_PROVIDER_RATE_LIMITED');
      assert.equal(error.message.includes('private provider response'), false);
      return true;
    },
  );
});

test('OpenAI generation reports missing server configuration without attempting a request', async () => {
  const generator = createOpenAIQuestionGenerator({
    apiKey: '',
    logger: { info() {}, warn() {} },
  });

  await assert.rejects(
    generator({ categoryId: 'sports', count: 15 }),
    {
      code: 'AI_NOT_CONFIGURED',
      safeMessage: 'AI question generation is not configured. Set OPENAI_API_KEY in the backend environment.',
    },
  );
});

test('Gemini generator requests JSON output and validates fifteen questions', async () => {
  const calls = [];
  const logs = [];
  const category = AI_CATEGORIES.find((item) => item.id === 'sports');
  const generator = createGeminiQuestionGenerator({
    apiKey: 'private-test-gemini-api-key-that-must-not-be-logged',
    model: 'gemini-test-model',
    inputPricePerMillion: 0.1,
    outputPricePerMillion: 0.4,
    logger: {
      info: (...args) => logs.push(args),
      warn: (...args) => logs.push(args),
    },
    client: {
      models: {
        generateContent: async (request) => {
          calls.push(request);
          return {
            text: JSON.stringify({
              questions: Array.from({ length: 15 }, (_, index) =>
                providerQuestion(index, category.label),
              ),
            }),
            usageMetadata: {
              promptTokenCount: 1000,
              candidatesTokenCount: 2500,
            },
          };
        },
      },
    },
  });

  const result = await generator({
    categoryId: 'sports',
    difficulty: 'mixed',
    count: 15,
    requestId: 'gemini-test-generation-id',
  });

  assert.equal(result.questions.length, 15);
  assert.equal(result.questions[0].options.length, 4);
  assert.equal(result.questions[0].answerKey, 'b');
  assert.equal(result.questions[0].explanation.length > 10, true);
  assert.equal(result.usage.inputTokens, 1000);
  assert.equal(result.usage.outputTokens, 2500);
  assert.equal(result.estimatedCostUsd, 0.0011);
  assert.equal(result.provider, 'gemini');
  assert.equal(calls[0].model, 'gemini-test-model');
  assert.equal(calls[0].config.responseMimeType, 'application/json');
  assert.equal(
    calls[0].config.responseJsonSchema.additionalProperties,
    false,
  );
  assert.equal(logs[0][0], '[DailyDuel AI] question generation completed');
  assert.equal(JSON.stringify(logs).includes('private-test-gemini-api-key'), false);
});

test('Gemini generator forwards configured count, topic, and language', async () => {
  const category = AI_CATEGORIES.find((item) => item.id === 'sports');
  let providerRequest;
  const generator = createGeminiQuestionGenerator({
    apiKey: 'private-test-gemini-api-key-that-must-not-be-logged',
    client: {
      models: {
        generateContent: async (request) => {
          providerRequest = request;
          const input = JSON.parse(request.contents);
          return {
            text: JSON.stringify({
              questions: Array.from({ length: input.questionCount }, (_, index) =>
                providerQuestion(index, category.label),
              ),
            }),
          };
        },
      },
    },
    logger: { info() {}, warn() {} },
  });

  const result = await generator({
    categoryId: 'sports',
    count: 3,
    topic: 'World Cup history',
    language: 'Telugu',
  });

  assert.equal(result.questions.length, 3);
  assert.equal(result.questions[0].subcategory, 'Sports');
  const input = JSON.parse(providerRequest.contents);
  assert.equal(input.questionCount, 3);
  assert.equal(input.topic, 'World Cup history');
  assert.equal(input.language, 'Telugu');
});

test('Gemini generator uses the supported default model when no override is given', async () => {
  const category = AI_CATEGORIES.find((item) => item.id === 'sports');
  let requestedModel;
  const generator = createGeminiQuestionGenerator({
    apiKey: 'private-test-gemini-api-key-that-must-not-be-logged',
    client: {
      models: {
        generateContent: async (request) => {
          requestedModel = request.model;
          return {
            text: JSON.stringify({
              questions: [providerQuestion(0, category.label)],
            }),
          };
        },
      },
    },
    logger: { info() {}, warn() {} },
  });

  await generator({ categoryId: 'sports', count: 1 });

  assert.equal(requestedModel, 'gemini-3.5-flash-lite');
});

test('Gemini generator rejects invalid counts and maps provider failures safely', async () => {
  const category = AI_CATEGORIES.find((item) => item.id === 'cinema');
  const invalidOutput = createGeminiQuestionGenerator({
    apiKey: 'private-test-gemini-api-key-that-must-not-be-logged',
    client: {
      models: {
        generateContent: async () => ({
          text: JSON.stringify({
            questions: [providerQuestion(0, category.label)],
          }),
        }),
      },
    },
    logger: { info() {}, warn() {} },
  });
  await assert.rejects(
    invalidOutput({ categoryId: 'cinema', count: 15 }),
    { code: 'AI_INVALID_RESPONSE', status: 502 },
  );

  const failingGenerator = createGeminiQuestionGenerator({
    apiKey: 'private-test-gemini-api-key-that-must-not-be-logged',
    client: {
      models: {
        generateContent: async () => {
          const error = new Error('private provider response');
          error.status = 429;
          throw error;
        },
      },
    },
    logger: { info() {}, warn() {} },
  });
  await assert.rejects(
    failingGenerator({ categoryId: 'cinema', count: 15 }),
    (error) => {
      assert.equal(error.status, 429);
      assert.equal(error.code, 'AI_PROVIDER_RATE_LIMITED');
      assert.equal(error.message.includes('private provider response'), false);
      return true;
    },
  );
});

test('Gemini generation reports missing configuration without making a request', async () => {
  const generator = createGeminiQuestionGenerator({
    apiKey: '',
    logger: { info() {}, warn() {} },
  });
  await assert.rejects(
    generator({ categoryId: 'sports', count: 15 }),
    {
      code: 'AI_NOT_CONFIGURED',
      safeMessage: 'AI question generation is not configured. Set GEMINI_API_KEY in the backend environment.',
    },
  );
});

test('configured generator prefers Gemini when both provider keys are present', async () => {
  const category = AI_CATEGORIES.find((item) => item.id === 'sports');
  let openAiCalls = 0;
  let geminiRequestedModel;
  const generate = createConfiguredQuestionGenerator({
    geminiApiKey: 'private-test-gemini-api-key-that-must-not-be-logged',
    geminiModel: 'gemini-test-model',
    geminiClient: {
      models: {
        generateContent: async (request) => {
          geminiRequestedModel = request.model;
          return {
            text: JSON.stringify({
              questions: [providerQuestion(0, category.label)],
            }),
          };
        },
      },
    },
    openAiApiKey: 'private-test-openai-api-key-that-must-not-be-logged',
    openAiClient: {
      responses: {
        create: async () => {
          openAiCalls += 1;
          throw new Error('OpenAI should not be called when Gemini is configured.');
        },
      },
    },
    logger: { info() {}, warn() {} },
  });

  const result = await generate({
    categoryId: 'sports',
    difficulty: 'mixed',
    count: 1,
  });

  assert.equal(result.provider, 'gemini');
  assert.equal(result.questions.length, 1);
  assert.equal(geminiRequestedModel, 'gemini-test-model');
  assert.equal(openAiCalls, 0);
});
