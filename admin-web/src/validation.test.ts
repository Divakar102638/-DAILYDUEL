import { describe, expect, it } from 'vitest';
import { parseBulkQuestionsJson, parseQuestionOptions } from './validation';

describe('admin input validation helpers', () => {
  it('accepts a bounded JSON array for server-side bulk validation', () => {
    expect(parseBulkQuestionsJson('[{"questionText":"Example"}]')).toEqual([
      { questionText: 'Example' },
    ]);
  });

  it('rejects malformed, empty, non-array, and oversized imports', () => {
    expect(() => parseBulkQuestionsJson('{bad')).toThrow('valid JSON');
    expect(() => parseBulkQuestionsJson('{}')).toThrow('JSON array');
    expect(() => parseBulkQuestionsJson('[]')).toThrow('between 1 and 100');
    expect(() => parseBulkQuestionsJson(JSON.stringify(Array(101).fill({}))))
      .toThrow('between 1 and 100');
  });

  it('parses labeled option rows and rejects missing option text', () => {
    expect(parseQuestionOptions('a|First answer\nb|Second answer')).toEqual([
      { id: 'a', text: 'First answer' },
      { id: 'b', text: 'Second answer' },
    ]);
    expect(() => parseQuestionOptions('option without separator'))
      .toThrow('id|option text');
  });
});
