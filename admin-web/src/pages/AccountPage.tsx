import { useAuth } from '../auth-context';
import { PageHeader } from '../components/ui';

export function AccountPage() {
  const { user, signOut } = useAuth();
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
      <p className="subtle-note">The access token is held for this browser tab session and is never written to logs or included in page URLs.</p>
    </div>
  );
}
