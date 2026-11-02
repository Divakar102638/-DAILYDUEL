import { useState, type FormEvent } from 'react';
import { api, ApiError } from '../api';
import { Alert, EmptyState, LoadingState, Modal, PageHeader, Pagination, StatusBadge } from '../components/ui';
import { useApiResource } from '../hooks/useApiResource';
import type { AdminQuestion, Category } from '../types';
import { parseBulkQuestionsJson, parseQuestionOptions } from '../validation';

const questionTypes = [
  ['multiple_choice', 'Multiple choice'],
  ['true_false', 'True or false'],
  ['riddle', 'Riddle'],
  ['emoji_guess', 'Emoji guess'],
  ['scenario', 'Scenario'],
  ['image_identification', 'Image identification'],
  ['personality_preference', 'Personality preference (casual only)'],
] as const;

function optionsText(question?: AdminQuestion) {
  return question?.options.map((option) => `${option.id}|${option.text}`).join('\n') ?? 'a|Option A\nb|Option B';
}

function answerText(question?: AdminQuestion) {
  if (!question) return 'b';
  return typeof question.answerKey === 'object'
    ? JSON.stringify(question.answerKey, null, 2)
    : String(question.answerKey);
}

function QuestionEditor({
  question,
  categories,
  onClose,
  onSaved,
}: {
  question?: AdminQuestion;
  categories: Category[];
  onClose: () => void;
  onSaved: () => void;
}) {
  const [categoryId, setCategoryId] = useState(question?.categoryId ?? categories[0]?.id ?? '');
  const category = categories.find((item) => item.id === categoryId);
  const [subcategory, setSubcategory] = useState(question?.subcategory ?? category?.subcategories[0] ?? '');
  const [text, setText] = useState(question?.questionText ?? '');
  const [type, setType] = useState(question?.type ?? 'multiple_choice');
  const [options, setOptions] = useState(optionsText(question));
  const [answerKey, setAnswerKey] = useState(answerText(question));
  const [explanation, setExplanation] = useState(question?.explanation ?? '');
  const [difficulty, setDifficulty] = useState<string>(question?.difficulty ?? 'easy');
  const [points, setPoints] = useState(String(question?.points ?? 10));
  const [timeLimit, setTimeLimit] = useState(question?.timeLimitSeconds?.toString() ?? '');
  const [casual, setCasual] = useState(question?.modes.includes('casual') ?? true);
  const [competitive, setCompetitive] = useState(question?.modes.includes('competitive') ?? false);
  const [imageUrl, setImageUrl] = useState(question?.image?.url ?? '');
  const [imageSource, setImageSource] = useState(question?.image?.source ?? '');
  const [imageLicense, setImageLicense] = useState(question?.image?.license ?? '');
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState('');

  function changeCategory(value: string) {
    setCategoryId(value);
    setSubcategory(categories.find((item) => item.id === value)?.subcategories[0] ?? '');
  }

  async function submit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    setError('');
    if (!casual && !competitive) {
      setError('Select at least one quiz mode.');
      return;
    }
    let parsedOptions;
    let parsedAnswer: unknown = answerKey.trim();
    try {
      parsedOptions = parseQuestionOptions(options);
      if (type === 'personality_preference') parsedAnswer = JSON.parse(answerKey) as Record<string, string>;
    } catch (reason) {
      setError(reason instanceof Error ? reason.message : 'Question options or answer are invalid.');
      return;
    }
    const body = {
      categoryId,
      subcategory,
      questionText: text.trim(),
      type,
      options: parsedOptions,
      answerKey: type === 'true_false' ? answerKey === 'true' : parsedAnswer,
      explanation: explanation.trim(),
      difficulty,
      timeLimitSeconds: timeLimit ? Number(timeLimit) : null,
      points: Number(points),
      modes: [...(casual ? ['casual'] : []), ...(competitive ? ['competitive'] : [])],
      ...(type === 'image_identification' ? { image: { url: imageUrl.trim(), source: imageSource.trim(), license: imageLicense.trim() } } : {}),
    };

    setBusy(true);
    try {
      if (question) {
        await api.patch(`/api/v1/admin/quizzes/questions/${question.id}`, body);
      } else {
        await api.post('/api/v1/admin/quizzes/questions', body);
      }
      onSaved();
      onClose();
    } catch (reason) {
      setError(reason instanceof ApiError ? reason.message : 'Question could not be saved.');
    } finally {
      setBusy(false);
    }
  }

  return (
    <Modal title={question ? 'Edit draft question' : 'Create question draft'} onClose={onClose} size="wide">
      <form className="form-stack" onSubmit={submit}>
        {error && <Alert>{error}</Alert>}
        <div className="form-grid">
          <label className="field"><span>Category</span><select required value={categoryId} onChange={(event) => changeCategory(event.target.value)}>{categories.filter((item) => item.active).map((item) => <option value={item.id} key={item.id}>{item.name}</option>)}</select></label>
          <label className="field"><span>Subcategory</span><select required value={subcategory} onChange={(event) => setSubcategory(event.target.value)}>{(category?.subcategories ?? []).map((item) => <option value={item} key={item}>{item}</option>)}</select></label>
          <label className="field field-span"><span>Question text</span><textarea required minLength={1} maxLength={500} rows={3} value={text} onChange={(event) => setText(event.target.value)} /></label>
          <label className="field"><span>Question format</span><select value={type} onChange={(event) => {
            const nextType = event.target.value;
            setType(nextType);
            if (nextType === 'personality_preference') setCompetitive(false);
            if (nextType === 'true_false') {
              setOptions('true|True\nfalse|False');
              setAnswerKey('true');
            } else if (nextType === 'riddle' || nextType === 'emoji_guess') {
              setOptions('');
            } else if (type === 'riddle' || type === 'emoji_guess' || type === 'true_false') {
              setOptions('a|Option A\nb|Option B');
              setAnswerKey('b');
            }
          }}>{questionTypes.map(([value, label]) => <option value={value} key={value}>{label}</option>)}</select></label>
          <label className="field"><span>Difficulty</span><select value={difficulty} onChange={(event) => setDifficulty(event.target.value)}><option value="easy">Easy</option><option value="medium">Medium</option><option value="hard">Hard</option></select></label>
          {type !== 'riddle' && type !== 'emoji_guess' && <label className="field field-span"><span>Answer options <small>One per line using id|option text. Riddles may have no options.</small></span><textarea rows={4} value={options} onChange={(event) => setOptions(event.target.value)} placeholder={'a|First option\nb|Second option'} /></label>}
          <label className="field field-span"><span>{type === 'personality_preference' ? 'Result mapping (JSON object)' : type === 'true_false' ? 'Correct answer' : 'Correct answer key'}</span>
            {type === 'true_false'
              ? <select value={answerKey} onChange={(event) => setAnswerKey(event.target.value)}><option value="true">True</option><option value="false">False</option></select>
              : <textarea required rows={type === 'personality_preference' ? 4 : 2} value={answerKey} onChange={(event) => setAnswerKey(event.target.value)} placeholder={type === 'personality_preference' ? '{"a":"result one","b":"result two"}' : 'Enter an option ID or accepted answer'} />}
          </label>
          <label className="field field-span"><span>Explanation</span><textarea required maxLength={1000} rows={2} value={explanation} onChange={(event) => setExplanation(event.target.value)} /></label>
          <label className="field"><span>Marks</span><input type="number" min={0} max={1000} step={1} value={points} onChange={(event) => setPoints(event.target.value)} /></label>
          <label className="field"><span>Optional time limit (seconds)</span><input type="number" min={1} max={600} step={1} value={timeLimit} onChange={(event) => setTimeLimit(event.target.value)} placeholder="No limit" /></label>
          {type === 'image_identification' && <>
            <label className="field field-span"><span>Licensed image HTTPS URL</span><input type="url" required value={imageUrl} onChange={(event) => setImageUrl(event.target.value)} /></label>
            <label className="field"><span>Image source</span><input required value={imageSource} onChange={(event) => setImageSource(event.target.value)} /></label>
            <label className="field"><span>License</span><input required value={imageLicense} onChange={(event) => setImageLicense(event.target.value)} /></label>
          </>}
        </div>
        <div className="checkbox-row"><label className="checkbox-field"><input type="checkbox" checked={casual} onChange={(event) => setCasual(event.target.checked)} /><span>Casual quiz</span></label><label className="checkbox-field"><input type="checkbox" checked={competitive} disabled={type === 'personality_preference'} onChange={(event) => setCompetitive(event.target.checked)} /><span>Competitive exam</span></label></div>
        <p className="subtle-note">New and edited questions remain drafts. Publishing is a separate review action.</p>
        <div className="form-actions"><button type="button" className="button button-secondary" onClick={onClose}>Cancel</button><button className="button button-primary" disabled={busy}>{busy ? 'Saving…' : question ? 'Save draft' : 'Create draft'}</button></div>
      </form>
    </Modal>
  );
}

