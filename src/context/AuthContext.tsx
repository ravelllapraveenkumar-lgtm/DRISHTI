/**
 * DRISHTI: Role-Based Access Control & Authentication Context
 * SIH 2026 Problem ID: 26095 | MoSJE
 */

import React, { createContext, useContext, useState, useEffect } from 'react';
import { api } from '../api/client';
import { UserProfile, UserRole, DemoUser } from '../types/api';

interface AuthContextType {
  user: UserProfile | null;
  token: string | null;
  activeRole: UserRole;
  demoUsers: DemoUser[];
  isLoading: boolean;
  isBackendConnected: boolean;
  login: (email: string, pass: string) => Promise<void>;
  demoLogin: (role: UserRole) => Promise<void>;
  logout: () => void;
  // RBAC Permission Checks
  canMandateInspection: boolean;
  canReviewReports: boolean;
  canAcknowledgeAlerts: boolean;
  canSubmitChecklist: boolean;
  canSubmitEvidence: boolean;
  isInspector: boolean;
  isInstitutionHead: boolean;
}

const DEFAULT_DEMO_USERS: DemoUser[] = [
  {
    id: 'b0000001-0000-0000-0000-000000000001',
    email: 'admin@mosje.gov.in',
    full_name: 'Dr. Rajeshwar Sharma',
    designation: 'Joint Secretary',
    department: 'Department of Social Justice',
    state: 'Delhi',
    district: 'Central Delhi',
    roles: ['SUPER_ADMIN']
  },
  {
    id: 'b0000001-0000-0000-0000-000000000002',
    email: 'official.delhi@mosje.gov.in',
    full_name: 'Sunita Verma, IAS',
    designation: 'Director (Monitoring)',
    department: 'MoSJE National Cell',
    state: 'Delhi',
    district: 'New Delhi',
    roles: ['MINISTRY_OFFICIAL']
  },
  {
    id: 'b0000001-0000-0000-0000-000000000003',
    email: 'dswo.lucknow@up.gov.in',
    full_name: 'Anurag Tripathi, PCS',
    designation: 'District Social Welfare Officer',
    department: 'DSWO Lucknow',
    state: 'Uttar Pradesh',
    district: 'Lucknow',
    roles: ['DISTRICT_OFFICER']
  },
  {
    id: 'b0000001-0000-0000-0000-000000000004',
    email: 'inspector.sharma@mosje.gov.in',
    full_name: 'Vikramaditya Sharma',
    designation: 'Senior Empaneled Inspector',
    department: 'Field Inspection Cadre',
    state: 'Uttar Pradesh',
    district: 'Lucknow',
    roles: ['FIELD_INSPECTOR']
  },
  {
    id: 'b0000001-0000-0000-0000-000000000005',
    email: 'ngo.prerna@drishti.org',
    full_name: 'Meenakshi Sundaram',
    designation: 'Director & Secretary',
    department: 'Prerna Rehabilitation Society',
    state: 'Uttar Pradesh',
    district: 'Lucknow',
    roles: ['INSTITUTION_ADMIN']
  }
];

const AuthContext = createContext<AuthContextType | undefined>(undefined);

