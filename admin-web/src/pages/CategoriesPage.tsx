import { useState, type FormEvent } from 'react';
import { api, ApiError } from '../api';
import type { Category } from '../types';
import { Alert, EmptyState, LoadingState, PageHeader } from '../components/ui';
import { useApiResource } from '../hooks/useApiResource';

const emptyCategory: Category = { id: '', name: '', subcategories: [], active: true };

export function CategoriesPage() {
  const resource = useApiResource(() => api.categories());
  const [editing, setEditing] = useState<Category | null>(null);
  const [subcategoriesText, setSubcategoriesText] = useState('');
  const [busy, setBusy] = useState(false);
  const [message, setMessage] = useState('');
  const [error, setError] = useState('');

  function startEdit(category: Category) {
    setEditing({ ...category });
    setSubcategoriesText(category.subcategories.join('\n'));
    setError('');
    setMessage('');
  }

  function startCreate() {
    startEdit(emptyCategory);
  }

  async function save(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    if (!editing) return;
    const id = editing.id.trim().toLowerCase().replaceAll(' ', '-');
    const subcategories = [...new Set(subcategoriesText.split(/\r?\n/).map((value) => value.trim()).filter(Boolean))];
    if (!/^[a-z0-9][a-z0-9-]{1,79}$/.test(id)) {
      setError('Use a category ID with lowercase letters, numbers, and hyphens (at least 2 characters).');
      return;
    }
    if (subcategories.length === 0) {
      setError('Add at least one subcategory, one per line.');
      return;
    }
    setBusy(true);
    setError('');
    try {
      await api.put(`/api/v1/admin/quizzes/categories/${encodeURIComponent(id)}`, {
        name: editing.name.trim(),
        subcategories,
        active: editing.active,
      });
      setEditing(null);
      setMessage('Category saved.');
      resource.reload();
    } catch (reason) {
      setError(reason instanceof ApiError ? reason.message : 'Category could not be saved.');
    } finally {
      setBusy(false);
    }
  }

  return (
    <div className="page-stack">
      <PageHeader eyebrow="CONTENT SETUP" title="Categories" description="Configure the taxonomy used by casual quizzes and competitive exams." action={<button className="button button-primary" onClick={startCreate}>Add category</button>} />
      {message && <Alert kind="success">{message}</Alert>}
      {error && !editing && <Alert>{error}</Alert>}
      {resource.loading && <LoadingState />}
      {resource.error && <Alert>{resource.error}</Alert>}
      {resource.data && (
        <section className="panel">
          <div className="table-toolbar"><div><h2>Configured categories</h2><p>{resource.data.length} categories returned by the backend</p></div><button className="button button-secondary" onClick={resource.reload}>Refresh</button></div>
          {resource.data.length === 0
            ? <EmptyState title="No categories configured" detail="Add a category to organize the question bank." />
            : <div className="category-grid">{resource.data.map((category) => (
              <article className="category-card" key={category.id}>
                <div className="category-card-top"><div><span className="category-icon">{category.name.slice(0, 1).toUpperCase()}</span><div><h3>{category.name}</h3><small>{category.id}</small></div></div><span className={`availability ${category.active ? 'available' : 'unavailable'}`}>{category.active ? 'Active' : 'Inactive'}</span></div>
                <div className="chip-list">{category.subcategories.map((subcategory) => <span className="chip" key={subcategory}>{subcategory}</span>)}</div>
                <button className="button button-secondary button-small" onClick={() => startEdit(category)}>Edit configuration</button>
              </article>
            ))}</div>}
        </section>
      )}
      {editing && (
        <div className="modal-backdrop">
          <section className="modal" role="dialog" aria-modal="true" aria-label={editing.id ? 'Edit category' : 'Create category'}>
            <div className="modal-heading"><h2>{editing.id ? 'Edit category' : 'Create category'}</h2><button className="icon-button" aria-label="Close dialog" onClick={() => setEditing(null)}>×</button></div>
            <form className="form-stack" onSubmit={save}>
              {error && <Alert>{error}</Alert>}
              <label className="field"><span>Category ID</span><input required disabled={Boolean(resource.data?.some((category) => category.id === editing.id))} value={editing.id} onChange={(event) => setEditing({ ...editing, id: event.target.value })} placeholder="e.g. science-and-tech" /></label>
              <label className="field"><span>Display name</span><input required minLength={2} maxLength={80} value={editing.name} onChange={(event) => setEditing({ ...editing, name: event.target.value })} /></label>
              <label className="field"><span>Subcategories <small>One per line</small></span><textarea rows={7} required value={subcategoriesText} onChange={(event) => setSubcategoriesText(event.target.value)} /></label>
              <label className="checkbox-field"><input type="checkbox" checked={editing.active} onChange={(event) => setEditing({ ...editing, active: event.target.checked })} /><span>Category is active and available to participants</span></label>
              <div className="form-actions"><button type="button" className="button button-secondary" onClick={() => setEditing(null)}>Cancel</button><button className="button button-primary" disabled={busy}>{busy ? 'Saving…' : 'Save category'}</button></div>
            </form>
          </section>
        </div>
      )}
    </div>
  );
}
