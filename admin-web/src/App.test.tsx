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
  return vi.fn(async (input: RequestInfo | URL, init?: RequestInit) => {
    const url = new URL(String(input));
    if (url.pathname.endsWith('/api/v1/auth/login')) {
      return jsonResponse({ token: 'test-token' });
    }
    if (url.pathname.endsWith('/api/v1/auth/admin-setup/status')) {
      return jsonResponse({ setupAvailable: false });
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
    if (url.pathname.endsWith('/api/v1/admin/quizzes/ai-categories')) {
      return jsonResponse({
        categories: [
          { id: 'sports', label: 'Sports' },
          { id: 'politics', label: 'Politics' },
          { id: 'cinema', label: 'Cinema' },
          { id: 'technology', label: 'Technology' },
          { id: 'general-knowledge', label: 'General Knowledge' },
          { id: 'entertainment', label: 'Entertainment' },
        ],
      });
    }
    if (url.pathname.endsWith('/api/v1/admin/quizzes/questions/generate')) {
      const requestBody = JSON.parse(String(init?.body)) as { count?: number };
      return jsonResponse({ questionsCreated: requestBody.count ?? 15 }, 201);
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

  it('generates configurable AI drafts through the protected backend API', async () => {
    const fetchMock = authenticatedFetch();
    vi.stubGlobal('fetch', fetchMock);
    vi.stubGlobal('crypto', { randomUUID: () => 'c844c5ab-1aef-4a2d-b95b-23fb479feb2e' });
    const user = userEvent.setup();
    render(<App />);

    await user.type(await screen.findByLabelText('Email address'), 'admin@example.test');
    await user.type(screen.getByLabelText('Password'), 'test-admin-password');
    await user.click(screen.getByRole('button', { name: 'Sign in securely' }));
    await user.click(await screen.findByRole('link', { name: /Question bank/ }));
    await user.click(await screen.findByRole('button', { name: 'Generate with AI' }));
    expect(screen.getByLabelText('Number of questions')).toHaveValue(15);
    await user.selectOptions(await screen.findByLabelText('Category'), 'sports');
    await user.type(screen.getByLabelText('Subject or topic'), 'World Cup history');
    await user.clear(screen.getByLabelText('Number of questions'));
    await user.type(screen.getByLabelText('Number of questions'), '3');
    await user.clear(screen.getByLabelText('Language'));
    await user.type(screen.getByLabelText('Language'), 'Telugu');
    await user.click(screen.getByRole('button', { name: 'Generate drafts' }));

    expect(await screen.findByRole('status')).toHaveTextContent(
      '3 AI questions were saved as drafts.',
    );
    const generationCall = fetchMock.mock.calls.find(([input]) =>
      new URL(String(input)).pathname.endsWith('/api/v1/admin/quizzes/questions/generate'),
    );
    expect(generationCall?.[1]?.method).toBe('POST');
    expect(JSON.parse(String(generationCall?.[1]?.body))).toEqual({
      requestId: 'c844c5ab-1aef-4a2d-b95b-23fb479feb2e',
      category: 'sports',
      topic: 'World Cup history',
      count: 3,
      language: 'Telugu',
      difficulty: 'mixed',
    });
  });

  it('validates question quantity before sending an AI generation request', async () => {
    const fetchMock = authenticatedFetch();
    vi.stubGlobal('fetch', fetchMock);
    const user = userEvent.setup();
    render(<App />);

    await user.type(await screen.findByLabelText('Email address'), 'admin@example.test');
    await user.type(screen.getByLabelText('Password'), 'test-admin-password');
    await user.click(screen.getByRole('button', { name: 'Sign in securely' }));
    await user.click(await screen.findByRole('link', { name: /Question bank/ }));
    await user.click(await screen.findByRole('button', { name: 'Generate with AI' }));
    await user.selectOptions(await screen.findByLabelText('Category'), 'sports');
    const countInput = screen.getByLabelText('Number of questions');
    await user.clear(countInput);
    await user.type(countInput, '0');
    expect(countInput).toBeInvalid();
    await user.click(screen.getByRole('button', { name: 'Generate drafts' }));

    expect(
      fetchMock.mock.calls.some(([input]) =>
        new URL(String(input)).pathname.endsWith('/api/v1/admin/quizzes/questions/generate'),
      ),
    ).toBe(false);
  });

  it('keeps generation retries idempotent and reports provider errors', async () => {
    const fetchMock = authenticatedFetch();
    const defaultFetch = fetchMock.getMockImplementation();
    let finishGeneration!: (response: Response) => void;
    const pendingGeneration = new Promise<Response>((resolve) => {
      finishGeneration = resolve;
    });
    fetchMock.mockImplementation(async (input, init) => {
      if (new URL(String(input)).pathname.endsWith('/api/v1/admin/quizzes/questions/generate')) {
        return pendingGeneration;
      }
      return defaultFetch!(input, init);
    });
    vi.stubGlobal('fetch', fetchMock);
    const user = userEvent.setup();
    render(<App />);

    await user.type(await screen.findByLabelText('Email address'), 'admin@example.test');
    await user.type(screen.getByLabelText('Password'), 'test-admin-password');
    await user.click(screen.getByRole('button', { name: 'Sign in securely' }));
    await user.click(await screen.findByRole('link', { name: /Question bank/ }));
    await user.click(await screen.findByRole('button', { name: 'Generate with AI' }));
    await user.selectOptions(await screen.findByLabelText('Category'), 'sports');
    await user.click(screen.getByRole('button', { name: 'Generate drafts' }));

    expect(screen.getByRole('button', { name: 'Generating drafts…' })).toBeDisabled();
    finishGeneration(jsonResponse(
      { error: { code: 'AI_PROVIDER_UNAVAILABLE', message: 'AI service is unavailable.' } },
      503,
    ));
    expect(await screen.findByText('AI service is unavailable.')).toBeInTheDocument();
    await user.click(screen.getByRole('button', { name: 'Generate drafts' }));
    const generationCalls = fetchMock.mock.calls.filter(([input]) =>
      new URL(String(input)).pathname.endsWith('/api/v1/admin/quizzes/questions/generate'),
    );
    expect(generationCalls).toHaveLength(2);
    expect(
      JSON.parse(String(generationCalls[0][1]?.body)).requestId,
    ).toBe(JSON.parse(String(generationCalls[1][1]?.body)).requestId);
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
