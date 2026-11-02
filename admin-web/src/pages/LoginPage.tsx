import { useState, type FormEvent } from 'react';
import { useAuth } from '../auth-context';
import { ApiError } from '../api';
import { Alert } from '../components/ui';

export function LoginPage() {
  const { signIn } = useAuth();
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState('');

  async function submit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    setError('');
    setBusy(true);
    try {
      await signIn(email.trim(), password);
    } catch (reason) {
      setError(reason instanceof ApiError ? reason.message : 'Sign in failed. Try again.');
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
        <form className="login-card" onSubmit={submit}>
          <p className="eyebrow">WELCOME BACK</p>
          <h2>Administrator sign in</h2>
          <p className="muted">Use your existing DailyDuel administrator account.</p>
          {error && <Alert>{error}</Alert>}
          <label className="field">
            <span>Email address</span>
            <input autoComplete="username" type="email" required maxLength={254} value={email} onChange={(event) => setEmail(event.target.value)} />
          </label>
          <label className="field">
            <span>Password</span>
            <input autoComplete="current-password" type="password" required maxLength={128} value={password} onChange={(event) => setPassword(event.target.value)} />
          </label>
          <button className="button button-primary button-full" disabled={busy}>
            {busy ? <><span className="spinner spinner-light" /> Verifying access…</> : 'Sign in securely'}
          </button>
          <p className="login-security">Your role is confirmed by the backend. A successful login alone does not grant administrator access.</p>
        </form>
      </section>
    </main>
  );
}
