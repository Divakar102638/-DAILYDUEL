import type { ReactNode } from 'react';

export function PageHeader({
  eyebrow,
  title,
  description,
  action,
}: {
  eyebrow: string;
  title: string;
  description: string;
  action?: ReactNode;
}) {
  return (
    <div className="page-heading">
      <div>
        <p className="eyebrow">{eyebrow}</p>
        <h1>{title}</h1>
        <p className="page-description">{description}</p>
      </div>
      {action && <div className="page-heading-action">{action}</div>}
    </div>
  );
}

export function Alert({
  children,
  kind = 'error',
}: {
  children: ReactNode;
  kind?: 'error' | 'success' | 'info';
}) {
  return <div className={`alert alert-${kind}`} role={kind === 'error' ? 'alert' : 'status'}>{children}</div>;
}

export function LoadingState({ label = 'Loading data…' }: { label?: string }) {
  return <div className="table-state"><span className="spinner" />{label}</div>;
}

export function EmptyState({
  title,
  detail,
}: {
  title: string;
  detail: string;
}) {
  return (
    <div className="empty-state">
      <span className="empty-mark" aria-hidden="true">—</span>
      <h3>{title}</h3>
      <p>{detail}</p>
    </div>
  );
}

export function Modal({
  title,
  onClose,
  children,
  size = 'medium',
}: {
  title: string;
  onClose: () => void;
  children: ReactNode;
  size?: 'medium' | 'wide';
}) {
  return (
    <div className="modal-backdrop" onMouseDown={(event) => {
      if (event.target === event.currentTarget) onClose();
    }}>
      <section className={`modal modal-${size}`} role="dialog" aria-modal="true" aria-label={title}>
        <div className="modal-heading">
          <h2>{title}</h2>
          <button type="button" className="icon-button" aria-label="Close dialog" onClick={onClose}>×</button>
        </div>
        {children}
      </section>
    </div>
  );
}

export function Pagination({
  page,
  pageCount,
  onChange,
}: {
  page: number;
  pageCount: number;
  onChange: (page: number) => void;
}) {
  if (pageCount <= 1) return null;
  return (
    <div className="pagination">
      <span>Page {page} of {pageCount}</span>
      <div className="button-row">
        <button className="button button-secondary" disabled={page <= 1} onClick={() => onChange(page - 1)}>Previous</button>
        <button className="button button-secondary" disabled={page >= pageCount} onClick={() => onChange(page + 1)}>Next</button>
      </div>
    </div>
  );
}

export function StatusBadge({ status }: { status: string }) {
  const tone = status === 'published' || status === 'results_published'
    ? 'green'
    : status === 'archived' || status === 'closed'
      ? 'gray'
      : status === 'open'
        ? 'blue'
        : 'amber';
  return <span className={`status-badge status-${tone}`}>{status.replaceAll('_', ' ')}</span>;
}
