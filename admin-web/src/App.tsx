import { BrowserRouter, Navigate, Outlet, Route, Routes } from 'react-router-dom';
import { AuthProvider } from './auth';
import { useAuth } from './auth-context';
import { AdminLayout } from './components/AdminLayout';
import { LoginPage } from './pages/LoginPage';
import { DashboardPage } from './pages/DashboardPage';
import { ExamsPage } from './pages/ExamsPage';
import { QuestionsPage } from './pages/QuestionsPage';
import { CategoriesPage } from './pages/CategoriesPage';
import { ResultsPage } from './pages/ResultsPage';
import { AccountPage } from './pages/AccountPage';
import { StudentsPage } from './pages/StudentsPage';
import './App.css';

function RequireAdmin() {
  const { user, loading, error } = useAuth();

  if (loading) {
    return <div className="full-state"><span className="spinner" />Verifying administrator session…</div>;
  }
  if (!user) {
    return error
      ? <div className="full-state"><div className="alert alert-error">{error}</div><a className="button button-primary" href="/login">Return to login</a></div>
      : <Navigate to="/login" replace />;
  }
  return <Outlet />;
}

function LoginRoute() {
  const { user, loading } = useAuth();
  if (loading) return <div className="full-state"><span className="spinner" />Checking session…</div>;
  return user ? <Navigate to="/" replace /> : <LoginPage />;
}

export default function App() {
  return (
    <BrowserRouter>
      <AuthProvider>
        <Routes>
          <Route path="/login" element={<LoginRoute />} />
          <Route element={<RequireAdmin />}>
            <Route element={<AdminLayout />}>
              <Route index element={<DashboardPage />} />
              <Route path="exams" element={<ExamsPage />} />
              <Route path="questions" element={<QuestionsPage />} />
              <Route path="categories" element={<CategoriesPage />} />
              <Route path="results" element={<ResultsPage />} />
              <Route path="students" element={<StudentsPage />} />
              <Route path="account" element={<AccountPage />} />
            </Route>
          </Route>
          <Route path="*" element={<Navigate to="/" replace />} />
        </Routes>
      </AuthProvider>
    </BrowserRouter>
  );
}
