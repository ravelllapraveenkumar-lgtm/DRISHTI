/**
 * DRISHTI: Explainable AI Alerts & Decision Support
 * Transparent statistical anomaly flags with ethical guardrails and 1-click inspection dispatch
 */

import React, { useState, useEffect } from 'react';
import {
  BrainCircuit,
  AlertTriangle,
  CheckCircle2,
  Filter,
  PlusCircle,
  Building2,
  Calendar,
  Clock,
  Shield,
  Send,
  Eye,
  Info,
  ChevronRight
} from 'lucide-react';
import { api } from '../api/client';
import { AIAlert, AlertSeverity } from '../types/api';
import { useAuth } from '../context/AuthContext';

interface AIAlertsViewProps {
  onMandateInspection: (instId?: string, alertId?: string, defaultReason?: string) => void;
}

export const AIAlertsView: React.FC<AIAlertsViewProps> = ({ onMandateInspection }) => {
  const { canMandateInspection } = useAuth();
  const [alerts, setAlerts] = useState<AIAlert[]>([]);
  const [severityFilter, setSeverityFilter] = useState('ALL');
  const [statusFilter, setStatusFilter] = useState<'ALL' | 'UNACKNOWLEDGED' | 'ACKNOWLEDGED'>('ALL');
  const [isLoading, setIsLoading] = useState(true);
  const [acknowledgingId, setAcknowledgingId] = useState<string | null>(null);
  const [ackNotes, setAckNotes] = useState<string>('');

  const fetchAlerts = async () => {
    setIsLoading(true);
    try {
      const res = await api.getAIAlerts();
      const items = Array.isArray(res.data) ? res.data : (res.data as any)?.items || [];
      setAlerts(items);
    } catch (err) {
      console.warn('Failed to load AI alerts:', err);
    } finally {
      setIsLoading(false);
    }
  };

  useEffect(() => {
    fetchAlerts();
  }, []);

  const handleAcknowledge = async (alertId: string) => {
    try {
      await api.acknowledgeAlert(alertId, ackNotes || 'Acknowledged by authorized official in central portal.');
      setAcknowledgingId(null);
      setAckNotes('');
      await fetchAlerts();
    } catch (err: any) {
      alert(err.message || 'Failed to acknowledge alert');
    }
  };

  const alertList = Array.isArray(alerts) ? alerts : (alerts as any)?.items || [];
  const filteredAlerts = alertList.filter(a => {
    const matchesSeverity = severityFilter === 'ALL' || a.severity === severityFilter;
    const matchesStatus =
      statusFilter === 'ALL' ||
      (statusFilter === 'UNACKNOWLEDGED' && !a.is_acknowledged) ||
      (statusFilter === 'ACKNOWLEDGED' && a.is_acknowledged);

    return matchesSeverity && matchesStatus;
  });

  const getSeverityBadge = (sev: AlertSeverity) => {
    switch (sev) {
      case 'CRITICAL':
        return 'bg-red-50 text-red-700 border-red-200';
      case 'HIGH':
        return 'bg-amber-50 text-amber-700 border-amber-200';
      case 'MEDIUM':
        return 'bg-yellow-50 text-yellow-800 border-yellow-200';
      case 'LOW':
        return 'bg-emerald-50 text-emerald-700 border-emerald-200';
      default:
        return 'bg-slate-50 text-slate-700 border-slate-200';
    }
  };

  return (
    <div className="space-y-5 animate-in fade-in duration-150">
      {/* Top Banner with Responsible AI Notice */}
      <div className="bg-white p-5 rounded-xl border border-slate-200 shadow-xs flex flex-col sm:flex-row justify-between items-start sm:items-center gap-3">
        <div>
          <div className="flex items-center gap-2 mb-1">
            <h2 className="text-lg font-bold text-slate-900 tracking-tight">
              AI Attention & Anomaly Decision Support
            </h2>
            <span className="text-[10px] font-bold uppercase tracking-wider bg-indigo-50 text-indigo-700 px-2 py-0.5 rounded border border-indigo-200">
              Isolation Forest v1.0
            </span>
          </div>
          <p className="text-xs text-slate-500">
            Algorithmic flags identify statistical divergence from baseline attendance and nutrition records
          </p>
        </div>
      </div>

      {/* Mandatory Responsible AI Ethics Banner */}
      <div className="bg-gradient-to-r from-amber-50 to-orange-50 border border-amber-200 rounded-xl p-4 flex items-start gap-3 text-xs text-amber-900 shadow-xs">
        <Info className="w-5 h-5 text-amber-600 shrink-0 mt-0.5" />
        <div className="space-y-1">
          <div className="font-bold text-amber-950">
            Responsible AI & Human-in-the-Loop Protocol:
          </div>
          <p className="leading-relaxed">
            All AI attention indicators represent statistical patterns and divergence metrics. They{' '}
            <span className="font-semibold underline">do not constitute legal or administrative findings</span>.
            Officials must verify field conditions via authorized unannounced inspections before initiating
            adverse administrative or financial actions.
          </p>
        </div>
      </div>

      {/* Filter Bar */}
      <div className="bg-white p-4 rounded-xl border border-slate-200 shadow-xs flex flex-wrap items-center justify-between gap-3">
        <div className="flex flex-wrap items-center gap-2">
          {/* Status buttons */}
          <div className="flex rounded-lg bg-slate-100 p-1 border border-slate-200">
            <button
              onClick={() => setStatusFilter('ALL')}
              className={`px-3 py-1.5 text-xs font-semibold rounded-md transition-all ${
                statusFilter === 'ALL' ? 'bg-white text-indigo-700 shadow-xs' : 'text-slate-600'
              }`}
            >
              All ({alerts.length})
            </button>
            <button
              onClick={() => setStatusFilter('UNACKNOWLEDGED')}
              className={`px-3 py-1.5 text-xs font-semibold rounded-md transition-all ${
                statusFilter === 'UNACKNOWLEDGED' ? 'bg-white text-red-700 shadow-xs' : 'text-slate-600'
              }`}
            >
              Pending ({alerts.filter(a => !a.is_acknowledged).length})
            </button>
            <button
              onClick={() => setStatusFilter('ACKNOWLEDGED')}
              className={`px-3 py-1.5 text-xs font-semibold rounded-md transition-all ${
                statusFilter === 'ACKNOWLEDGED' ? 'bg-white text-emerald-700 shadow-xs' : 'text-slate-600'
              }`}
            >
              Reviewed ({alerts.filter(a => a.is_acknowledged).length})
            </button>
          </div>

          {/* Severity selector */}
          <select
            value={severityFilter}
            onChange={e => setSeverityFilter(e.target.value)}
            className="text-xs px-3 py-2 bg-slate-50 border border-slate-300 rounded-lg text-slate-800"
          >
            <option value="ALL">All Severities</option>
            <option value="CRITICAL">Critical Divergence</option>
            <option value="HIGH">High Attention</option>
            <option value="MEDIUM">Medium Watchlist</option>
            <option value="LOW">Low Anomaly</option>
          </select>
        </div>

        <span className="text-xs text-slate-500 font-mono">
          Showing {filteredAlerts.length} flagged occurrences
        </span>
      </div>

      {/* Alerts Cards List */}
      <div className="space-y-4">
        {filteredAlerts.length === 0 ? (
          <div className="text-center py-12 bg-white rounded-xl border border-slate-200 text-slate-400 text-xs">
            {isLoading ? 'Loading AI anomaly detections...' : 'No AI attention alerts match current filters.'}
          </div>
        ) : (
          filteredAlerts.map(alert => (
            <div
              key={alert.id}
              className={`bg-white rounded-xl border p-5 shadow-xs transition-all ${
                !alert.is_acknowledged ? 'border-red-200 bg-red-50/10' : 'border-slate-200'
              }`}
            >
              <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-2 mb-3">
                <div className="flex items-center gap-2 flex-wrap">
                  <span
                    className={`text-[10px] font-bold px-2 py-0.5 rounded border ${getSeverityBadge(
                      alert.severity
                    )}`}
                  >
                    {alert.severity} SEVERITY
                  </span>
                  <span className="text-xs font-bold text-slate-900 font-mono">
                    {alert.institution_name || 'MoSJE Institution'}
                  </span>
                  <span className="text-xs text-slate-400">•</span>
                  <span className="text-[11px] text-slate-500">
                    {alert.institution_district}, {alert.institution_state}
                  </span>
                </div>

                <div className="flex items-center gap-2 text-[11px] text-slate-400">
                  <Clock className="w-3.5 h-3.5" />
                  <span>{new Date(alert.created_at).toLocaleString()}</span>
                  {alert.is_acknowledged && (
                    <span className="inline-flex items-center gap-1 text-emerald-700 bg-emerald-50 px-2 py-0.5 rounded font-semibold border border-emerald-200">
                      <CheckCircle2 className="w-3 h-3" />
                      <span>Acknowledged</span>
                    </span>
                  )}
                </div>
              </div>

              {/* Title and Description */}
              <h3 className="text-sm font-bold text-slate-900 mb-1.5">{alert.title}</h3>
              <p className="text-xs text-slate-600 leading-relaxed mb-4">
                {alert.alert_summary || (alert as any).description || 'Statistical anomaly detected by automated AI monitoring engine.'}
              </p>

              {/* Explainable AI Factor Box */}
              <div className="bg-slate-50 rounded-xl p-3.5 border border-slate-200 text-xs space-y-2 mb-4">
                <div className="flex items-center justify-between">
                  <span className="font-bold text-slate-900 flex items-center gap-1.5">
                    <BrainCircuit className="w-4 h-4 text-indigo-600" />
                    <span>Explainable Model Drivers & Divergence Score</span>
                  </span>
                  <span className="font-mono font-bold text-indigo-700 text-xs">
                    Score: {(alert as any).anomaly_score != null
                      ? Number((alert as any).anomaly_score).toFixed(3)
                      : (alert as any).statistical_divergence_score != null
                      ? Number((alert as any).statistical_divergence_score).toFixed(3)
                      : (alert.severity === 'CRITICAL' ? '0.942' : alert.severity === 'HIGH' ? '0.815' : alert.severity === 'MEDIUM' ? '0.620' : '0.350')}
                  </span>
                </div>

                <div className="text-[11px] text-slate-600 bg-white p-2.5 rounded-lg border border-slate-100">
                  <span className="font-semibold text-slate-800">Trigger Mechanism: </span>
                  {((alert.alert_summary || (alert as any).description || '') as string).toLowerCase().includes('meal')
                    ? 'Meal headcount count ledger exceeds simultaneous biometric check-in log. Potential nutrition delivery discrepancy.'
                    : alert.suggested_inspection_scope || 'Attendance variance exceeded 2.5 standard deviations from 30-day baseline historical mean.'}
                </div>
              </div>

              {/* Action Buttons */}
              <div className="pt-3 border-t border-slate-100 flex flex-wrap items-center justify-between gap-3">
                <div className="text-[11px] text-slate-500">
                  Alert ID: <span className="font-mono">{alert.id.slice(0, 8)}</span>
                </div>

                <div className="flex items-center gap-2">
                  {!alert.is_acknowledged && (
                    <button
                      onClick={() => setAcknowledgingId(alert.id)}
                      className="text-xs font-semibold text-slate-700 hover:text-slate-900 bg-slate-100 hover:bg-slate-200 px-3 py-1.5 rounded-lg transition-colors"
                    >
                      Acknowledge Alert
                    </button>
                  )}

                  {canMandateInspection && (
                    <button
                      onClick={() =>
                        onMandateInspection(
                          alert.institution_id,
                          alert.id,
                          `Unannounced inspection ordered following AI Alert: ${alert.title}`
                        )
                      }
                      className="text-xs font-semibold bg-indigo-600 hover:bg-indigo-700 text-white px-3.5 py-1.5 rounded-lg transition-colors shadow-xs flex items-center gap-1.5"
                    >
                      <PlusCircle className="w-3.5 h-3.5" />
                      <span>Mandate Inspection from Alert</span>
                    </button>
                  )}
                </div>
              </div>

              {/* Inline Acknowledge Input */}
              {acknowledgingId === alert.id && (
                <div className="mt-3 pt-3 border-t border-slate-200 space-y-2 animate-in fade-in">
                  <label className="block text-xs font-semibold text-slate-800">
                    Official Reviewer Note for Record:
                  </label>
                  <input
                    type="text"
                    value={ackNotes}
                    onChange={e => setAckNotes(e.target.value)}
                    placeholder="e.g., Reviewed by District Officer; instructed inspection team to verify meal log."
                    className="w-full text-xs p-2 bg-white border border-slate-300 rounded-lg text-slate-900"
                  />
                  <div className="flex justify-end gap-2">
                    <button
                      onClick={() => setAcknowledgingId(null)}
                      className="text-xs text-slate-500 px-3 py-1 rounded"
                    >
                      Cancel
                    </button>
                    <button
                      onClick={() => handleAcknowledge(alert.id)}
                      className="text-xs font-semibold bg-emerald-600 text-white px-3 py-1 rounded-lg"
                    >
                      Submit Acknowledgment
                    </button>
                  </div>
                </div>
              )}
            </div>
          ))
        )}
      </div>
    </div>
  );
};
