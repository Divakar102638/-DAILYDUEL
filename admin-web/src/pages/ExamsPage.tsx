import { useMemo, useState, type FormEvent } from 'react';
import { api, ApiError } from '../api';
import type { AdminExam, AdminQuestion, Category } from '../types';
import { Alert, EmptyState, LoadingState, Modal, PageHeader, Pagination, StatusBadge } from '../components/ui';
import { useApiResource } from '../hooks/useApiResource';

interface ExamFormProps {
  exam?: AdminExam;
  categories: Category[];
  questions: AdminQuestion[];
  onClose: () => void;
  onSaved: () => void;
}

function localDateValue(value?: string) {
  if (!value) return '';
  const date = new Date(value);
  return new Date(date.getTime() - date.getTimezoneOffset() * 60_000).toISOString().slice(0, 16);
}

function ExamForm({ exam, categories, questions, onClose, onSaved }: ExamFormProps) {
  const [title, setTitle] = useState(exam?.title ?? '');
  const [description, setDescription] = useState(exam?.description ?? '');
  const [categoryId, setCategoryId] = useState(exam?.categoryId ?? categories[0]?.id ?? '');
  const [scheduledAt, setScheduledAt] = useState(localDateValue(exam?.scheduledAt));
  const [questionIds, setQuestionIds] = useState<string[]>([]);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState('');
  const categoryQuestions = useMemo(
    () => questions.filter((question) => question.categoryId === categoryId),
    [questions, categoryId],
  );

  async function submit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    if (!exam && questionIds.length !== 15) {
      setError('Select exactly 15 published competitive questions.');
      return;
    }
    setBusy(true);
    setError('');
    try {
      const body = {
        title: title.trim(),
        description: description.trim(),
        categoryId,
        scheduledAt: new Date(scheduledAt).toISOString(),
      };
      if (exam) {
        await api.patch(`/api/v1/admin/quizzes/exams/${exam.id}`, body);
      } else {
        await api.post('/api/v1/admin/quizzes/exams', { ...body, questionIds });
      }
      onSaved();
      onClose();
    } catch (reason) {
      setError(reason instanceof ApiError ? reason.message : 'Exam could not be saved.');
    } finally {
      setBusy(false);
    }
  }

  function toggleQuestion(id: string) {
    setQuestionIds((current) => current.includes(id)
      ? current.filter((value) => value !== id)
      : current.length < 15 ? [...current, id] : current);
  }

  return (
    <Modal title={exam ? 'Edit scheduled exam' : 'Schedule a competitive exam'} onClose={onClose} size="wide">
      <form className="form-stack" onSubmit={submit}>
        {error && <Alert>{error}</Alert>}
        <div className="form-grid">
          <label className="field field-span"><span>Exam title</span><input required minLength={3} maxLength={120} value={title} onChange={(event) => setTitle(event.target.value)} /></label>
          <label className="field field-span"><span>Description</span><textarea rows={3} maxLength={1000} value={description} onChange={(event) => setDescription(event.target.value)} /></label>
          <label className="field"><span>Category</span><select required value={categoryId} disabled={Boolean(exam)} onChange={(event) => setCategoryId(event.target.value)}>{categories.filter((category) => category.active || category.id === exam?.categoryId).map((category) => <option value={category.id} key={category.id}>{category.name}</option>)}</select></label>
          <label className="field"><span>Scheduled start</span><input type="datetime-local" required value={scheduledAt} onChange={(event) => setScheduledAt(event.target.value)} /></label>
        </div>
        <div className="exam-structure-note"><strong>Competition format</strong><span>15 questions · 30 seconds each · 7 minutes 30 seconds total</span>{exam && <small>Existing question selection is immutable here to protect the exam snapshot.</small>}</div>
        {!exam && (
          <fieldset className="question-picker">
            <legend>Choose 15 published competitive questions <span>{questionIds.length}/15 selected</span></legend>
            {categoryQuestions.length === 0
              ? <p className="muted">No published competitive questions are available in this category.</p>
              : <div className="question-picker-list">{categoryQuestions.map((question) => (
                <label key={question.id} className="question-picker-item">
                  <input type="checkbox" checked={questionIds.includes(question.id)} disabled={!questionIds.includes(question.id) && questionIds.length >= 15} onChange={() => toggleQuestion(question.id)} />
                  <span><strong>{question.questionText}</strong><small>{question.subcategory} · {question.difficulty} · {question.points} marks</small></span>
                </label>
              ))}</div>}
          </fieldset>
        )}
        <div className="form-actions"><button type="button" className="button button-secondary" onClick={onClose}>Cancel</button><button className="button button-primary" disabled={busy || categories.filter((category) => category.active).length === 0 || (!exam && questionIds.length !== 15)}>{busy ? 'Saving…' : exam ? 'Save changes' : 'Schedule exam'}</button></div>
      </form>
    </Modal>
  );
}

