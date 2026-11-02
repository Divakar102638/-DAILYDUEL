import { useEffect, useState } from 'react';
import { api, ApiError } from '../api';
import { Alert, EmptyState, LoadingState, PageHeader, Pagination } from '../components/ui';
import type { AdminStudent, Pagination as PaginationData } from '../types';

export function StudentsPage() {
  const [students, setStudents] = useState<AdminStudent[]>([]);
  const [page, setPage] = useState(1);
  const [pagination, setPagination] = useState<PaginationData | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [revision, setRevision] = useState(0);

  useEffect(() => {
    let active = true;
    api.students(new URLSearchParams({ page: String(page), pageSize: '25' }))
      .then((response) => {
        if (!active) return;
        setStudents(response.users);
        setPagination(response.pagination);
      })
      .catch((reason: unknown) => {
        if (!active) return;
        setStudents([]);
        setPagination(null);
        setError(reason instanceof ApiError ? reason.message : 'Could not load student accounts.');
      })
      .finally(() => {
        if (active) setLoading(false);
      });
    return () => { active = false; };
  }, [page, revision]);

  function changePage(nextPage: number) {
    setLoading(true);
    setError('');
    setPage(nextPage);
  }

  function refresh() {
    setLoading(true);
    setError('');
    setRevision((current) => current + 1);
  }

  return (
    <div className="page-stack">
      <PageHeader
        eyebrow="ACCOUNT DIRECTORY"
        title="Students"
        description="Registered student accounts from the existing DailyDuel database."
        action={<button className="button button-secondary" onClick={refresh}>Refresh data</button>}
      />
      {error && <Alert>{error}</Alert>}
      <section className="panel results-panel">
        <div className="table-toolbar">
          <div>
            <h2>Registered students</h2>
            <p>{pagination ? `${pagination.total.toLocaleString()} student accounts` : 'Accounts with the student role'}</p>
          </div>
        </div>
        {loading
          ? <LoadingState label="Loading student accounts…" />
          : error
            ? null
            : students.length === 0
              ? <EmptyState title="No student accounts" detail="Registered student accounts will appear here." />
              : <>
                <div className="table-wrap">
                  <table>
                    <thead><tr><th>Student</th><th>Username</th><th>Email</th><th>Registered</th></tr></thead>
                    <tbody>
                      {students.map((student) => (
                        <tr key={student.id}>
                          <td><strong>{student.fullName}</strong></td>
                          <td>@{student.username}</td>
                          <td>{student.email}</td>
                          <td>{student.createdAt ? new Date(student.createdAt).toLocaleDateString() : '—'}</td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>
                {pagination && <Pagination page={pagination.page} pageCount={pagination.pageCount} onChange={changePage} />}
              </>}
      </section>
    </div>
  );
}
