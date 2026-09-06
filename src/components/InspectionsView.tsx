/**
 * DRISHTI: Inspections Register & Official Dispatch View
 * Lifecycle tracking of mandated unannounced and routine inspections
 */

import React, { useState, useEffect } from 'react';
import {
  ClipboardCheck,
  PlusCircle,
  Filter,
  Search,
  AlertTriangle,
  Clock,
  User,
  Building2,
  Calendar,
  CheckCircle2,
  FileText,
  ChevronRight,
  Shield
} from 'lucide-react';
import { api } from '../api/client';
import { Inspection, InspectionStatus, PriorityLevel, Institution } from '../types/api';
import { useAuth } from '../context/AuthContext';

interface InspectionsViewProps {
  onMandateInspection: (instId?: string, alertId?: string, defaultReason?: string) => void;
  onSelectInspection?: (inspection: Inspection) => void;
}

export const InspectionsView: React.FC<InspectionsViewProps> = ({
  onMandateInspection,
  onSelectInspection
}) => {
  const { canMandateInspection, canReviewReports } = useAuth();
  const [inspections, setInspections] = useState<Inspection[]>([]);
  const [statusFilter, setStatusFilter] = useState('ALL');
  const [priorityFilter, setPriorityFilter] = useState('ALL');
  const [searchQuery, setSearchQuery] = useState('');
  const [isLoading, setIsLoading] = useState(true);
  const [updatingId, setUpdatingId] = useState<string | null>(null);

  const fetchInspections = async () => {
    setIsLoading(true);
    try {
      const res = await api.getInspections();
      const items = Array.isArray(res.data) ? res.data : (res.data as any)?.items || [];
      setInspections(items);
    } catch (err) {
      console.warn('Failed to load inspections:', err);
    } finally {
      setIsLoading(false);
    }
  };

  useEffect(() => {
    fetchInspections();
  }, []);

  const handleStatusUpdate = async (id: string, newStatus: InspectionStatus) => {
    setUpdatingId(id);
    try {
      await api.updateInspectionStatus(id, newStatus, `Status transitioned to ${newStatus} by authorized official.`);
      await fetchInspections();
    } catch (err: any) {
      alert(err.message || 'Failed to update inspection status');
    } finally {
      setUpdatingId(null);
    }
  };

  const inspList = Array.isArray(inspections) ? inspections : (inspections as any)?.items || [];
  const filteredInspections = inspList.filter(insp => {
    const matchesStatus = statusFilter === 'ALL' || insp.status === statusFilter;
    const matchesPriority = priorityFilter === 'ALL' || insp.priority === priorityFilter;
    const matchesSearch =
      insp.inspection_code.toLowerCase().includes(searchQuery.toLowerCase()) ||
      (insp.institution_name && insp.institution_name.toLowerCase().includes(searchQuery.toLowerCase())) ||
      insp.inspection_reason.toLowerCase().includes(searchQuery.toLowerCase());

    return matchesStatus && matchesPriority && matchesSearch;
  });

  const getPriorityBadge = (priority: PriorityLevel) => {
    switch (priority) {
      case 'EMERGENCY':
        return 'bg-red-50 text-red-700 border-red-200';
      case 'URGENT':
        return 'bg-amber-50 text-amber-700 border-amber-200';
      case 'ROUTINE':
        return 'bg-blue-50 text-blue-700 border-blue-200';
      default:
        return 'bg-slate-50 text-slate-700 border-slate-200';
    }
  };

  const getStatusBadge = (status: InspectionStatus) => {
    switch (status) {
      case 'APPROVED':
      case 'CLOSED':
        return 'bg-emerald-50 text-emerald-700 border-emerald-200';
      case 'IN_PROGRESS':
      case 'ASSIGNED':
        return 'bg-indigo-50 text-indigo-700 border-indigo-200';
      case 'SUBMITTED':
        return 'bg-purple-50 text-purple-700 border-purple-200';
      case 'PENDING_DISPATCH':
        return 'bg-amber-50 text-amber-700 border-amber-200';
      default:
        return 'bg-slate-50 text-slate-700 border-slate-200';
    }
  };

  return (
    <div className="space-y-5 animate-in fade-in duration-150">
      {/* Top Header */}
      <div className="bg-white p-5 rounded-xl border border-slate-200 shadow-xs flex flex-col sm:flex-row justify-between items-start sm:items-center gap-3">
        <div>
          <h2 className="text-lg font-bold text-slate-900 tracking-tight">
            Inspection Register & Official Dispatch
          </h2>
          <p className="text-xs text-slate-500">
            Mandated unannounced visits, assigned field cadre, and inspection lifecycle audit records
          </p>
        </div>

        {canMandateInspection && (
          <button
            onClick={() => onMandateInspection()}
            className="bg-indigo-600 hover:bg-indigo-700 text-white text-xs font-semibold px-4 py-2 rounded-lg flex items-center gap-1.5 shadow-xs transition-colors"
          >
            <PlusCircle className="w-4 h-4" />
            <span>Mandate Unannounced Inspection</span>
          </button>
        )}
      </div>

      {/* Filter Bar */}
      <div className="bg-white p-4 rounded-xl border border-slate-200 shadow-xs space-y-3">
        <div className="grid grid-cols-1 sm:grid-cols-4 gap-3">
          <div className="sm:col-span-2 relative">
            <Search className="w-4 h-4 text-slate-400 absolute left-3 top-2.5" />
            <input
              type="text"
              placeholder="Search by inspection code, facility, or directive reason..."
              value={searchQuery}
              onChange={e => setSearchQuery(e.target.value)}
              className="w-full text-xs pl-9 pr-3 py-2 bg-slate-50 border border-slate-300 rounded-lg focus:bg-white focus:outline-hidden focus:ring-2 focus:ring-indigo-500 text-slate-900"
            />
          </div>

          <div>
            <select
              value={statusFilter}
              onChange={e => setStatusFilter(e.target.value)}
              className="w-full text-xs px-3 py-2 bg-slate-50 border border-slate-300 rounded-lg focus:bg-white focus:outline-hidden focus:ring-2 focus:ring-indigo-500 text-slate-800"
            >
              <option value="ALL">All Statuses</option>
              <option value="PENDING_DISPATCH">Pending Dispatch</option>
              <option value="ASSIGNED">Assigned to Inspector</option>
              <option value="IN_PROGRESS">In Progress On-Site</option>
              <option value="SUBMITTED">Report Submitted</option>
              <option value="APPROVED">Official Review Approved</option>
              <option value="CLOSED">Closed Action Taken</option>
            </select>
          </div>

          <div>
            <select
              value={priorityFilter}
              onChange={e => setPriorityFilter(e.target.value)}
              className="w-full text-xs px-3 py-2 bg-slate-50 border border-slate-300 rounded-lg focus:bg-white focus:outline-hidden focus:ring-2 focus:ring-indigo-500 text-slate-800"
            >
              <option value="ALL">All Priorities</option>
              <option value="EMERGENCY">Emergency (Immediate)</option>
              <option value="URGENT">Urgent (48 hours)</option>
              <option value="ROUTINE">Routine (Periodic)</option>
            </select>
          </div>
        </div>
      </div>

      {/* Inspections Table */}
      <div className="bg-white rounded-xl border border-slate-200 overflow-hidden shadow-xs">
        <div className="p-4 border-b border-slate-200 flex items-center justify-between">
          <span className="text-xs font-bold text-slate-800">
            Registered Directives ({filteredInspections.length})
          </span>
          <span className="text-[11px] text-slate-500">
            Official records timestamped under MoSJE Field Manual
          </span>
        </div>

        <div className="overflow-x-auto">
          <table className="w-full text-left text-xs text-slate-700">
            <thead className="bg-slate-50 text-slate-500 font-semibold border-b border-slate-200">
              <tr>
                <th className="px-5 py-3">Code & Priority</th>
                <th className="px-5 py-3">Facility</th>
                <th className="px-5 py-3">Timeline</th>
                <th className="px-5 py-3">Assigned Inspector</th>
                <th className="px-5 py-3">Status</th>
                <th className="px-5 py-3">Reason / Directive</th>
                <th className="px-5 py-3 text-right">Official Action</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-100">
              {filteredInspections.length === 0 ? (
                <tr>
                  <td colSpan={7} className="text-center py-10 text-slate-400 text-xs">
                    {isLoading ? 'Loading inspections...' : 'No inspections found matching filters.'}
                  </td>
                </tr>
              ) : (
                filteredInspections.map(insp => (
                  <tr key={insp.id} className="hover:bg-slate-50/80 transition-colors">
                    <td className="px-5 py-3.5">
                      <div className="font-bold text-slate-900 font-mono">{insp.inspection_code}</div>
                      <span
                        className={`inline-block text-[10px] font-bold px-2 py-0.2 rounded border mt-1 ${getPriorityBadge(
                          insp.priority
                        )}`}
                      >
                        {insp.priority}
                      </span>
                    </td>
                    <td className="px-5 py-3.5">
                      <div className="font-bold text-slate-900">{insp.institution_name || 'MoSJE Facility'}</div>
                      <div className="text-[11px] text-slate-400">
                        {insp.institution_district}, {insp.institution_state}
                      </div>
                    </td>
                    <td className="px-5 py-3.5 font-mono text-[11px]">
                      <div>Mandated: {insp.mandated_date}</div>
                      <div className="text-slate-400">Due: {insp.due_date}</div>
                    </td>
                    <td className="px-5 py-3.5">
                      <div className="flex items-center gap-1 text-slate-900 font-medium">
                        <User className="w-3.5 h-3.5 text-slate-400" />
                        <span>{insp.assigned_inspector_name || 'Pending Assignment'}</span>
                      </div>
                    </td>
                    <td className="px-5 py-3.5">
                      <span
                        className={`inline-block text-[10px] font-bold px-2 py-0.5 rounded border ${getStatusBadge(
                          insp.status
                        )}`}
                      >
                        {insp.status.replace(/_/g, ' ')}
                      </span>
                    </td>
                    <td className="px-5 py-3.5 max-w-xs">
                      <p className="text-slate-600 line-clamp-2 leading-relaxed">{insp.inspection_reason}</p>
                    </td>
                    <td className="px-5 py-3.5 text-right space-x-2">
                      {canReviewReports && insp.status === 'SUBMITTED' && (
                        <button
                          disabled={updatingId === insp.id}
                          onClick={() => handleStatusUpdate(insp.id, 'APPROVED')}
                          className="text-[11px] font-semibold bg-emerald-50 hover:bg-emerald-100 text-emerald-700 px-2.5 py-1 rounded border border-emerald-200 transition-colors"
                        >
                          Approve
                        </button>
                      )}
                      {canReviewReports && insp.status === 'APPROVED' && (
                        <button
                          disabled={updatingId === insp.id}
                          onClick={() => handleStatusUpdate(insp.id, 'CLOSED')}
                          className="text-[11px] font-semibold bg-slate-100 hover:bg-slate-200 text-slate-700 px-2.5 py-1 rounded transition-colors"
                        >
                          Close Order
                        </button>
                      )}
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
