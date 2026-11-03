import { useState, type FormEvent } from 'react';
import { useAuth } from '../auth-context';
import { ApiError } from '../api';
import { Alert } from '../components/ui';

function getSignInFailureCategory(reason: unknown) {
  if (!(reason instanceof ApiError)) return 'unexpected_client_error';
  if (reason.status === 0) return 'network_error';
  if (reason.status === 400) return 'validation_error';
  if (reason.status === 401) return 'authentication_failed';
  if (reason.status === 403) return 'admin_authorization_failed';
  if (reason.status === 429) return 'rate_limited';
  if (reason.status >= 500) return 'backend_error';
  return 'http_error';
}

export function LoginPage() {
  const { signIn, setupAvailable, setupError, createAdminAccount } = useAuth();
  const [mode, setMode] = useState<'setup' | 'login'>(setupAvailable ? 'setup' : 'login');
  const [fullName, setFullName] = useState('');
  const [username, setUsername] = useState('');
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [confirmPassword, setConfirmPassword] = useState('');
  const [setupSecret, setSetupSecret] = useState('');
  const [showPasswords, setShowPasswords] = useState(false);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState('');
  const [notice, setNotice] = useState('');

  async function submit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    setError('');
    setBusy(true);
    try {
      await signIn(email.trim(), password);
    } catch (reason) {
      console.warn('[DailyDuel admin] Sign-in failed', {
        status: reason instanceof ApiError && reason.status > 0 ? reason.status : null,
        category: getSignInFailureCategory(reason),
        endpoint: reason instanceof ApiError ? reason.endpoint ?? 'sign_in' : 'sign_in',
      });
      setError(reason instanceof ApiError ? reason.message : 'Sign in failed. Try again.');
    } finally {
      setBusy(false);
    }
  }

  async function submitSetup(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    setError('');
    setNotice('');
    if (password !== confirmPassword) {
      setError('Passwords do not match.');
      return;
    }

    setBusy(true);
    try {
      await createAdminAccount({
        fullName,
        username,
        email: email.trim(),
        password,
        confirmPassword,
        setupSecret,
      });
      setMode('login');
      setPassword('');
      setConfirmPassword('');
      setSetupSecret('');
      setNotice('Administrator setup is complete. Sign in with the account you just created.');
    } catch (reason) {
      setError(reason instanceof ApiError ? reason.message : 'Administrator setup failed. Try again.');
    } finally {
      setBusy(false);
    }
  }

  return (
    <main className="login-screen">
      <section className="login-story">
        <div className="brand brand-light"><span className="brand-mark">D</span><span><strong>DailyDuel</strong><small>ADMIN CONSOLE</small></span></div>
        <div className="login-pitch">
          <p className="eyebrow eyebrow-light">ADMINISTRATION WORKSPACE</p>
          <h1>Make every quiz<br />count.</h1>
          <p>Manage trusted questions, schedule competitions, and review published outcomes from one focused workspace.</p>
          <div className="login-note"><span className="secure-dot" /> Protected by your DailyDuel API</div>
        </div>
        <div className="login-decoration" aria-hidden="true"><span /><span /><span /></div>
        <small className="login-footer">Built for educators and competition hosts.</small>
      </section>
      <section className="login-panel">
        <form className="login-card" onSubmit={mode === 'setup' ? submitSetup : submit}>
          <p className="eyebrow">{mode === 'setup' ? 'FIRST-TIME SETUP' : 'WELCOME BACK'}</p>
          <h2>{mode === 'setup' ? 'Welcome to DailyDuel Admin Setup' : 'Administrator sign in'}</h2>
          <p className="muted">
            {mode === 'setup'
              ? 'Create the separate administrator account. Setup requires the one-time authorization secret.'
              : 'Use your existing DailyDuel administrator account.'}
          </p>
          {setupError && <Alert>{setupError}</Alert>}
          {notice && <div className="alert alert-success" role="status">{notice}</div>}
          {error && <Alert>{error}</Alert>}
          {mode === 'setup' ? (
            <>
              <label className="field">
                <span>Full name</span>
                <input autoComplete="name" required maxLength={80} value={fullName} onChange={(event) => setFullName(event.target.value)} />
              </label>
              <label className="field">
                <span>Username</span>
                <input autoComplete="username" required minLength={3} maxLength={20} pattern="[a-zA-Z0-9_]+" value={username} onChange={(event) => setUsername(event.target.value)} />
              </label>
              <label className="field">
                <span>Admin email</span>
                <input autoComplete="email" type="email" required maxLength={254} value={email} onChange={(event) => setEmail(event.target.value)} />
              </label>
              <label className="field">
                <span>Password (at least 12 characters)</span>
                <input autoComplete="new-password" type={showPasswords ? 'text' : 'password'} required minLength={12} maxLength={128} value={password} onChange={(event) => setPassword(event.target.value)} />
              </label>
              <label className="field">
                <span>Confirm password</span>
                <input autoComplete="new-password" type={showPasswords ? 'text' : 'password'} required minLength={12} maxLength={128} value={confirmPassword} onChange={(event) => setConfirmPassword(event.target.value)} />
              </label>
              <button className="button button-secondary button-small" type="button" onClick={() => setShowPasswords((visible) => !visible)}>
                {showPasswords ? 'Hide passwords' : 'Show passwords'}
              </button>
              <label className="field">
                <span>One-time setup secret</span>
                <input autoComplete="off" type="password" required minLength={32} maxLength={256} value={setupSecret} onChange={(event) => setSetupSecret(event.target.value)} />
              </label>
              <button className="button button-primary button-full" disabled={busy}>
                {busy ? <><span className="spinner spinner-light" /> Creating administrator…</> : 'Create administrator'}
              </button>
            </>
          ) : (
            <>
              <label className="field">
                <span>Email address</span>
                <input autoComplete="username" type="email" required maxLength={254} value={email} onChange={(event) => setEmail(event.target.value)} />
              </label>
              <label className="field">
                <span>Password</span>
                <input autoComplete="current-password" type={showPasswords ? 'text' : 'password'} required maxLength={128} value={password} onChange={(event) => setPassword(event.target.value)} />
              </label>
              <button className="button button-secondary button-small" type="button" onClick={() => setShowPasswords((visible) => !visible)}>
                {showPasswords ? 'Hide password' : 'Show password'}
              </button>
              <button className="button button-primary button-full" disabled={busy}>
                {busy ? <><span className="spinner spinner-light" /> Verifying access…</> : 'Sign in securely'}
              </button>
              <p className="login-security">Your role is confirmed by the backend. A successful login alone does not grant administrator access.</p>
            </>
          )}
        </form>
      </section>
    </main>
  );
}
