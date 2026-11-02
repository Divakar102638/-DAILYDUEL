import { afterEach, describe, expect, it, vi } from 'vitest';
import { ApiError, DailyDuelApi } from './api';

function response(payload: unknown, status = 200) {
  return {
    ok: status >= 200 && status < 300,
    status,
    json: async () => payload,
  } as Response;
}

afterEach(() => {
  vi.unstubAllGlobals();
  window.sessionStorage.clear();
});

describe('DailyDuel admin API authentication', () => {
  it('stores a tab-scoped token only after backend session and admin checks succeed', async () => {
    const fetchMock = vi.fn(async (input: RequestInfo | URL, _init?: RequestInit) => {
      const path = new URL(String(input)).pathname;
      if (path.endsWith('/auth/login')) return response({ token: 'short-lived-test-token' });
      if (path.endsWith('/auth/session')) return response({
        user: { id: 'admin-1', fullName: 'Admin User', username: 'admin', email: 'admin@example.test', role: 'admin' },
      });
      if (path.endsWith('/admin/access')) return response({ authorized: true });
      return response({ error: { message: 'Unexpected request' } }, 404);
    });
    vi.stubGlobal('fetch', fetchMock);
    const client = new DailyDuelApi();

    const user = await client.login('admin@example.test', 'private-password');

    expect(user.role).toBe('admin');
    expect(window.sessionStorage.length).toBe(1);
    expect(fetchMock).toHaveBeenCalledTimes(3);
    const loginCall = fetchMock.mock.calls[0];
    expect(loginCall[1]?.method).toBe('POST');
    expect(loginCall[1]?.body).toContain('"email":"admin@example.test"');
  });

  it('clears the token and rejects a normal user even after successful login', async () => {
    const fetchMock = vi.fn(async (input: RequestInfo | URL) => {
      const path = new URL(String(input)).pathname;
      if (path.endsWith('/auth/login')) return response({ token: 'token-for-user' });
      return response({
        user: { id: 'user-1', fullName: 'Student', username: 'student', email: 'student@example.test', role: 'user' },
      });
    });
    vi.stubGlobal('fetch', fetchMock);
    const client = new DailyDuelApi();

    await expect(client.login('student@example.test', 'password'))
      .rejects.toMatchObject({ status: 403 });
    expect(window.sessionStorage.length).toBe(0);
    expect(fetchMock).toHaveBeenCalledTimes(2);
  });

  it('clears revoked sessions and gives safe API errors without raw response details', async () => {
    vi.stubGlobal('fetch', vi.fn(async () => response({
      error: { code: 'UNAUTHENTICATED', message: 'A valid login session is required.', details: 'private backend detail' },
    }, 401)));
    const client = new DailyDuelApi();
    client.setSessionToken('expired-token');

    await expect(client.get('/api/v1/admin/access')).rejects.toMatchObject({
      status: 401,
      message: 'A valid login session is required.',
    });
    await expect(client.get('/api/v1/admin/access')).rejects.toBeInstanceOf(ApiError);
  });
});
