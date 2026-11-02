import {
  useCallback,
  useEffect,
  useMemo,
  useState,
  type ReactNode,
} from 'react';
import { api } from './api';
import type { AdminUser } from './types';
import { AuthContext } from './auth-context';

export function AuthProvider({ children }: { children: ReactNode }) {
  const [user, setUser] = useState<AdminUser | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    let active = true;
    const handleUnauthorized = () => {
      if (active) setUser(null);
    };
    window.addEventListener('dailyduel:unauthorized', handleUnauthorized);
    api.restoreAdminSession()
      .then((restored) => {
        if (active) setUser(restored);
      })
      .catch(() => {
        if (active) setError('Could not verify the saved session. Check the backend connection and try again.');
      })
      .finally(() => {
        if (active) setLoading(false);
      });
    return () => {
      active = false;
      window.removeEventListener('dailyduel:unauthorized', handleUnauthorized);
    };
  }, []);

  const signIn = useCallback(async (email: string, password: string) => {
    setError(null);
    const admin = await api.login(email, password);
    setUser(admin);
  }, []);

  const signOut = useCallback(async () => {
    await api.logout();
    setUser(null);
    setError(null);
  }, []);

  const value = useMemo(
    () => ({ user, loading, error, signIn, signOut }),
    [user, loading, error, signIn, signOut],
  );
  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
}
