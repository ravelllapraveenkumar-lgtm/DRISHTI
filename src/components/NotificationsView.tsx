/**
 * DRISHTI: Official Notification Center
 * System alerts, inspection dispatches, report approvals, and statutory notices
 */

import React, { useState, useEffect } from 'react';
import {
  Bell,
  CheckCircle2,
  AlertTriangle,
  ClipboardCheck,
  FileText,
  Clock,
  CheckCheck
} from 'lucide-react';
import { api } from '../api/client';
import { Notification } from '../types/api';

interface NotificationsViewProps {
  onNavigateToTab: (tab: string) => void;
}

export const NotificationsView: React.FC<NotificationsViewProps> = ({ onNavigateToTab }) => {
  const [notifications, setNotifications] = useState<Notification[]>([]);
  const [isLoading, setIsLoading] = useState(true);

  const fetchNotifications = async () => {
    setIsLoading(true);
    try {
      const res = await api.getNotifications();
      const items = Array.isArray(res.data) ? res.data : (res.data as any)?.items || [];
      setNotifications(items);
    } catch (err) {
      console.warn('Failed to load notifications:', err);
    } finally {
      setIsLoading(false);
    }
  };

  useEffect(() => {
    fetchNotifications();
  }, []);

  const handleMarkAsRead = async (id: string) => {
    try {
      await api.markNotificationRead(id);
      setNotifications(prev =>
        (Array.isArray(prev) ? prev : []).map(n => (n.id === id ? { ...n, is_read: true } : n))
      );
    } catch (err) {
      console.warn('Failed to mark read:', err);
    }
  };

  const handleMarkAllRead = async () => {
    const list = Array.isArray(notifications) ? notifications : [];
    for (const n of list.filter(n => !n.is_read)) {
      try {
        await api.markNotificationRead(n.id);
      } catch {
        // continue
      }
    }
    setNotifications(prev => (Array.isArray(prev) ? prev : []).map(n => ({ ...n, is_read: true })));
  };

  const notifList = Array.isArray(notifications) ? notifications : [];

  return (
    <div className="space-y-5 animate-in fade-in duration-150">
      <div className="bg-white p-5 rounded-xl border border-slate-200 shadow-xs flex flex-col sm:flex-row justify-between items-start sm:items-center gap-3">
        <div>
          <h2 className="text-lg font-bold text-slate-900 tracking-tight">Notification Center</h2>
          <p className="text-xs text-slate-500">
            Real-time administrative alerts, dispatch orders, and field inspection submissions
          </p>
        </div>

        {notifList.some(n => !n.is_read) && (
          <button
            onClick={handleMarkAllRead}
            className="text-xs font-semibold text-indigo-700 hover:text-indigo-900 bg-indigo-50 hover:bg-indigo-100 px-3 py-1.5 rounded-lg border border-indigo-200 transition-colors flex items-center gap-1.5"
          >
            <CheckCheck className="w-3.5 h-3.5" />
            <span>Mark All as Read</span>
          </button>
        )}
      </div>

      <div className="bg-white rounded-xl border border-slate-200 divide-y divide-slate-100 shadow-xs overflow-hidden">
        {notifList.length === 0 ? (
          <div className="text-center py-12 text-slate-400 text-xs">
            {isLoading ? 'Loading notifications...' : 'No notifications found.'}
          </div>
        ) : (
          notifList.map(n => (
            <div
              key={n.id}
              className={`p-4 flex items-start justify-between gap-4 transition-colors ${
                !n.is_read ? 'bg-indigo-50/40' : 'hover:bg-slate-50'
              }`}
            >
              <div className="flex items-start gap-3">
                <div
                  className={`w-8 h-8 rounded-lg flex items-center justify-center shrink-0 mt-0.5 ${
                    n.notification_type === 'ALERT'
                      ? 'bg-red-100 text-red-700'
                      : n.notification_type === 'ASSIGNMENT'
                      ? 'bg-blue-100 text-blue-700'
                      : 'bg-emerald-100 text-emerald-700'
                  }`}
                >
                  {n.notification_type === 'ALERT' ? (
                    <AlertTriangle className="w-4 h-4" />
                  ) : n.notification_type === 'ASSIGNMENT' ? (
                    <ClipboardCheck className="w-4 h-4" />
                  ) : (
                    <FileText className="w-4 h-4" />
                  )}
                </div>

                <div className="space-y-1">
                  <div className="flex items-center gap-2">
                    <h4 className="font-bold text-xs text-slate-900">{n.title}</h4>
                    {!n.is_read && (
                      <span className="w-2 h-2 rounded-full bg-indigo-600 shrink-0" />
                    )}
                  </div>
                  <p className="text-xs text-slate-600 leading-relaxed max-w-2xl">{n.message}</p>
                  <div className="text-[10px] text-slate-400 flex items-center gap-1 font-mono">
                    <Clock className="w-3 h-3" />
                    <span>{new Date(n.created_at).toLocaleString()}</span>
                  </div>
                </div>
              </div>

              {!n.is_read && (
                <button
                  onClick={() => handleMarkAsRead(n.id)}
                  className="text-xs text-indigo-600 hover:text-indigo-800 font-medium px-2 py-1 rounded hover:bg-white"
                >
                  Mark Read
                </button>
              )}
            </div>
          ))
        )}
      </div>
    </div>
  );
};
