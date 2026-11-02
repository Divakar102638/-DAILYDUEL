import { api } from '../api';
import { Alert, EmptyState, LoadingState, PageHeader, StatusBadge } from '../components/ui';
import { useApiResource } from '../hooks/useApiResource';

export function DashboardPage() {
  const resource = useApiResource(async () => {
    const [scheduled, completed, publishedQuestions, pendingQuestions, categories] = await Promise.all([
      api.exams(new URLSearchParams({ status: 'scheduled', pageSize: '1' })),
      api.exams(new URLSearchParams({ status: 'results_published', pageSize: '1' })),
      api.questions(new URLSearchParams({ status: 'published', pageSize: '1' })),
      api.questions(new URLSearchParams({ status: 'pending_review', pageSize: '1' })),
      api.categories(),
    ]);
    return {
      scheduled: scheduled.pagination.total,
      completed: completed.pagination.total,
      publishedQuestions: publishedQuestions.pagination.total,
      pendingReview: pendingQuestions.pagination.total,
      categories: categories.filter((category) => category.active).length,
    };
  });

  return (
    <div className="page-stack">
      <PageHeader
        eyebrow="DAILYDUEL ADMIN"
        title="Overview"
        description="A live snapshot of the content and competitions managed by your API."
        action={<button className="button button-secondary" onClick={resource.reload}>Refresh data</button>}
      />
      {resource.loading && <LoadingState label="Loading live dashboard data…" />}
      {resource.error && <Alert>{resource.error}</Alert>}
      {resource.data && (
        <>
          <section className="stats-grid" aria-label="Dashboard statistics">
            <StatCard label="Scheduled exams" value={resource.data.scheduled} detail="Upcoming competitions" tone="blue" />
            <StatCard label="Published results" value={resource.data.completed} detail="Competitions with published results" tone="green" />
            <StatCard label="Published questions" value={resource.data.publishedQuestions} detail="Available in the question bank" tone="violet" />
            <StatCard label="Active categories" value={resource.data.categories} detail={`${resource.data.pendingReview} questions pending review`} tone="amber" />
          </section>
          <div className="content-grid">
            <section className="panel welcome-panel">
              <div className="panel-heading">
                <div><p className="eyebrow">WORKFLOW</p><h2>Manage with confidence</h2></div>
                <StatusBadge status="API connected" />
              </div>
              <p>Questions stay in draft until reviewed. Competitive exams require fifteen published deterministic questions and become locked as soon as participation begins.</p>
              <div className="workflow-steps">
                <WorkflowStep number="01" title="Build the bank" detail="Create or import drafts, then review and publish." />
                <WorkflowStep number="02" title="Schedule a duel" detail="Select approved questions and set a future start." />
                <WorkflowStep number="03" title="Review results" detail="Published scores and ranks are read from the backend." />
              </div>
            </section>
            <section className="panel api-panel">
              <p className="eyebrow">DATA SOURCE</p>
              <h2>Real API records</h2>
              <p>These cards use authenticated administrator endpoints. No sample statistics are included.</p>
              <div className="api-address">{import.meta.env.VITE_API_BASE_URL || 'http://localhost:3000'}</div>
              <small>Counts reflect records currently returned by the backend.</small>
            </section>
          </div>
          {!resource.loading && !resource.error && resource.data.categories === 0 && (
            <EmptyState title="No active categories" detail="Create or activate a category before adding categorized content." />
          )}
        </>
      )}
    </div>
  );
}

function StatCard({ label, value, detail, tone }: { label: string; value: number; detail: string; tone: string }) {
  return (
    <article className={`stat-card stat-${tone}`}>
      <div className="stat-top"><span>{label}</span><span className="stat-dot" /></div>
      <strong className="stat-value">{value.toLocaleString()}</strong>
      <small>{detail}</small>
    </article>
  );
}

function WorkflowStep({ number, title, detail }: { number: string; title: string; detail: string }) {
  return <div className="workflow-step"><span>{number}</span><div><strong>{title}</strong><small>{detail}</small></div></div>;
}