export function QuestionsPage() {
  const [status, setStatus] = useState('all');
  const [search, setSearch] = useState('');
  const [page, setPage] = useState(1);
  const [editor, setEditor] = useState<AdminQuestion | null | undefined>();
  const [bulkOpen, setBulkOpen] = useState(false);
  const [bulkJson, setBulkJson] = useState('');
  const [bulkReport, setBulkReport] = useState<{ created: { questionId: string }[]; duplicates: { questionText: string }[]; invalid: { index: number; message: string }[] } | null>(null);
  const [bulkError, setBulkError] = useState('');
  const [busy, setBusy] = useState(false);
  const [feedback, setFeedback] = useState('');
  const [actionError, setActionError] = useState('');
  const params = new URLSearchParams({ status, page: String(page), pageSize: '25' });
  if (search.trim()) params.set('search', search.trim());
  const resource = useApiResource(() => api.questions(params), [status, page, search]);
  const categoryResource = useApiResource(() => api.categories());

  async function publish(question: AdminQuestion) {
    setActionError('');
    try {
      await api.post(`/api/v1/admin/quizzes/questions/${question.id}/publish`, {});
      setFeedback('Question reviewed and published.');
      resource.reload();
    } catch (reason) {
      setActionError(reason instanceof ApiError ? reason.message : 'Question could not be published.');
    }
  }

  async function archive(question: AdminQuestion) {
    if (!window.confirm(`Archive "${question.questionText}"? Existing exam snapshots will remain unchanged.`)) return;
    setActionError('');
    try {
      await api.patch(`/api/v1/admin/quizzes/questions/${question.id}/archive`);
      setFeedback('Question archived. Existing exam snapshots are preserved.');
      resource.reload();
    } catch (reason) {
      setActionError(reason instanceof ApiError ? reason.message : 'Question could not be archived.');
    }
  }

  async function importQuestions(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    setBulkError('');
    setBulkReport(null);
    let questions: unknown[];
    try {
      questions = parseBulkQuestionsJson(bulkJson);
    } catch (reason) {
      setBulkError(reason instanceof Error ? reason.message : 'Import content is invalid.');
      return;
    }
    setBusy(true);
    try {
      const report = await api.post<typeof bulkReport>('/api/v1/admin/quizzes/questions/bulk', { questions });
      setBulkReport(report);
      if (report?.created.length) resource.reload();
    } catch (reason) {
      setBulkError(reason instanceof ApiError ? reason.message : 'Bulk import failed.');
    } finally {
      setBusy(false);
    }
  }

  const questions = resource.data?.questions ?? [];

  return (
    <div className="page-stack">
      <PageHeader eyebrow="CONTENT QUALITY" title="Question bank" description="Create drafts, review answer keys, publish approved content, and import batches." action={<div className="button-row"><button className="button button-secondary" onClick={() => { setBulkOpen(true); setBulkReport(null); }}>Bulk import</button><button className="button button-primary" onClick={() => setEditor(null)}>Add question <span aria-hidden="true">+</span></button></div>} />
      {feedback && <Alert kind="success">{feedback}</Alert>}
      {actionError && <Alert>{actionError}</Alert>}
      <section className="panel">
        <div className="table-toolbar"><div><h2>Question records</h2><p>{resource.data?.pagination.total ?? '—'} matching questions</p></div><div className="toolbar-controls">
          <label className="search-field"><span className="sr-only">Search questions</span><input value={search} onChange={(event) => { setSearch(event.target.value); setPage(1); }} placeholder="Search question text…" /></label>
          <label className="inline-field"><span className="sr-only">Filter questions</span><select aria-label="Filter questions" value={status} onChange={(event) => { setStatus(event.target.value); setPage(1); }}><option value="all">All statuses</option><option value="draft">Draft</option><option value="pending_review">Pending review</option><option value="published">Published</option><option value="archived">Archived</option></select></label>
        </div></div>
        {resource.loading && <LoadingState />}
        {resource.error && <Alert>{resource.error}</Alert>}
        {!resource.loading && !resource.error && questions.length === 0 && <EmptyState title="No questions found" detail={search ? 'Try a different search term.' : 'Create a draft question or import a validated JSON batch.'} />}
        {questions.length > 0 && <>
          <div className="table-wrap"><table><thead><tr><th>Question</th><th>Category</th><th>Format</th><th>Difficulty</th><th>Modes</th><th>Status</th><th>Actions</th></tr></thead><tbody>
            {questions.map((question) => <tr key={question.id}><td><div className="table-primary"><strong>{question.questionText}</strong><small>Correct answer: {formatAnswer(question.answerKey)} · {question.points} marks</small></div></td><td>{question.categoryId}<small className="cell-subtitle">{question.subcategory}</small></td><td>{question.type.replaceAll('_', ' ')}</td><td>{question.difficulty}</td><td>{question.modes.join(', ')}</td><td><StatusBadge status={question.status} /></td><td><div className="table-actions">{['draft', 'pending_review'].includes(question.status) && <><button className="text-button" onClick={() => setEditor(question)}>Edit</button><button className="text-button" onClick={() => void publish(question)}>Publish</button></>}{question.status !== 'archived' && <button className="text-button text-danger" onClick={() => void archive(question)}>Archive</button>}</div></td></tr>)}
          </tbody></table></div>
          <Pagination page={resource.data?.pagination.page ?? 1} pageCount={resource.data?.pagination.pageCount ?? 1} onChange={setPage} />
        </>}
      </section>
      {editor !== undefined && (categoryResource.loading
        ? <Modal title="Preparing question form" onClose={() => setEditor(undefined)}><LoadingState label="Loading categories…" /></Modal>
        : categoryResource.error
          ? <Modal title="Question form unavailable" onClose={() => setEditor(undefined)}><Alert>{categoryResource.error}</Alert></Modal>
          : <QuestionEditor question={editor ?? undefined} categories={categoryResource.data ?? []} onClose={() => setEditor(undefined)} onSaved={() => { setFeedback('Question saved as a draft.'); resource.reload(); }} />)}
      {bulkOpen && <Modal title="Bulk question import" onClose={() => setBulkOpen(false)} size="wide">
        <form className="form-stack" onSubmit={importQuestions}>
          <p className="muted">Paste a JSON array of question objects. Up to 100 entries are validated; imported items become drafts. The backend reports created, duplicate, and invalid entries individually.</p>
          <label className="field"><span>Question JSON</span><textarea className="code-input" required rows={14} spellCheck={false} value={bulkJson} onChange={(event) => setBulkJson(event.target.value)} placeholder={'[\n  {\n    "categoryId": "fun-entertainment",\n    "subcategory": "Funny quizzes",\n    "questionText": "Example question?",\n    "type": "multiple_choice",\n    "options": [{"id":"a","text":"First"},{"id":"b","text":"Second"}],\n    "answerKey": "b",\n    "explanation": "Reason for the answer.",\n    "difficulty": "easy",\n    "modes": ["casual"],\n    "points": 10\n  }\n]'} /></label>
          {bulkError && <Alert>{bulkError}</Alert>}
          {bulkReport && <div className="import-report" role="status"><strong>Import complete</strong><span>{bulkReport.created.length} created as drafts</span><span>{bulkReport.duplicates.length} duplicates skipped</span><span>{bulkReport.invalid.length} invalid entries</span>{bulkReport.invalid.length > 0 && <ul>{bulkReport.invalid.map((item) => <li key={item.index}>Item {item.index + 1}: {item.message}</li>)}</ul>}</div>}
          <div className="form-actions"><button type="button" className="button button-secondary" onClick={() => setBulkOpen(false)}>Close</button><button className="button button-primary" disabled={busy}>{busy ? 'Validating…' : 'Validate and import'}</button></div>
        </form>
      </Modal>}
    </div>
  );
}

function formatAnswer(answer: AdminQuestion['answerKey']) {
  if (typeof answer === 'object') return 'personality result mapping';
  return String(answer);
}
