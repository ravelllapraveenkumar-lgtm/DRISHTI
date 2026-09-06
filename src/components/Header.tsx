/**
 * DRISHTI: Government Central Dashboard Header
 * MoSJE Official Branding, Live Backend Status, Role Switcher, Notifications Popover
 */

import React, { useState, useEffect } from 'react';
import {
  Eye,
  Shield,
  Bell,
  CheckCircle2,
  AlertTriangle,
  ChevronDown,
  User,
  LogOut,
  ExternalLink,
  Wifi,
  WifiOff,
  Check
} from 'lucide-react';
import { useAuth } from '../context/AuthContext';
import { UserRole, Notification } from '../types/api';
import { api } from '../api/client';

interface HeaderProps {
  onOpenNotifications: () => void;
  onNavigateTab: (tabId: string) => void;
}

export const Header: React.FC<HeaderProps> = ({ onOpenNotifications, onNavigateTab }) => {
  const { user, activeRole, demoUsers, demoLogin, logout, isBackendConnected } = useAuth();
  const [roleDropdownOpen, setRoleDropdownOpen] = useState(false);
  const [notificationsOpen, setNotificationsOpen] = useState(false);
  const [notifications, setNotifications] = useState<Notification[]>([]);
  const [unreadCount, setUnreadCount] = useState(0);

  useEffect(() => {
    async function loadNotifications() {
      try {
        const res = await api.getNotifications();
        const items = Array.isArray(res.data) ? res.data : (res.data as any)?.items || [];
        setNotifications(items);
        setUnreadCount(items.filter(n => !n.is_read).length);
      } catch {
        // use fallback empty
      }
    }
    loadNotifications();
    const interval = setInterval(loadNotifications, 15000);
    return () => clearInterval(interval);
  }, [user]);

  const handleRoleSelect = async (role: UserRole) => {
    setRoleDropdownOpen(false);
    await demoLogin(role);
  };

  const getRoleBadgeColor = (role: UserRole) => {
    switch (role) {
      case 'SUPER_ADMIN':
        return 'bg-purple-100 text-purple-800 border-purple-200';
      case 'MINISTRY_OFFICIAL':
        return 'bg-blue-100 text-blue-800 border-blue-200';
      case 'DISTRICT_OFFICER':
        return 'bg-emerald-100 text-emerald-800 border-emerald-200';
      case 'FIELD_INSPECTOR':
        return 'bg-amber-100 text-amber-800 border-amber-200';
      case 'INSTITUTION_ADMIN':
        return 'bg-slate-100 text-slate-800 border-slate-200';
      default:
        return 'bg-slate-100 text-slate-800 border-slate-200';
    }
  };

  const formatRoleName = (role: string) => {
    return role.replace(/_/g, ' ');
  };

  return (
    <header className="bg-white border-b border-slate-200 sticky top-0 z-30 shadow-xs">
      {/* Top Government Strip */}
      <div className="bg-[#0F172A] text-slate-300 text-xs px-4 sm:px-8 py-1.5 flex justify-between items-center border-b border-slate-800">
        <div className="flex items-center gap-2">
          <span className="inline-block w-2 h-2 rounded-full bg-amber-400"></span>
          <span className="font-medium text-slate-200">
            Ministry of Social Justice & Empowerment (MoSJE) | Government of India
          </span>
          <span className="hidden md:inline text-slate-500">•</span>
          <span className="hidden md:inline text-slate-400">SIH 2026 Problem ID: 26095</span>
        </div>
        <div className="flex items-center gap-3">
          {/* Live Backend Indicator */}
          <div
            className={`flex items-center gap-1.5 px-2.5 py-0.5 rounded-full text-[11px] font-medium border ${
              isBackendConnected
                ? 'bg-emerald-950/80 text-emerald-300 border-emerald-700/60'
                : 'bg-amber-950/80 text-amber-300 border-amber-700/60'
            }`}
            title={
              isBackendConnected
                ? 'Connected to FastAPI backend with 48 registered endpoints and SQLite/Postgres DB'
                : 'Backend offline: Using synthetic fallback data'
            }
          >
            {isBackendConnected ? (
              <>
                <span className="w-1.5 h-1.5 rounded-full bg-emerald-400 animate-pulse"></span>
                <span>Live Backend Connected (/api/v1)</span>
              </>
            ) : (
              <>
                <span className="w-1.5 h-1.5 rounded-full bg-amber-400"></span>
                <span>Demo / Synthetic Fallback</span>
              </>
            )}
          </div>
          <span className="text-[11px] text-slate-400 hidden sm:inline">Official Prototype</span>
        </div>
      </div>

      {/* Main Header Bar */}
      <div className="px-4 sm:px-8 py-3 flex items-center justify-between">
        {/* Brand & Emblem */}
        <div className="flex items-center gap-3">
          <div className="w-10 h-10 rounded-xl bg-gradient-to-br from-indigo-700 to-slate-900 flex items-center justify-center text-white shadow-md shadow-indigo-900/10 border border-indigo-500/20">
            <Eye className="w-5 h-5 text-indigo-300" />
          </div>
          <div>
            <div className="flex items-center gap-2">
              <h1 className="text-xl font-bold tracking-tight text-slate-900">DRISHTI</h1>
              <span className="text-[10px] font-semibold uppercase tracking-wider bg-indigo-50 text-indigo-700 px-2 py-0.5 rounded-md border border-indigo-200">
                Central Portal
              </span>
            </div>
            <p className="text-xs text-slate-500 hidden sm:block">
              Smart Real-Time Monitoring & Inspection Decision-Support System
            </p>
          </div>
        </div>

        {/* Action Controls & User Switcher */}
        <div className="flex items-center gap-3 sm:gap-4">
          {/* Notifications Button */}
          <div className="relative">
            <button
              onClick={() => setNotificationsOpen(!notificationsOpen)}
              className="relative p-2 rounded-lg text-slate-600 hover:text-slate-900 hover:bg-slate-100 transition-colors border border-slate-200"
              aria-label="Notifications"
            >
              <Bell className="w-4 h-4" />
              {unreadCount > 0 && (
                <span className="absolute -top-1 -right-1 bg-red-600 text-white text-[10px] font-bold w-4 h-4 rounded-full flex items-center justify-center ring-2 ring-white">
                  {unreadCount}
                </span>
              )}
            </button>

            {/* Notifications Dropdown */}
            {notificationsOpen && (
              <div className="absolute right-0 mt-2 w-80 sm:w-96 bg-white rounded-xl shadow-xl border border-slate-200 p-3 z-50 animate-in fade-in slide-in-from-top-2">
                <div className="flex items-center justify-between pb-2 border-b border-slate-100 mb-2">
                  <div className="flex items-center gap-2">
                    <span className="font-semibold text-sm text-slate-800">Notifications</span>
                    <span className="text-xs bg-indigo-50 text-indigo-700 px-1.5 py-0.5 rounded font-mono">
                      {unreadCount} unread
                    </span>
                  </div>
                  <button
                    onClick={() => {
                      setNotificationsOpen(false);
                      onOpenNotifications();
                    }}
                    className="text-xs text-indigo-600 hover:text-indigo-800 font-medium"
                  >
                    View All
                  </button>
                </div>

                <div className="space-y-2 max-h-72 overflow-y-auto">
                  {notifications.length === 0 ? (
                    <div className="text-center py-6 text-slate-400 text-xs">
                      No notifications at this time
                    </div>
                  ) : (
                    notifications.slice(0, 5).map(n => (
                      <div
                        key={n.id}
                        className={`p-2.5 rounded-lg text-xs transition-colors ${
                          n.is_read ? 'bg-slate-50 text-slate-600' : 'bg-indigo-50/70 border border-indigo-100 text-slate-900'
                        }`}
                      >
                        <div className="flex items-center justify-between font-semibold mb-1">
                          <span className="text-slate-900">{n.title}</span>
                          <span className="text-[10px] text-slate-400">
                            {new Date(n.created_at).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}
                          </span>
                        </div>
                        <p className="text-slate-600 line-clamp-2">{n.message}</p>
                      </div>
                    ))
                  )}
                </div>
              </div>
            )}
          </div>

          {/* Quick RBAC Role Switcher */}
          <div className="relative">
            <button
              onClick={() => setRoleDropdownOpen(!roleDropdownOpen)}
              className="flex items-center gap-2 px-3 py-1.5 rounded-lg border border-slate-200 hover:border-slate-300 bg-slate-50 hover:bg-white transition-all text-left"
            >
              <div className="w-7 h-7 rounded-full bg-slate-800 text-white flex items-center justify-center font-bold text-xs">
                {user?.full_name?.charAt(0) || 'U'}
              </div>
              <div className="hidden md:block">
                <div className="text-xs font-semibold text-slate-900 leading-tight">
                  {user?.full_name || 'Authorized Official'}
                </div>
                <div className="flex items-center gap-1.5">
                  <span
                    className={`text-[10px] font-semibold px-1.5 py-0.2 rounded border ${getRoleBadgeColor(
                      activeRole
                    )}`}
                  >
                    {formatRoleName(activeRole)}
                  </span>
                </div>
              </div>
              <ChevronDown className="w-3.5 h-3.5 text-slate-400" />
            </button>

            {/* Role Switcher Popover */}
            {roleDropdownOpen && (
              <div className="absolute right-0 mt-2 w-72 bg-white rounded-xl shadow-xl border border-slate-200 p-2 z-50">
                <div className="p-2 border-b border-slate-100 mb-1">
                  <div className="text-xs font-bold text-slate-800">Switch Official Role (RBAC)</div>
                  <div className="text-[11px] text-slate-500">
                    Test the system under any of the 5 authorized government roles
                  </div>
                </div>

                <div className="space-y-1">
                  {demoUsers.map(du => {
                    const primaryRole = (du.roles[0] || 'SUPER_ADMIN') as UserRole;
                    const isCurrent = activeRole === primaryRole;
                    return (
                      <button
                        key={du.id}
                        onClick={() => handleRoleSelect(primaryRole)}
                        className={`w-full text-left p-2 rounded-lg text-xs flex items-center justify-between transition-colors ${
                          isCurrent
                            ? 'bg-indigo-50 text-indigo-900 font-semibold border border-indigo-100'
                            : 'hover:bg-slate-50 text-slate-700'
                        }`}
                      >
                        <div>
                          <div className="font-semibold text-slate-900">{du.full_name}</div>
                          <div className="text-[11px] text-slate-500">
                            {du.designation} • {du.district || du.state}
                          </div>
                          <span
                            className={`inline-block mt-0.5 text-[9px] font-medium px-1.5 py-0.2 rounded border ${getRoleBadgeColor(
                              primaryRole
                            )}`}
                          >
                            {formatRoleName(primaryRole)}
                          </span>
                        </div>
                        {isCurrent && <Check className="w-4 h-4 text-indigo-600 shrink-0" />}
                      </button>
                    );
                  })}
                </div>

                <div className="mt-2 pt-2 border-t border-slate-100 flex justify-between items-center px-1">
                  <span className="text-[10px] text-slate-400">DRISHTI RBAC Engine</span>
                  <button
                    onClick={() => {
                      logout();
                      setRoleDropdownOpen(false);
                    }}
                    className="text-xs text-red-600 hover:text-red-700 font-medium flex items-center gap-1"
                  >
                    <LogOut className="w-3 h-3" />
                    Reset Session
                  </button>
                </div>
              </div>
            )}
          </div>
        </div>
      </div>
    </header>
  );
};
