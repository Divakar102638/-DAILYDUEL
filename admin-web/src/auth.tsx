import {
  useCallback,
  useEffect,
  useMemo,
  useState,
  type ReactNode,
} from 'react';
import { api } from './api';
import type { AdminCredentialUpdate, AdminSetupInput, AdminUser } from './types';
import { AuthContext } from './auth-context';

export function AuthProvider({ children }: { children: ReactNode }) {
  const [user, setUser] = useState<AdminUser | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [setupAvailable, setSetupAvailable] = useState(false);
  const [setupError, setSetupError] = useState<string | null>(null);

  useEffect(() => {
    let active = true;
    const handleUnauthorized = () => {
      if (active) setUser(null);
    };
    window.addEventListener('dailyduel:unauthorized', handleUnauthorized);
    const restoreSession = api.restoreAdminSession()
      .then((restored) => {
        if (active) setUser(restored);
      })
      .catch(() => {
        if (active) setError('Could not verify the saved session. Check the backend connection and try again.');
      });
    const checkSetup = api.adminSetupAvailable()
      .then((available) => {
        if (active) setSetupAvailable(available);
      })
      .catch(() => {
        if (active) {
          setSetupAvailable(false);
          setSetupError('Could not check first-time administrator setup. You can still try signing in.');
        }
      });
    Promise.all([restoreSession, checkSetup]).finally(() => {
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

  const createAdminAccount = useCallback(async (input: AdminSetupInput) => {
    await api.createFirstAdmin(input);
    setSetupAvailable(false);
    setSetupError(null);
  }, []);

  const updateAdminCredentials = useCallback(async (input: AdminCredentialUpdate) => {
    const result = await api.updateAdminCredentials(input);
    setUser(result.user);
  }, []);

  const signOut = useCallback(async () => {
    await api.logout();
    setUser(null);
    setError(null);
  }, []);

  const value = useMemo(
    () => ({
      user,
      loading,
      error,
      setupAvailable,
      setupError,
      signIn,
      createAdminAccount,
      updateAdminCredentials,
      signOut,
    }),
    [user, loading, error, setupAvailable, setupError, signIn, createAdminAccount, updateAdminCredentials, signOut],
  );
  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
}
