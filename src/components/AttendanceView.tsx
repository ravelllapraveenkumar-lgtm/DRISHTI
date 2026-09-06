/**
 * DRISHTI: Attendance Analytics & Verification View
 * Beneficiary roster validation, biometric verification logs & divergence analysis
 */

import React, { useState, useEffect } from 'react';
import {
  Users,
  Calendar,
  CheckCircle2,
  XCircle,
  Clock,
  Fingerprint,
  Smartphone,
  Search,
  Filter,
  AlertTriangle,
  TrendingDown
} from 'lucide-react';
import { api } from '../api/client';
import { AttendanceRecord, AttendanceSummary, Institution } from '../types/api';

interface AttendanceViewProps {
  institutions: Institution[];
}

export const AttendanceView: React.FC<AttendanceViewProps> = ({ institutions }) => {
  const [records, setRecords] = useState<AttendanceRecord[]>([]);
  const [selectedInstId, setSelectedInstId] = useState<string>('ALL');
  const [selectedDate, setSelectedDate] = useState<string>(new Date().toISOString().split('T')[0]);
  const [summary, setSummary] = useState<AttendanceSummary | null>(null);
  const [isLoading, setIsLoading] = useState<boolean>(true);

  useEffect(() => {
    async function fetchAttendance() {
      setIsLoading(true);
      try {
        const params: any = {};
        if (selectedInstId !== 'ALL') params.institution_id = selectedInstId;
        const res = await api.getAttendanceRecords(params);
        const items = Array.isArray(res.data) ? res.data : (res.data as any)?.items || [];
        setRecords(items);

        const instList = Array.isArray(institutions) ? institutions : (institutions as any)?.items || [];
        if (selectedInstId !== 'ALL') {
          const sumRes = await api.getAttendanceSummary(selectedInstId);
          setSummary(sumRes.data);
        } else if (instList.length > 0) {
          const sumRes = await api.getAttendanceSummary(instList[0].id);
          setSummary(sumRes.data);
        }
      } catch (err) {
        console.warn('Failed to fetch attendance data:', err);
      } finally {
        setIsLoading(false);
      }
    }
    fetchAttendance();
  }, [selectedInstId]);

  return (
    <div className="space-y-5 animate-in fade-in duration-150">
      {/* Top Header */}
      <div className="bg-white p-5 rounded-xl border border-slate-200 shadow-xs flex flex-col sm:flex-row justify-between items-start sm:items-center gap-3">
        <div>
          <h2 className="text-lg font-bold text-slate-900 tracking-tight">
            Attendance Verification & Roster Analytics
          </h2>
          <p className="text-xs text-slate-500">
            Aadhaar-linked biometric punch records vs smart portal declarations for MoSJE scheme beneficiaries
          </p>
        </div>

        {/* Institution Filter */}
        <div className="w-full sm:w-auto flex items-center gap-2">
          <select
            value={selectedInstId}
            onChange={e => setSelectedInstId(e.target.value)}
            className="text-xs bg-slate-50 border border-slate-300 rounded-lg px-3 py-2 text-slate-900 focus:bg-white focus:outline-hidden focus:ring-2 focus:ring-indigo-500 font-medium"
          >
            <option value="ALL">All Institutions ({institutions.length})</option>
            {institutions.map(inst => (
              <option key={inst.id} value={inst.id}>
                {inst.name}
              </option>
            ))}
          </select>
        </div>
      </div>

      {/* KPI Cards for Selected Institution / Overview */}
      {summary && (
        <div className="grid grid-cols-2 sm:grid-cols-4 gap-3">
          <div className="bg-white p-4 rounded-xl border border-slate-200 shadow-xs">
            <span className="text-xs text-slate-500 font-medium">Sanctioned Roster</span>
            <div className="text-xl font-bold text-slate-900 mt-1">{summary.total_roster_count}</div>
            <span className="text-[11px] text-slate-400">Enrolled beneficiaries</span>
          </div>

          <div className="bg-white p-4 rounded-xl border border-slate-200 shadow-xs">
            <span className="text-xs text-slate-500 font-medium">Verified Present</span>
            <div className="text-xl font-bold text-emerald-600 mt-1">{summary.present_count}</div>
            <span className="text-[11px] text-emerald-700">Biometrically validated</span>
          </div>

          <div className="bg-white p-4 rounded-xl border border-slate-200 shadow-xs">
            <span className="text-xs text-slate-500 font-medium">Absent / On Leave</span>
            <div className="text-xl font-bold text-amber-600 mt-1">
              {summary.absent_count + summary.on_leave_count}
            </div>
            <span className="text-[11px] text-slate-400">Roster variance</span>
          </div>

          <div className="bg-white p-4 rounded-xl border border-slate-200 shadow-xs">
            <span className="text-xs text-slate-500 font-medium">Attendance Rate</span>
            <div className="text-xl font-bold text-indigo-600 mt-1">
              {summary.attendance_percentage}%
            </div>
            <span className="text-[11px] text-indigo-700 font-medium">
              {summary.attendance_percentage >= 85 ? 'Meets scheme mandate' : 'Below recommended 85%'}
            </span>
          </div>
        </div>
      )}

      {/* Attendance Roster Table */}
      <div className="bg-white rounded-xl border border-slate-200 overflow-hidden shadow-xs">
        <div className="p-4 border-b border-slate-200 flex items-center justify-between">
          <span className="text-xs font-bold text-slate-800">
            Attendance Punch Log ({records.length} records)
          </span>
          <span className="text-[11px] text-slate-500">
            Modes: Biometric Device / Geofenced Smart Portal
          </span>
        </div>

        <div className="overflow-x-auto">
          <table className="w-full text-left text-xs text-slate-700">
            <thead className="bg-slate-50 text-slate-500 font-semibold border-b border-slate-200">
              <tr>
                <th className="px-5 py-3">Date</th>
                <th className="px-5 py-3">Beneficiary ID & Name</th>
                <th className="px-5 py-3">Status</th>
                <th className="px-5 py-3">Verification Mode</th>
                <th className="px-5 py-3">Source Integrity</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-100">
              {records.length === 0 ? (
                <tr>
                  <td colSpan={5} className="text-center py-10 text-slate-400 text-xs">
                    {isLoading ? 'Loading attendance logs...' : 'No attendance entries logged for this selection.'}
                  </td>
                </tr>
              ) : (
                records.map(record => (
                  <tr key={record.id} className="hover:bg-slate-50/80 transition-colors">
                    <td className="px-5 py-3.5 font-mono text-slate-900">{record.attendance_date}</td>
                    <td className="px-5 py-3.5">
                      <div className="font-bold text-slate-900">
                        {record.beneficiary_name || `Beneficiary #${record.beneficiary_id.slice(0, 8)}`}
                      </div>
                      <div className="text-[11px] text-slate-400 font-mono">{record.beneficiary_id}</div>
                    </td>
                    <td className="px-5 py-3.5">
                      <span
                        className={`inline-flex items-center gap-1 text-[11px] font-semibold px-2 py-0.5 rounded border ${
                          record.status === 'PRESENT'
                            ? 'bg-emerald-50 text-emerald-700 border-emerald-200'
                            : record.status === 'ABSENT'
                            ? 'bg-red-50 text-red-700 border-red-200'
                            : 'bg-amber-50 text-amber-700 border-amber-200'
                        }`}
                      >
                        {record.status === 'PRESENT' ? (
                          <CheckCircle2 className="w-3 h-3 text-emerald-600" />
                        ) : record.status === 'ABSENT' ? (
                          <XCircle className="w-3 h-3 text-red-600" />
                        ) : (
                          <Clock className="w-3 h-3 text-amber-600" />
                        )}
                        <span>{record.status}</span>
                      </span>
                    </td>
                    <td className="px-5 py-3.5">
                      <div className="flex items-center gap-1.5 text-slate-800">
                        {record.verification_mode.includes('BIOMETRIC') ? (
                          <Fingerprint className="w-4 h-4 text-indigo-600" />
                        ) : (
                          <Smartphone className="w-4 h-4 text-slate-500" />
                        )}
                        <span className="font-medium">{record.verification_mode.replace(/_/g, ' ')}</span>
                      </div>
                    </td>
                    <td className="px-5 py-3.5">
                      <span className="text-[10px] text-slate-500 bg-slate-100 px-2 py-0.5 rounded font-mono">
                        {record.is_synthetic ? 'DEMO RECORD' : 'LIVE TELEMETRY'}
                      </span>
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