export const AuthProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const [user, setUser] = useState<UserProfile | null>(null);
  const [token, setTokenState] = useState<string | null>(api.getToken());
  const [activeRole, setActiveRole] = useState<UserRole>('SUPER_ADMIN');
  const [demoUsers, setDemoUsers] = useState<DemoUser[]>(DEFAULT_DEMO_USERS);
  const [isLoading, setIsLoading] = useState<boolean>(true);
  const [isBackendConnected, setIsBackendConnected] = useState<boolean>(true);

  // Initialize auth state
  useEffect(() => {
    async function initAuth() {
      setIsLoading(true);
      try {
        // Fetch live demo users from backend if possible
        try {
          const res = await api.getDemoUsers();
          if (res.data && res.data.length > 0) {
            setDemoUsers(res.data);
          }
        } catch {
          // fallback to DEFAULT_DEMO_USERS
        }

        // If existing token, try getMe()
        if (api.getToken()) {
          try {
            const meRes = await api.getMe();
            setUser(meRes.data);
            if (meRes.data.roles && meRes.data.roles.length > 0) {
              setActiveRole(meRes.data.roles[0] as UserRole);
            }
            setIsBackendConnected(meRes.isLive);
            setIsLoading(false);
            return;
          } catch {
            api.setToken(null);
            setTokenState(null);
          }
        }

        // Default initial session: log in as SUPER_ADMIN for seamless first-load inspection
        await performDemoLogin('SUPER_ADMIN');
      } catch (err) {
        console.warn('[DRISHTI Auth] Initialization fallback used:', err);
        // Set local fallback user
        setUser({
          id: 'b0000001-0000-0000-0000-000000000001',
          email: 'admin@mosje.gov.in',
          full_name: 'Dr. Rajeshwar Sharma',
          designation: 'Joint Secretary',
          department: 'Department of Social Justice',
          state: 'Delhi',
          district: 'Central Delhi',
          is_active: true,
          is_demo: true,
          roles: ['SUPER_ADMIN'],
          created_at: new Date().toISOString()
        });
        setActiveRole('SUPER_ADMIN');
        setIsBackendConnected(false);
      } finally {
        setIsLoading(false);
      }
    }

    initAuth();
  }, []);

  const performDemoLogin = async (role: UserRole) => {
    setIsLoading(true);
    try {
      const res = await api.demoLogin(role);
      api.setToken(res.data.access_token);
      setTokenState(res.data.access_token);
      setActiveRole(role);

      // Fetch user profile
      try {
        const meRes = await api.getMe();
        setUser(meRes.data);
        setIsBackendConnected(meRes.isLive);
      } catch {
        // Build user profile from token response or demo users
        const demoMatch = demoUsers.find(u => u.roles.includes(role));
        setUser({
          id: res.data.user_id,
          email: res.data.email,
          full_name: res.data.full_name,
          designation: demoMatch?.designation || 'Government Official',
          department: demoMatch?.department || 'MoSJE',
          state: demoMatch?.state || 'National',
          district: demoMatch?.district || 'Central',
          is_active: true,
          is_demo: true,
          roles: res.data.roles,
          created_at: new Date().toISOString()
        });
        setIsBackendConnected(res.isLive);
      }
    } catch (err) {
      console.warn('[DRISHTI Auth] Demo login via API failed, activating offline role mode:', err);
      const demoMatch = demoUsers.find(u => u.roles.includes(role)) || demoUsers[0];
      setUser({
        id: demoMatch.id,
        email: demoMatch.email,
        full_name: demoMatch.full_name,
        designation: demoMatch.designation,
        department: demoMatch.department,
        state: demoMatch.state,
        district: demoMatch.district,
        is_active: true,
        is_demo: true,
        roles: demoMatch.roles,
        created_at: new Date().toISOString()
      });
      setActiveRole(role);
      setIsBackendConnected(false);
    } finally {
      setIsLoading(false);
    }
  };

  const login = async (email: string, pass: string) => {
    setIsLoading(true);
    try {
      const res = await api.login(email, pass);
      api.setToken(res.data.access_token);
      setTokenState(res.data.access_token);
      const meRes = await api.getMe();
      setUser(meRes.data);
      if (meRes.data.roles && meRes.data.roles.length > 0) {
        setActiveRole(meRes.data.roles[0] as UserRole);
      }
      setIsBackendConnected(meRes.isLive);
    } finally {
      setIsLoading(false);
    }
  };

  const logout = () => {
    api.setToken(null);
    setTokenState(null);
    setUser(null);
  };

  // RBAC computed properties
  const canMandateInspection = ['SUPER_ADMIN', 'MINISTRY_OFFICIAL', 'DISTRICT_OFFICER'].includes(activeRole);
  const canReviewReports = ['SUPER_ADMIN', 'MINISTRY_OFFICIAL', 'DISTRICT_OFFICER'].includes(activeRole);
  const canAcknowledgeAlerts = ['SUPER_ADMIN', 'MINISTRY_OFFICIAL', 'DISTRICT_OFFICER'].includes(activeRole);
  const canSubmitChecklist = ['FIELD_INSPECTOR', 'SUPER_ADMIN'].includes(activeRole);
  const canSubmitEvidence = ['FIELD_INSPECTOR', 'SUPER_ADMIN'].includes(activeRole);
  const isInspector = activeRole === 'FIELD_INSPECTOR';
  const isInstitutionHead = activeRole === 'INSTITUTION_ADMIN';

  return (
    <AuthContext.Provider
      value={{
        user,
        token,
        activeRole,
        demoUsers,
        isLoading,
        isBackendConnected,
        login,
        demoLogin: performDemoLogin,
        logout,
        canMandateInspection,
        canReviewReports,
        canAcknowledgeAlerts,
        canSubmitChecklist,
        canSubmitEvidence,
        isInspector,
        isInstitutionHead
      }}
    >
      {children}
    </AuthContext.Provider>
  );
};

export const useAuth = () => {
  const context = useContext(AuthContext);
  if (!context) {
    throw new Error('useAuth must be used within an AuthProvider');
  }
  return context;
};
