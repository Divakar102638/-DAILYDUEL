const assert = require('node:assert/strict');
const { test } = require('node:test');
const { loadConfig } = require('../src/config');

function withConfig(overrides, operation) {
  const keys = ['MONGODB_URI', 'AUTH_TOKEN_SECRET', 'GEMINI_MODEL'];
  const previous = new Map(keys.map((key) => [key, process.env[key]]));
  Object.assign(process.env, {
    MONGODB_URI: 'mongodb://localhost:27017/dailyduel-test',
    AUTH_TOKEN_SECRET: 'x'.repeat(32),
    GEMINI_MODEL: '',
    ...overrides,
  });
  try {
    return operation();
  } finally {
    for (const [key, value] of previous) {
      if (value === undefined) delete process.env[key];
      else process.env[key] = value;
    }
  }
}

test('backend configuration uses the Gemini model default', () => {
  withConfig({}, () => {
    assert.equal(loadConfig().geminiModel, 'gemini-3.5-flash-lite');
  });
});
