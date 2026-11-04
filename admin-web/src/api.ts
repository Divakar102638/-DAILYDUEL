import type {
  AdminExam,
  AdminQuestion,
  AdminCredentialUpdate,
  AdminStudent,
  AdminSetupInput,
  AdminUser,
  Category,
  ExamResult,
  Pagination,
} from './types';

const TOKEN_KEY = 'dailyduel.admin.session-token';
const configuredBaseUrl = import.meta.env.VITE_API_BASE_URL?.trim();
const defaultBaseUrl = import.meta.env.PROD
  ? 'https://dailyduel.onrender.com'
  : 'http://localhost:3000';
export const apiBaseUrl = (configuredBaseUrl || defaultBaseUrl).replace(/\/+$/, '');

export class ApiError extends Error {
  readonly status: number;
  readonly code?: string;
  readonly endpoint?: string;

  constructor(
    message: string,
    status: number,
    code?: string,
    endpoint?: string,
  ) {
    super(message);
    this.name = 'ApiError';
    this.status = status;
    this.code = code;
    this.endpoint = endpoint;
  }
}

interface ApiErrorBody {
  error?: { message?: unknown; code?: unknown };
}

export class DailyDuelApi {
  private token: string | null = null;

  get hasSessionToken() {
    return this.token !== null;
  }

  getSessionToken() {
    return this.token;
  }

  setSessionToken(token: string | null) {
    this.token = token;
    if (typeof window !== 'undefined') {
      if (token) window.sessionStorage.setItem(TOKEN_KEY, token);
      else window.sessionStorage.removeItem(TOKEN_KEY);
    }
  }

  private readStoredToken() {
    if (this.token) return this.token;
    if (typeof window === 'undefined') return null;
    this.token = window.sessionStorage.getItem(TOKEN_KEY);
    return this.token;
  }

  async request<T>(
    path: string,
    options: { method?: string; body?: unknown; token?: string | null } = {},
  ): Promise<T> {
    const token = options.token === undefined ? this.readStoredToken() : options.token;
    const headers = new Headers({ Accept: 'application/json' });
    if (options.body !== undefined) headers.set('Content-Type', 'application/json');
    if (token) headers.set('Authorization', `Bearer ${token}`);

    let response: Response;
    try {
      response = await fetch(`${apiBaseUrl}${path}`, {
        method: options.method ?? 'GET',
        headers,
        ...(options.body === undefined ? {} : { body: JSON.stringify(options.body) }),
      });
    } catch {
      throw new ApiError(
        'Could not reach the DailyDuel API. Check the backend and local CORS configuration.',
        0,
        'NETWORK_ERROR',
        path,
      );
    }

    const payload = await response.json().catch(() => null) as ApiErrorBody | null;
    if (!response.ok) {
      if (response.status === 401 || response.status === 403) {
        this.setSessionToken(null);
        if (typeof window !== 'undefined') {
          window.dispatchEvent(new Event('dailyduel:unauthorized'));
        }
      }
      const message = typeof payload?.error?.message === 'string'
        ? payload.error.message
        : response.status === 401
          ? 'Your session has expired. Sign in again.'
          : 'The request could not be completed.';
      const code = typeof payload?.error?.code === 'string' ? payload.error.code : undefined;
      throw new ApiError(message, response.status, code, path);
    }
    return payload as T;
  }

  async login(email: string, password: string): Promise<AdminUser> {
    const session = await this.request<{ token: string }>(
      '/api/v1/auth/login',
      { method: 'POST', body: { email, password }, token: null },
    );
    if (typeof session.token !== 'string' || !session.token) {
      throw new ApiError(
        'The API returned an invalid login response.',
        502,
        'INVALID_LOGIN_RESPONSE',
        '/api/v1/auth/login',
      );
    }

    this.setSessionToken(session.token);
    try {
      const verified = await this.request<{ user: AdminUser }>('/api/v1/auth/session');
      if (verified.user?.role !== 'admin') {
        throw new ApiError(
          'Administrator access is required.',
          403,
          'ADMIN_REQUIRED',
          '/api/v1/auth/session',
        );
      }
      await this.request<{ authorized: true }>('/api/v1/admin/access');
      return verified.user;
    } catch (error) {
      this.setSessionToken(null);
      throw error;
    }
  }

  async adminSetupAvailable() {
    const result = await this.request<{ setupAvailable: boolean }>(
      '/api/v1/auth/admin-setup/status',
      { token: null },
    );
    return result.setupAvailable === true;
  }

  async createFirstAdmin(input: AdminSetupInput) {
    return this.request<{ initialized: true }>(
      '/api/v1/auth/admin-setup',
      { method: 'POST', body: input, token: null },
    );
  }

  async updateAdminCredentials(input: AdminCredentialUpdate) {
    const result = await this.request<{ token: string; user: AdminUser }>(
      '/api/v1/auth/account/credentials',
      { method: 'PATCH', body: input },
    );
    if (typeof result.token !== 'string' || !result.token) {
      throw new ApiError(
        'The API returned an invalid account update response.',
        502,
        'INVALID_CREDENTIAL_UPDATE_RESPONSE',
        '/api/v1/auth/account/credentials',
      );
    }
    this.setSessionToken(result.token);
    return { user: result.user };
  }

  async restoreAdminSession(): Promise<AdminUser | null> {
    if (!this.readStoredToken()) return null;
    try {
      const session = await this.request<{ user: AdminUser }>('/api/v1/auth/session');
      if (session.user?.role !== 'admin') {
        this.setSessionToken(null);
        return null;
      }
      await this.request<{ authorized: true }>('/api/v1/admin/access');
      return session.user;
    } catch (error) {
      if (error instanceof ApiError && (error.status === 401 || error.status === 403)) {
        this.setSessionToken(null);
        return null;
      }
      throw error;
    }
  }

  async logout() {
    this.setSessionToken(null);
  }

  get<T>(path: string) {
    return this.request<T>(path);
  }

  post<T>(path: string, body: unknown) {
    return this.request<T>(path, { method: 'POST', body });
  }

  put<T>(path: string, body: unknown) {
    return this.request<T>(path, { method: 'PUT', body });
  }

  patch<T>(path: string, body?: unknown) {
    return this.request<T>(path, { method: 'PATCH', ...(body === undefined ? {} : { body }) });
  }

  async categories() {
    return (await this.get<{ categories: Category[] }>('/api/v1/admin/quizzes/categories')).categories;
  }

  async students(params = new URLSearchParams()) {
    const suffix = params.size ? `?${params}` : '';
    return this.get<{ users: AdminStudent[]; pagination: Pagination }>(
      `/api/v1/admin/users${suffix}`,
    );
  }

  async exams(params = new URLSearchParams()) {
    const suffix = params.size ? `?${params}` : '';
    return this.get<{ exams: AdminExam[]; pagination: Pagination }>(
      `/api/v1/admin/quizzes/exams${suffix}`,
    );
  }

  async questions(params = new URLSearchParams()) {
    const suffix = params.size ? `?${params}` : '';
    return this.get<{ questions: AdminQuestion[]; pagination: Pagination }>(
      `/api/v1/admin/quizzes/questions${suffix}`,
    );
  }

  async results(examId: string, page = 1) {
    return this.get<{
      exam: { title: string };
      results: ExamResult[];
      pagination: Pagination;
    }>(
      `/api/v1/admin/quizzes/exams/${encodeURIComponent(examId)}/results?page=${page}&pageSize=25`,
    );
  }
}

export const api = new DailyDuelApi();
