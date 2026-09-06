/**
 * DRISHTI: Daily Monitoring & Telemetry View
 * Biometric punch logs vs reported headcounts, kitchen meal counts, CCTV uptime
 */

import React, { useState, useEffect } from 'react';
import {
  Activity,
  Calendar,
  AlertCircle,
  CheckCircle2,
  Filter,
  Search,
  Building2,
  Video,
  Radio,
  Coffee,
  Users,
  Fingerprint
} from 'lucide-react';
import { api } from '../api/client';
import { MonitoringRecord, Institution } from '../types/api';

interface MonitoringViewProps {
  institutions: Institution[];
  initialInstitutionId?: string;
  onMandateInspection: (instId?: string, alertId?: string, defaultReason?: string) => void;
}

export const MonitoringView: React.FC<MonitoringViewProps> = ({
  institutions,
  initialInstitutionId,
  onMandateInspection
}) => {
  const [records, setRecords] = useState<MonitoringRecord[]>([]);
  const [selectedInstId, setSelectedInstId] = useState<string>(initialInstitutionId || 'ALL');
  const [isLoading, setIsLoading] = useState<boolean>(true);

  useEffect(() => {
    async function fetchMonitoring() {
      setIsLoading(true);
      try {
        const params = selectedInstId !== 'ALL' ? { institution_id: selectedInstId } : undefined;
        const res = await api.getMonitoringRecords(params);
        const items = Array.isArray(res.data) ? res.data : (res.data as any)?.items || [];
        setRecords(items);
      } catch (err) {
        console.warn('Failed to load monitoring records, using fallback:', err);
      } finally {
        setIsLoading(false);
      }
    }
    fetchMonitoring();
  }, [selectedInstId]);

  const instList = Array.isArray(institutions) ? institutions : (institutions as any)?.items || [];

  const getInstitutionName = (id: string) => {
    const inst = instList.find(i => i.id === id);
    return inst ? inst.name : 'Registered MoSJE Facility';
  };

  return (
    <div className="space-y-5 animate-in fade-in duration-150">
      {/* Header Banner */}
      <div className="bg-white p-5 rounded-xl border border-slate-200 shadow-xs flex flex-col sm:flex-row justify-between items-start sm:items-center gap-3">
        <div>
          <h2 className="text-lg font-bold text-slate-900 tracking-tight">
            Daily Monitoring & Automated Telemetry
          </h2>
          <p className="text-xs text-slate-500">
            Real-time biometric attendance reconciliation, kitchen meal ledger records, and CCTV stream uptime
          </p>
        </div>

        {/* Institution Filter */}
        <div className="w-full sm:w-auto">
          <select
            value={selectedInstId}
            onChange={e => setSelectedInstId(e.target.value)}
            className="w-full sm:w-64 text-xs bg-slate-50 border border-slate-300 rounded-lg px-3 py-2 text-slate-900 focus:bg-white focus:outline-hidden focus:ring-2 focus:ring-indigo-500 font-medium"
          >
            <option value="ALL">All Monitored Facilities ({institutions.length})</option>
            {institutions.map(inst => (
              <option key={inst.id} value={inst.id}>
                {inst.name}
              </option>
            ))}
          </select>
        </div>
      </div>

      {/* Demo / Synthetic Data Notice */}
      <div className="bg-amber-50/70 border border-amber-200 rounded-xl p-3.5 flex items-start gap-2.5 text-xs text-amber-900 shadow-xs">
        <AlertCircle className="w-4 h-4 text-amber-600 shrink-0 mt-0.5" />
        <div className="space-y-0.5">
          <span className="font-semibold text-amber-950">Demonstration Telemetry Notice: </span>
          <span>
            Daily biometric attendance logs and CCTV uptime percentages shown are simulated demonstration telemetry for SIH evaluation. No direct physical government CCTV camera connections or real citizen Aadhaar databases are accessed in this environment.
          </span>
        </div>
      </div>

      {/* Telemetry Record Table */}
      <div className="bg-white rounded-xl border border-slate-200 overflow-hidden shadow-xs">
        <div className="p-4 border-b border-slate-200 flex items-center justify-between">
          <span className="text-xs font-bold text-slate-800">
            Recorded Telemetry Entries ({records.length})
          </span>
          <span className="text-[11px] text-slate-500">
            Automated divergence threshold: ±15% variance triggers AI attention flag
          </span>
        </div>

        <div className="overflow-x-auto">
          <table className="w-full text-left text-xs text-slate-700">
            <thead className="bg-slate-50 text-slate-500 font-semibold border-b border-slate-200">
              <tr>
                <th className="px-5 py-3">Date</th>
                <th className="px-5 py-3">Facility</th>
                <th className="px-5 py-3">Reported vs Biometric</th>
                <th className="px-5 py-3">Meals Served</th>
                <th className="px-5 py-3">Staff Present</th>
                <th className="px-5 py-3">CCTV Uptime</th>
                <th className="px-5 py-3">Geofence Status</th>
                <th className="px-5 py-3">Data Origin</th>
                <th className="px-5 py-3 text-right">Actions</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-100">
              {records.length === 0 ? (
                <tr>
                  <td colSpan={9} className="text-center py-10 text-slate-400 text-xs">
                    {isLoading ? 'Loading monitoring telemetry...' : 'No telemetry records logged for this filter.'}
                  </td>
                </tr>
              ) : (
                records.map(record => {
                  const discrepancy = Math.abs(
                    record.reported_beneficiaries_present - record.biometric_punch_count
                  );
                  const hasDiscrepancy = discrepancy > 5;
                  const instName = record.institution_name || getInstitutionName(record.institution_id);

                  return (
                    <tr key={record.id} className="hover:bg-slate-50/80 transition-colors">
                      <td className="px-5 py-3.5 font-mono text-slate-900">
                        {record.record_date}
                      </td>
                      <td className="px-5 py-3.5">
                        <div className="font-bold text-slate-900">{instName}</div>
                      </td>
                      <td className="px-5 py-3.5">
                        <div className="flex items-center gap-2">
                          <span className="font-semibold text-slate-900">
                            {record.biometric_punch_count} biometric
                          </span>
                          <span className="text-slate-400">/</span>
                          <span className="text-slate-600">{record.reported_beneficiaries_present} declared</span>
                        </div>
                        {hasDiscrepancy && (
                          <span className="inline-flex items-center gap-1 text-[10px] text-red-600 font-semibold bg-red-50 px-1.5 py-0.2 rounded mt-0.5 border border-red-100">
                            <AlertCircle className="w-3 h-3" />
                            <span>Δ {discrepancy} divergence</span>
                          </span>
                        )}
                      </td>
                      <td className="px-5 py-3.5">
                        <div className="flex items-center gap-1 text-slate-800">
                          <Coffee className="w-3.5 h-3.5 text-amber-600" />
                          <span>{record.meals_served_count} portions</span>
                        </div>
                      </td>
                      <td className="px-5 py-3.5">
                        <div className="flex items-center gap-1 text-slate-800">
                          <Users className="w-3.5 h-3.5 text-blue-600" />
                          <span>{record.staff_present_count} on duty</span>
                        </div>
                      </td>
                      <td className="px-5 py-3.5">
                        <div className="flex items-center gap-1">
                          <Video className="w-3.5 h-3.5 text-teal-600" />
                          <span
                            className={`font-semibold ${
                              record.cctv_uptime_percentage < 80 ? 'text-red-600' : 'text-slate-900'
                            }`}
                          >
                            {record.cctv_uptime_percentage}%
                          </span>
                        </div>
                      </td>
                      <td className="px-5 py-3.5">
                        <span
                          className={`inline-flex items-center gap-1 text-[11px] font-medium px-2 py-0.5 rounded ${
                            record.geofence_status.includes('MATCHED')
                              ? 'bg-emerald-50 text-emerald-700'
                              : 'bg-amber-50 text-amber-700'
                          }`}
                        >
                          <Radio className="w-3 h-3" />
                          <span>{record.geofence_status.replace(/_/g, ' ')}</span>
                        </span>
                      </td>
                      <td className="px-5 py-3.5">
                        <span className="text-[10px] font-mono font-medium px-2 py-0.5 rounded bg-slate-100 text-slate-600 border border-slate-200">
                          {record.is_synthetic ? 'DEMO / SYNTHETIC' : 'LIVE TELEMETRY'}
                        </span>
                      </td>
                      <td className="px-5 py-3.5 text-right">
                        {hasDiscrepancy && (
                          <button
                            onClick={() =>
                              onMandateInspection(
                                record.institution_id,
                                undefined,
                                `Mandated inspection on ${record.record_date}: Biometric punch divergence of ${discrepancy} detected.`
                              )
                            }
                            className="text-[11px] font-semibold bg-red-50 hover:bg-red-100 text-red-700 px-2 py-1 rounded border border-red-200 transition-colors"
                          >
                            Mandate Audit
                          </button>
                        )}
                      </td>
                    </tr>
                  );
                })
              )}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
};
