export function parseBulkQuestionsJson(value: string): unknown[] {
  let parsed: unknown;
  try {
    parsed = JSON.parse(value);
  } catch {
    throw new Error('Enter valid JSON before importing.');
  }
  if (!Array.isArray(parsed) || parsed.length === 0 || parsed.length > 100) {
    throw new Error('Import a JSON array containing between 1 and 100 questions.');
  }
  return parsed;
}

export function parseQuestionOptions(value: string) {
  if (!value.trim()) return [];
  return value.split(/\r?\n/).map((line, index) => {
    const separator = line.indexOf('|');
    if (separator <= 0 || !line.slice(separator + 1).trim()) {
      throw new Error(`Option line ${index + 1} must use id|option text.`);
    }
    return { id: line.slice(0, separator).trim(), text: line.slice(separator + 1).trim() };
  });
}
