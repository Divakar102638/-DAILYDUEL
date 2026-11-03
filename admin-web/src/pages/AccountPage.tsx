import { useState, type FormEvent } from 'react';
import { useAuth } from '../auth-context';
import { ApiError } from '../api';
import { Alert, PageHeader } from '../components/ui';

export function AccountPage() {
  const { user, signOut, updateAdminCredentials } = useAuth();
  const [email, setEmail] = useState(user?.email ?? '');
  const [currentPassword, setCurrentPassword] = useState('');
  const [newPassword, setNewPassword] = useState('');
  const [confirmPassword, setConfirmPassword] = useState('');
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState('');
  const [notice, setNotice] = useState('');

  async function submit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    setError('');
    setNotice('');
    if (newPassword && newPassword !== confirmPassword) {
      setError('The new passwords do not match.');
      return;
    }

    setBusy(true);
    try {
      await updateAdminCredentials({
        currentPassword,
        ...(email.trim().toLowerCase() === user?.email
          ? {}
          : { email: email.trim() }),
        ...(newPassword
          ? { newPassword, confirmPassword }
          : {}),
      });
      setCurrentPassword('');
      setNewPassword('');
      setConfirmPassword('');
      setNotice('Your administrator account details were updated.');
    } catch (reason) {
      setError(
        reason instanceof ApiError
          ? reason.message
          : 'Could not update your account. Please try again.',
      );
    } finally {
      setBusy(false);
    }
  }

  return (
    <div className="page-stack">
      <PageHeader eyebrow="ACCOUNT & SECURITY" title="Administrator account" description="Your identity and access are verified against the DailyDuel backend." />
      <section className="panel account-panel">
        <div className="account-avatar-large">{user?.fullName?.slice(0, 1).toUpperCase()}</div>
        <div className="account-details">
          <span className="eyebrow">BACKEND-VERIFIED ADMINISTRATOR</span>
          <h2>{user?.fullName}</h2>
          <p>@{user?.username}</p>
          <p>{user?.email}</p>
          <div className="security-callout"><span className="secure-dot" /> Administrator permissions are enforced independently on every protected API request.</div>
          <button className="button button-danger-outline" onClick={() => void signOut()}>Sign out of this browser session</button>
        </div>
      </section>
      <section className="panel account-credentials-panel">
        <div className="panel-heading">
          <div>
            <p className="eyebrow">ACCOUNT SECURITY</p>
            <h2>Change email or password</h2>
          </div>
        </div>
        <p className="muted">Enter your current password to confirm any change. Leave the new password fields empty if you only want to change your email.</p>
        {error && <Alert>{error}</Alert>}
        {notice && <Alert kind="success">{notice}</Alert>}
        <form className="account-credentials-form" onSubmit={(event) => void submit(event)}>
          <label className="field">
            <span>Administrator email</span>
            <input autoComplete="email" type="email" required maxLength={254} value={email} onChange={(event) => setEmail(event.target.value)} />
          </label>
          <label className="field">
            <span>Current password</span>
            <input autoComplete="current-password" type="password" required value={currentPassword} onChange={(event) => setCurrentPassword(event.target.value)} />
          </label>
          <label className="field">
            <span>New password (at least 12 characters)</span>
            <input autoComplete="new-password" type="password" minLength={12} maxLength={128} value={newPassword} onChange={(event) => setNewPassword(event.target.value)} />
          </label>
          <label className="field">
            <span>Confirm new password</span>
            <input autoComplete="new-password" type="password" minLength={12} maxLength={128} value={confirmPassword} onChange={(event) => setConfirmPassword(event.target.value)} />
          </label>
          <button className="button button-primary" disabled={busy}>
            {busy ? 'Saving changes…' : 'Save account changes'}
          </button>
        </form>
      </section>
      <p className="subtle-note">The access token is held for this browser tab session and is never written to logs or included in page URLs.</p>
    </div>
  );
}
