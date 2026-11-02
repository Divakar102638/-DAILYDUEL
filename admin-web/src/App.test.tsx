import { fireEvent, render, screen, waitFor } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { afterEach, describe, expect, it, vi } from 'vitest';
import App from './App';
import { api } from './api';

function jsonResponse(payload: unknown, status = 200) {
  return {
    ok: status >= 200 && status < 300,
    status,
    json: async () => payload,
  } as Response;
}

function authenticatedFetch(role: 'admin' | 'user' = 'admin') {
  return vi.fn(async (input: RequestInfo | URL) => {
    const url = new URL(String(input));
    if (url.pathname.endsWith('/api/v1/auth/login')) {
      return jsonResponse({ token: 'test-token' });
    }
    if (url.pathname.endsWith('/api/v1/auth/session')) {
      return jsonResponse({
        user: { id: 'user-1', fullName: 'DailyDuel Admin', username: 'admin', email: 'admin@example.test', role },
      });
    }
    if (url.pathname.endsWith('/api/v1/admin/access')) {
      return role === 'admin'
        ? jsonResponse({ authorized: true })
        : jsonResponse({ error: { message: 'Administrator permissions are required.' } }, 403);
    }
    if (url.pathname.endsWith('/api/v1/admin/quizzes/exams')) {
      return jsonResponse({ exams: [], pagination: { page: 1, pageSize: 1, total: 0, pageCount: 0 } });
    }
    if (url.pathname.endsWith('/api/v1/admin/quizzes/questions')) {
      return jsonResponse({ questions: [], pagination: { page: 1, pageSize: 1, total: 0, pageCount: 0 } });
    }
    if (url.pathname.endsWith('/api/v1/admin/quizzes/categories')) {
      return jsonResponse({ categories: [] });
    }
    if (url.pathname.endsWith('/api/v1/admin/users')) {
      return jsonResponse({
        users: [{
          id: 'student-1',
          fullName: 'Student One',
          username: 'student_one',
          email: 'student@example.test',
          createdAt: '2026-01-02T03:04:05.000Z',
        }],
        pagination: { page: 1, pageSize: 25, total: 1, pageCount: 1 },
      });
    }
    return jsonResponse({ error: { message: 'Not found.' } }, 404);
  });
}

afterEach(() => {
  vi.unstubAllGlobals();
  api.setSessionToken(null);
  window.history.replaceState({}, '', '/');
});

describe('admin portal authentication and dashboard', () => {
  it('requires an administrator session before rendering protected pages', async () => {
    const fetchMock = authenticatedFetch('user');
    vi.stubGlobal('fetch', fetchMock);
    const user = userEvent.setup();
    render(<App />);

    await user.type(await screen.findByLabelText('Email address'), 'student@example.test');
    await user.type(screen.getByLabelText('Password'), 'not-an-admin-password');
    await user.click(screen.getByRole('button', { name: 'Sign in securely' }));

    expect(await screen.findByRole('alert')).toHaveTextContent('Administrator');
    expect(screen.queryByRole('heading', { name: 'Overview' })).not.toBeInTheDocument();
    expect(fetchMock).not.toHaveBeenCalledWith(
      expect.stringContaining('/api/v1/admin/quizzes/exams'),
      expect.anything(),
    );
    expect(window.sessionStorage.length).toBe(0);
  });

  it('loads real empty-state dashboard data after backend verifies an admin', async () => {
    vi.stubGlobal('fetch', authenticatedFetch());
    const user = userEvent.setup();
    render(<App />);

    await user.type(await screen.findByLabelText('Email address'), 'admin@example.test');
    await user.type(screen.getByLabelText('Password'), 'test-admin-password');
    await user.click(screen.getByRole('button', { name: 'Sign in securely' }));

    expect(await screen.findByRole('heading', { name: 'Overview' })).toBeInTheDocument();
    expect(await screen.findByText('No active categories')).toBeInTheDocument();
    expect(screen.getAllByText('0', { selector: '.stat-value' })).toHaveLength(4);
    expect(screen.getByRole('link', { name: /Question bank/ })).toBeInTheDocument();
  });

  it('supports dismissing management dialogs without writing data', async () => {
    vi.stubGlobal('fetch', authenticatedFetch());
    const user = userEvent.setup();
    render(<App />);
    await user.type(await screen.findByLabelText('Email address'), 'admin@example.test');
    await user.type(screen.getByLabelText('Password'), 'test-admin-password');
    await user.click(screen.getByRole('button', { name: 'Sign in securely' }));
    await screen.findByRole('heading', { name: 'Overview' });
    await user.click(screen.getByRole('link', { name: /Categories/ }));

    await user.click(await screen.findByRole('button', { name: 'Add category' }));
    expect(screen.getByRole('dialog', { name: 'Create category' })).toBeInTheDocument();
    fireEvent.click(screen.getByRole('button', { name: 'Close dialog' }));
    await waitFor(() => {
      expect(screen.queryByRole('dialog')).not.toBeInTheDocument();
    });
  });

  it('displays registered students from the protected backend endpoint', async () => {
    const fetchMock = authenticatedFetch();
    vi.stubGlobal('fetch', fetchMock);
    const user = userEvent.setup();
    render(<App />);

    await user.type(await screen.findByLabelText('Email address'), 'admin@example.test');
    await user.type(screen.getByLabelText('Password'), 'test-admin-password');
    await user.click(await screen.findByRole('button', { name: 'Sign in securely' }));

    await user.click(await screen.findByRole('link', { name: /Students/ }));
    expect(await screen.findByRole('heading', { name: 'Registered students' })).toBeInTheDocument();
    expect(screen.getByText('Student One')).toBeInTheDocument();
    expect(screen.getByText('student@example.test')).toBeInTheDocument();
    expect(fetchMock).toHaveBeenCalledWith(
      expect.stringContaining('/api/v1/admin/users?page=1&pageSize=25'),
      expect.objectContaining({ headers: expect.any(Headers) }),
    );
  });
});
