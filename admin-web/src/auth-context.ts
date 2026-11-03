import { createContext, useContext } from 'react';
import type { AdminCredentialUpdate, AdminSetupInput, AdminUser } from './types';

export interface AuthContextValue {
  user: AdminUser | null;
  loading: boolean;
  error: string | null;
  setupAvailable: boolean;
  setupError: string | null;
  signIn(email: string, password: string): Promise<void>;
  createAdminAccount(input: AdminSetupInput): Promise<void>;
  updateAdminCredentials(input: AdminCredentialUpdate): Promise<void>;
  signOut(): Promise<void>;
}

export const AuthContext = createContext<AuthContextValue | null>(null);

export function useAuth() {
  const context = useContext(AuthContext);
  if (!context) throw new Error('useAuth must be used within AuthProvider.');
  return context;
}
