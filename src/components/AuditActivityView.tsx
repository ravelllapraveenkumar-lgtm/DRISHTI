/**
 * DRISHTI: System Audit Trail & Immutable Governance Log
 * Forensic ledger tracking all user authentications, inspection dispatches, and administrative decisions
 */

import React, { useState, useEffect } from 'react';
import {
  History,
  Shield,
  Search,
  Filter,
  User,
  Clock,
  Laptop,
  CheckCircle2,
  FileCode
} from 'lucide-react';
import { api } from '../api/client';
import { AuditLogEntry } from '../types/api';

export const AuditActivityView: React.FC = () => {
  const [logs, setLogs] = useState<AuditLogEntry[]>([]);
  const [searchQuery, setSearchQuery] = useState('');
  const [isLoading, setIsLoading] = useState(true);

  const fetchLogs = async () => {
    setIsLoading(true);
    try {
      const res = await api.getAuditLogs();
      const items = Array.isArray(res.data) ? res.data : (res.data as any)?.items || [];
      setLogs(items);
    } catch (err) {
      console.warn('Failed to load audit logs:', err);
    } finally {
      setIsLoading(false);
    }
  };

  useEffect(() => {
    fetchLogs();
  }, []);

  const logList = Array.isArray(logs) ? logs : [];
  const filteredLogs = logList.filter(l => {
    return (
      l.action.toLowerCase().includes(searchQuery.toLowerCase()) ||
      (l.actor_name && l.actor_name.toLowerCase().includes(searchQuery.toLowerCase())) ||
      l.entity_type.toLowerCase().includes(searchQuery.toLowerCase())
    );
  });

  return (
    <div className="space-y-5 animate-in fade-in duration-150">
      <div className="bg-white p-5 rounded-xl border border-slate-200 shadow-xs flex flex-col sm:flex-row justify-between items-start sm:items-center gap-3">
        <div>
          <h2 className="text-lg font-bold text-slate-900 tracking-tight">
            System Audit Trail & Governance Ledger
          </h2>
          <p className="text-xs text-slate-500">
            Immutable log of role authentications, unannounced inspection orders, and administrative reviews
          </p>
        </div>

        <div className="flex items-center gap-2 bg-slate-50 border border-slate-200 px-3 py-1.5 rounded-lg text-xs text-slate-600 font-mono">
          <Shield className="w-4 h-4 text-indigo-600" />
          <span>Section 43A IT Act Compliant</span>
        </div>
      </div>

      {/* Search Filter */}
      <div className="bg-white p-4 rounded-xl border border-slate-200 shadow-xs">
        <div className="relative">
          <Search className="w-4 h-4 text-slate-400 absolute left-3 top-2.5" />
          <input
            type="text"
            placeholder="Search by action, actor, or entity..."
            value={searchQuery}
            onChange={e => setSearchQuery(e.target.value)}
            className="w-full text-xs pl-9 pr-3 py-2 bg-slate-50 border border-slate-300 rounded-lg focus:bg-white focus:outline-hidden focus:ring-2 focus:ring-indigo-500 text-slate-900"
          />
        </div>
      </div>

      {/* Audit Log Table */}
      <div className="bg-white rounded-xl border border-slate-200 overflow-hidden shadow-xs">
        <div className="p-4 border-b border-slate-200 flex items-center justify-between">
          <span className="text-xs font-bold text-slate-800">
            Audit Activity Events ({filteredLogs.length})
          </span>
          <span className="text-[11px] text-slate-500">
            Server-side timestamped • Tamper-resistant
          </span>
        </div>

        <div className="overflow-x-auto">
          <table className="w-full text-left text-xs text-slate-700">
            <thead className="bg-slate-50 text-slate-500 font-semibold border-b border-slate-200">
              <tr>
                <th className="px-5 py-3">Timestamp (UTC)</th>
                <th className="px-5 py-3">Authorized Actor</th>
                <th className="px-5 py-3">Action Event</th>
                <th className="px-5 py-3">Entity Affected</th>
                <th className="px-5 py-3">IP Address</th>
                <th className="px-5 py-3">Event Details</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-100">
              {filteredLogs.length === 0 ? (
                <tr>
                  <td colSpan={6} className="text-center py-10 text-slate-400 text-xs">
                    {isLoading ? 'Loading audit trail...' : 'No audit entries found.'}
                  </td>
                </tr>
              ) : (
                filteredLogs.map(log => (
                  <tr key={log.id} className="hover:bg-slate-50/80 transition-colors">
                    <td className="px-5 py-3.5 font-mono text-slate-500 text-[11px] whitespace-nowrap">
                      {new Date(log.created_at).toLocaleString()}
                    </td>
                    <td className="px-5 py-3.5">
                      <div className="font-bold text-slate-900">{log.actor_name || 'System Service'}</div>
                      <div className="text-[10px] text-slate-400 font-mono">
                        {log.actor_role || 'AUTOMATED_CRON'}
                      </div>
                    </td>
                    <td className="px-5 py-3.5">
                      <span className="font-semibold text-slate-900 bg-slate-100 px-2 py-0.5 rounded font-mono text-[11px]">
                        {log.action}
                      </span>
                    </td>
                    <td className="px-5 py-3.5">
                      <div className="font-medium text-slate-800">{log.entity_type}</div>
                      {log.entity_id && (
                        <div className="text-[10px] text-slate-400 font-mono">
                          ID: {log.entity_id.slice(0, 8)}
                        </div>
                      )}
                    </td>
                    <td className="px-5 py-3.5 font-mono text-slate-500 text-[11px]">
                      {log.ip_address || '127.0.0.1'}
                    </td>
                    <td className="px-5 py-3.5 max-w-xs truncate text-[11px] text-slate-600 font-mono">
                      {JSON.stringify(log.details)}
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
};
