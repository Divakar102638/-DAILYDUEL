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
  it('checks setup availability and submits setup credentials only to the API', async () => {
    const fetchMock = vi.fn(async (input: RequestInfo | URL, _init?: RequestInit) => {
      const path = new URL(String(input)).pathname;
      if (path.endsWith('/admin-setup/status')) {
        return response({ setupAvailable: true });
      }
      return response({ initialized: true }, 201);
    });
    vi.stubGlobal('fetch', fetchMock);
    const client = new DailyDuelApi();

    expect(await client.adminSetupAvailable()).toBe(true);
    await client.createFirstAdmin({
      fullName: 'Test Admin',
      username: 'test_admin',
      email: 'admin@example.test',
      password: 'a-private-test-password',
      confirmPassword: 'a-private-test-password',
      setupSecret: 'private-test-one-time-secret',
    });

    expect(fetchMock).toHaveBeenCalledTimes(2);
    const statusRequest = fetchMock.mock.calls[0]?.[1];
    const setupRequest = fetchMock.mock.calls[1]?.[1];
    expect(statusRequest).toBeDefined();
    expect(setupRequest?.method).toBe('POST');
    expect(new Headers(statusRequest?.headers).has('Authorization')).toBe(false);
  });

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

  it('clears the tab-scoped session when signing out', async () => {
    const client = new DailyDuelApi();
    client.setSessionToken('test-token');

    await client.logout();

    expect(client.hasSessionToken).toBe(false);
    expect(window.sessionStorage.length).toBe(0);
  });

  it('sends credential updates using the authenticated admin session', async () => {
    const fetchMock = vi.fn(async (_input: RequestInfo | URL, init?: RequestInit) => {
      expect(init?.method).toBe('PATCH');
      expect(new Headers(init?.headers).get('Authorization')).toBe('Bearer admin-session-token');
      return response({
        token: 'rotated-admin-session-token',
        user: {
          id: 'admin-1',
          fullName: 'Admin User',
          username: 'admin',
          email: 'new-admin@example.test',
          role: 'admin',
        },
      });
    });
    vi.stubGlobal('fetch', fetchMock);
    const client = new DailyDuelApi();
    client.setSessionToken('admin-session-token');

    const result = await client.updateAdminCredentials({
      currentPassword: 'private-current-password',
      email: 'new-admin@example.test',
    });

    expect(result.user.email).toBe('new-admin@example.test');
    expect(client.getSessionToken()).toBe('rotated-admin-session-token');
    expect(fetchMock).toHaveBeenCalledTimes(1);
  });
});
