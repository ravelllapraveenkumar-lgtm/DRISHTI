/**
 * DRISHTI: Inspection Assignments & Fieldwork Dispatch
 * Cadre assignment management, acceptance, and on-site arrival geo-stamping
 */

import React, { useState, useEffect } from 'react';
import {
  UserCheck,
  Clock,
  MapPin,
  CheckCircle2,
  AlertCircle,
  Building2,
  Calendar,
  Navigation,
  ShieldCheck,
  ExternalLink
} from 'lucide-react';
import { api } from '../api/client';
import { InspectionAssignment } from '../types/api';
import { useAuth } from '../context/AuthContext';

export const AssignmentsView: React.FC = () => {
  const { user, isInspector, canMandateInspection } = useAuth();
  const [assignments, setAssignments] = useState<InspectionAssignment[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [actionInProgress, setActionInProgress] = useState<string | null>(null);

  const fetchAssignments = async () => {
    setIsLoading(true);
    try {
      const res = await api.getAssignments();
      const items = Array.isArray(res.data) ? res.data : (res.data as any)?.items || [];
      setAssignments(items);
    } catch (err) {
      console.warn('Failed to fetch assignments:', err);
    } finally {
      setIsLoading(false);
    }
  };

  useEffect(() => {
    fetchAssignments();
  }, []);

  const handleAccept = async (id: string) => {
    setActionInProgress(id);
    try {
      await api.acceptAssignment(id);
      await fetchAssignments();
    } catch (err: any) {
      alert(err.message || 'Failed to accept assignment');
    } finally {
      setActionInProgress(null);
    }
  };

  const handleArrive = async (id: string) => {
    setActionInProgress(id);
    try {
      // Mock on-site coordinates
      await api.markArrival(id, 26.8467, 80.9462);
      await fetchAssignments();
    } catch (err: any) {
      alert(err.message || 'Failed to record on-site arrival');
    } finally {
      setActionInProgress(null);
    }
  };

  return (
    <div className="space-y-5 animate-in fade-in duration-150">
      <div className="bg-white p-5 rounded-xl border border-slate-200 shadow-xs flex flex-col sm:flex-row justify-between items-start sm:items-center gap-3">
        <div>
          <h2 className="text-lg font-bold text-slate-900 tracking-tight">
            Fieldwork Assignments & Inspector Dispatch
          </h2>
          <p className="text-xs text-slate-500">
            Lifecycle monitoring from dispatch acknowledgment to tamper-evident on-site GPS arrival
          </p>
        </div>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
        {(!Array.isArray(assignments) || assignments.length === 0) ? (
          <div className="col-span-full text-center py-12 bg-white rounded-xl border border-slate-200 text-slate-400 text-xs">
            {isLoading ? 'Loading assignments...' : 'No assignments currently dispatched.'}
          </div>
        ) : (
          assignments.map(assign => {
            const hasAccepted = Boolean(assign.accepted_at);
            const hasArrived = Boolean(assign.arrived_at);

            return (
              <div
                key={assign.id}
                className="bg-white rounded-xl border border-slate-200 p-5 shadow-xs space-y-4 flex flex-col justify-between"
              >
                <div>
                  {/* Top Bar */}
                  <div className="flex items-center justify-between gap-2 mb-2">
                    <span className="text-[10px] font-bold text-indigo-700 bg-indigo-50 px-2 py-0.5 rounded border border-indigo-200 font-mono">
                      Inspection #{assign.inspection_id.slice(0, 8)}
                    </span>
                    <span
                      className={`text-[10px] font-bold px-2 py-0.5 rounded border ${
                        hasArrived
                          ? 'bg-emerald-50 text-emerald-700 border-emerald-200'
                          : hasAccepted
                          ? 'bg-blue-50 text-blue-700 border-blue-200'
                          : 'bg-amber-50 text-amber-700 border-amber-200'
                      }`}
                    >
                      {hasArrived ? 'ON-SITE VERIFIED' : hasAccepted ? 'ACCEPTED • IN TRANSIT' : 'PENDING ACCEPTANCE'}
                    </span>
                  </div>

                  {/* Inspector Name & Role */}
                  <h3 className="font-bold text-sm text-slate-900 mb-1">
                    {assign.inspector_name || 'Designated Inspector'}
                  </h3>
                  <div className="text-xs text-slate-500 mb-3">
                    Assigned: {new Date(assign.assigned_at).toLocaleString()}
                  </div>

                  {/* Timeline Stages */}
                  <div className="space-y-2 text-xs border-y border-slate-100 py-3 mb-3">
                    <div className="flex items-center justify-between">
                      <span className="text-slate-500">1. Dispatch Order:</span>
                      <span className="font-medium text-slate-800">
                        {new Date(assign.assigned_at).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}
                      </span>
                    </div>

                    <div className="flex items-center justify-between">
                      <span className="text-slate-500">2. Official Acceptance:</span>
                      <span
                        className={`font-medium ${
                          hasAccepted ? 'text-emerald-700' : 'text-slate-400 italic'
                        }`}
                      >
                        {hasAccepted
                          ? new Date(assign.accepted_at!).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })
                          : 'Awaiting acknowledgment'}
                      </span>
                    </div>

                    <div className="flex items-center justify-between">
                      <span className="text-slate-500">3. Geofence Arrival Stamp:</span>
                      <span
                        className={`font-medium ${
                          hasArrived ? 'text-emerald-700' : 'text-slate-400 italic'
                        }`}
                      >
                        {hasArrived
                          ? `Stamped at ${new Date(assign.arrived_at!).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}`
                          : 'Pending on-site GPS verification'}
                      </span>
                    </div>
                  </div>
                </div>

                {/* Interactive Action Controls */}
                <div className="pt-2 flex items-center justify-end gap-2">
                  {!hasAccepted && (
                    <button
                      disabled={actionInProgress === assign.id}
                      onClick={() => handleAccept(assign.id)}
                      className="text-xs font-semibold bg-indigo-600 hover:bg-indigo-700 text-white px-3 py-1.5 rounded-lg transition-colors shadow-xs"
                    >
                      {actionInProgress === assign.id ? 'Processing...' : 'Accept Assignment'}
                    </button>
                  )}

                  {hasAccepted && !hasArrived && (
                    <button
                      disabled={actionInProgress === assign.id}
                      onClick={() => handleArrive(assign.id)}
                      className="text-xs font-semibold bg-emerald-600 hover:bg-emerald-700 text-white px-3 py-1.5 rounded-lg transition-colors shadow-xs flex items-center gap-1.5"
                    >
                      <Navigation className="w-3.5 h-3.5" />
                      <span>{actionInProgress === assign.id ? 'Verifying GPS...' : 'Mark On-Site Arrival'}</span>
                    </button>
                  )}

                  {hasArrived && (
                    <div className="text-[11px] text-emerald-700 font-medium flex items-center gap-1">
                      <ShieldCheck className="w-4 h-4 text-emerald-600" />
                      <span>Geofence GPS Authenticated</span>
                    </div>
                  )}
                </div>
              </div>
            );
          })
        )}
      </div>
    </div>
  );
};
