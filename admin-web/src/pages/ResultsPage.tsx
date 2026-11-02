import { useEffect, useState } from 'react';
import { api, ApiError } from '../api';
import type { AdminExam, ExamResult } from '../types';
import { Alert, EmptyState, LoadingState, PageHeader, Pagination, StatusBadge } from '../components/ui';
import type { Pagination as PaginationData } from '../types';

export function ResultsPage() {
  const [exams, setExams] = useState<AdminExam[]>([]);
  const [examId, setExamId] = useState('');
  const [results, setResults] = useState<ExamResult[]>([]);
  const [loadingExams, setLoadingExams] = useState(true);
  const [loadingResults, setLoadingResults] = useState(false);
  const [error, setError] = useState('');
  const [examTitle, setExamTitle] = useState('');
  const [page, setPage] = useState(1);
  const [pagination, setPagination] = useState<PaginationData | null>(null);

  useEffect(() => {
    let active = true;
    api.exams(new URLSearchParams({ pageSize: '100' }))
      .then((response) => {
        if (!active) return;
        const published = response.exams.filter((exam) => exam.status === 'results_published');
        setExams(published);
        setLoadingResults(published.length > 0);
        setExamId((current) => current || published[0]?.id || '');
      })
      .catch((reason: unknown) => {
        if (active) setError(reason instanceof Error ? reason.message : 'Could not load exams.');
      })
      .finally(() => {
        if (active) setLoadingExams(false);
      });
    return () => { active = false; };
  }, []);

  useEffect(() => {
    if (!examId) return;
    let active = true;
    api.results(examId, page)
      .then((response) => {
        if (!active) return;
        setError('');
        setResults(response.results);
        setExamTitle(response.exam.title);
        setPagination(response.pagination);
      })
      .catch((reason: unknown) => {
        if (active) {
          setError(reason instanceof ApiError ? reason.message : 'Could not load exam results.');
          setResults([]);
          setPagination(null);
        }
      })
      .finally(() => {
        if (active) setLoadingResults(false);
      });
    return () => { active = false; };
  }, [examId, page]);

  return (
    <div className="page-stack">
      <PageHeader eyebrow="COMPETITION INSIGHTS" title="Results & leaderboards" description="Review rankings after the backend has published the official results." />
      {error && <Alert>{error}</Alert>}
      <section className="panel results-panel">
        <div className="table-toolbar"><div><h2>Published competitions</h2><p>Results are available only after backend publication.</p></div>
          <label className="inline-field"><span>Exam</span><select aria-label="Select exam" value={examId} onChange={(event) => { const nextExamId = event.target.value; setExamId(nextExamId); setPage(1); setLoadingResults(nextExamId !== ''); setResults([]); setExamTitle(''); setError(''); }} disabled={loadingExams || exams.length === 0}><option value="">Select a published exam</option>{exams.map((exam) => <option value={exam.id} key={exam.id}>{exam.title}</option>)}</select></label>
        </div>
        {loadingExams || loadingResults
          ? <LoadingState label="Loading published results…" />
          : error
            ? null
            : results.length === 0
              ? <EmptyState title="No published results" detail={exams.length === 0 ? 'Published exams will appear here when the backend has finalised rankings.' : 'This exam has no result records.'} />
              : <>
                <div className="results-summary"><div><span className="eyebrow">SELECTED EXAM</span><h3>{examTitle}</h3></div><StatusBadge status="results_published" /><span className="muted">{pagination?.total ?? results.length} ranked participants</span></div>
                <div className="table-wrap"><table><thead><tr><th>Rank</th><th>Participant</th><th>Score</th><th>Correct</th><th>Answered</th></tr></thead><tbody>
                  {results.map((result) => <tr key={`${result.rank}-${result.username}`}><td><span className={`rank rank-${result.rank}`}>{result.rank}</span></td><td><div className="participant"><strong>{result.fullName}</strong><small>@{result.username}</small></div></td><td className="score-cell">{result.score}</td><td>{result.correctCount}</td><td>{result.answeredCount} / {result.totalQuestions}</td></tr>)}
                </tbody></table></div>
                {pagination && <Pagination page={pagination.page} pageCount={pagination.pageCount} onChange={(nextPage) => { setLoadingResults(true); setPage(nextPage); }} />}
              </>}
      </section>
      <p className="subtle-note">Individual answers and private attempt data are not displayed in this leaderboard view.</p>
    </div>
  );
}
