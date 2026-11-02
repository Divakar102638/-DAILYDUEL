import { useState } from 'react';
import { NavLink, Outlet, useLocation, useNavigate } from 'react-router-dom';
import { useAuth } from '../auth-context';

const navigation = [
  { to: '/', label: 'Overview', short: 'OV' },
  { to: '/exams', label: 'Exam management', short: 'EX' },
  { to: '/questions', label: 'Question bank', short: 'QB' },
  { to: '/categories', label: 'Categories', short: 'CA' },
  { to: '/results', label: 'Results & ranks', short: 'RS' },
  { to: '/students', label: 'Students', short: 'ST' },
];

const titles: Record<string, string> = {
  '/': 'Overview',
  '/exams': 'Exam management',
  '/questions': 'Question bank',
  '/categories': 'Category management',
  '/results': 'Results & leaderboards',
  '/students': 'Students',
  '/account': 'Administrator account',
};

export function AdminLayout() {
  const { user, signOut } = useAuth();
  const location = useLocation();
  const navigate = useNavigate();
  const [menuOpen, setMenuOpen] = useState(false);

  async function logout() {
    await signOut();
    navigate('/login', { replace: true });
  }

  return (
    <div className="admin-shell">
      <aside className={`sidebar ${menuOpen ? 'sidebar-open' : ''}`}>
        <div className="brand">
          <span className="brand-mark">D</span>
          <span><strong>DailyDuel</strong><small>ADMIN CONSOLE</small></span>
        </div>
        <div className="workspace-label">WORKSPACE</div>
        <nav className="side-nav" aria-label="Admin navigation">
          {navigation.map((item) => (
            <NavLink
              key={item.to}
              to={item.to}
              end={item.to === '/'}
              onClick={() => setMenuOpen(false)}
              className={({ isActive }) => `nav-link ${isActive ? 'nav-link-active' : ''}`}
            >
              <span className="nav-short">{item.short}</span>{item.label}
            </NavLink>
          ))}
        </nav>
        <div className="sidebar-bottom">
          <div className="secure-note"><span className="secure-dot" />Backend verified access</div>
          <button className="account-link" onClick={() => navigate('/account')}>
            <span className="avatar">{user?.fullName?.slice(0, 1).toUpperCase() ?? 'A'}</span>
            <span className="account-copy"><strong>{user?.fullName}</strong><small>Administrator</small></span>
            <span aria-hidden="true">›</span>
          </button>
        </div>
      </aside>

      <div className="main-column">
        <header className="topbar">
          <button className="mobile-menu icon-button" aria-label="Open navigation" onClick={() => setMenuOpen(!menuOpen)}>☰</button>
          <div className="breadcrumb"><span>DailyDuel</span><span className="breadcrumb-divider">/</span><strong>{titles[location.pathname] ?? 'Admin'}</strong></div>
          <div className="topbar-actions">
            <span className="topbar-status"><span className="secure-dot" />Admin session verified</span>
            <button className="button button-quiet" onClick={() => void logout()}>Sign out</button>
          </div>
        </header>
        <main className="main-content"><Outlet /></main>
        <footer className="footer-note">DailyDuel Admin · Administrative actions are enforced by the backend.</footer>
      </div>
      {menuOpen && <button className="mobile-scrim" aria-label="Close navigation" onClick={() => setMenuOpen(false)} />}
    </div>
  );
}