export function ExamsPage() {
  const [page, setPage] = useState(1);
  const [search, setSearch] = useState('');
  const [status, setStatus] = useState('');
  const [showForm, setShowForm] = useState(false);
  const [editExam, setEditExam] = useState<AdminExam | undefined>();
  const [feedback, setFeedback] = useState('');
  const [actionError, setActionError] = useState('');
  const params = new URLSearchParams({ page: String(page), pageSize: '25' });
  if (search.trim()) params.set('search', search.trim());
  if (status) params.set('status', status);
  const resource = useApiResource(() => api.exams(params), [page, search, status]);
  const auxiliary = useApiResource(async () => {
    const [categories, response] = await Promise.all([
      api.categories(),
      api.questions(new URLSearchParams({ status: 'published', pageSize: '100' })),
    ]);
    return {
      categories,
      questions: response.questions.filter((question) => question.modes.includes('competitive') && question.status === 'published'),
    };
  });

  async function archive(exam: AdminExam) {
    if (!window.confirm(`Archive "${exam.title}"? This is only allowed before the exam has attempts.`)) return;
    setActionError('');
    try {
      await api.patch(`/api/v1/admin/quizzes/exams/${exam.id}/archive`);
      setFeedback('Exam archived. Existing attempts and results, if any, are preserved.');
      resource.reload();
    } catch (reason) {
      setActionError(reason instanceof ApiError ? reason.message : 'Exam could not be archived.');
    }
  }

  const exams = resource.data?.exams ?? [];

  return (
    <div className="page-stack">
      <PageHeader eyebrow="COMPETITION SETUP" title="Exam management" description="Schedule, review, and safely archive competitive exams." action={<button className="button button-primary" onClick={() => { setEditExam(undefined); setShowForm(true); }}>Schedule exam <span aria-hidden="true">+</span></button>} />
      {feedback && <Alert kind="success">{feedback}</Alert>}
      {actionError && <Alert>{actionError}</Alert>}
      <section className="panel">
        <div className="table-toolbar">
          <div><h2>Competitive exams</h2><p>{resource.data?.pagination.total ?? '—'} total records · edits lock after participation begins</p></div>
          <div className="toolbar-controls">
            <label className="search-field"><span className="sr-only">Search exams</span><input value={search} onChange={(event) => { setSearch(event.target.value); setPage(1); }} placeholder="Search exams…" /></label>
            <label className="inline-field"><span className="sr-only">Filter by status</span><select aria-label="Filter by status" value={status} onChange={(event) => { setStatus(event.target.value); setPage(1); }}><option value="">All statuses</option><option value="scheduled">Scheduled</option><option value="open">Open</option><option value="closed">Closed</option><option value="results_published">Results published</option><option value="archived">Archived</option></select></label>
          </div>
        </div>
        {resource.loading && <LoadingState />}
        {resource.error && <Alert>{resource.error}</Alert>}
        {!resource.loading && !resource.error && exams.length === 0 && <EmptyState title="No exams found" detail={search || status ? 'Try another search or filter.' : 'Schedule an exam after publishing fifteen competitive questions.'} />}
        {exams.length > 0 && (
          <>
            <div className="table-wrap"><table><thead><tr><th>Exam</th><th>Category</th><th>Schedule</th><th>Questions</th><th>Attempts</th><th>Status</th><th><span className="sr-only">Actions</span></th></tr></thead><tbody>
              {exams.map((exam) => <tr key={exam.id}><td><div className="table-primary"><strong>{exam.title}</strong><small>{exam.description || 'No description'}</small></div></td><td>{exam.categoryId}</td><td>{new Date(exam.scheduledAt).toLocaleString()}</td><td>{exam.questionCount} <small>· {exam.totalMarks} marks</small></td><td>{exam.attempts}</td><td><StatusBadge status={exam.status} /></td><td><div className="table-actions">
                {exam.status === 'scheduled' && exam.attempts === 0 && <button className="text-button" onClick={() => { setEditExam(exam); setShowForm(true); }}>Edit</button>}
                {exam.status === 'scheduled' && exam.attempts === 0 && <button className="text-button text-danger" onClick={() => void archive(exam)}>Archive</button>}
              </div></td></tr>)}
            </tbody></table></div>
            <Pagination page={resource.data?.pagination.page ?? 1} pageCount={resource.data?.pagination.pageCount ?? 1} onChange={setPage} />
          </>
        )}
      </section>
      {(showForm || editExam) && (
        auxiliary.loading ? <Modal title="Preparing exam form" onClose={() => { setShowForm(false); setEditExam(undefined); }}><LoadingState label="Loading categories and published questions…" /></Modal>
          : auxiliary.error ? <Modal title="Exam form unavailable" onClose={() => { setShowForm(false); setEditExam(undefined); }}><Alert>{auxiliary.error}</Alert></Modal>
            : auxiliary.data && <ExamForm exam={editExam} categories={auxiliary.data.categories} questions={auxiliary.data.questions} onClose={() => { setShowForm(false); setEditExam(undefined); }} onSaved={() => { setFeedback('Exam saved.'); resource.reload(); }} />
      )}
    </div>
  );
}
