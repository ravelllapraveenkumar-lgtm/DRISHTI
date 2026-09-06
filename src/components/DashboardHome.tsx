/**
 * DRISHTI: Government Central Dashboard Home
 * Executive Decision-Support Interface, Scheme Health, Risk Matrix & Quick Mandate
 */

import React from 'react';
import {
  Building2,
  Users,
  ClipboardCheck,
  AlertTriangle,
  Activity,
  Video,
  ShieldCheck,
  ArrowUpRight,
  TrendingUp,
  BrainCircuit,
  ExternalLink,
  ChevronRight,
  PlusCircle,
  Calendar,
  Eye,
  CheckCircle2,
  Clock
} from 'lucide-react';
import { DashboardSummary, Institution, AIAlert, SchemeStats } from '../types/api';
import { useAuth } from '../context/AuthContext';

interface DashboardHomeProps {
  summary: DashboardSummary | null;
  institutions: Institution[];
  alerts: AIAlert[];
  isLoading: boolean;
  onNavigate: (tab: string) => void;
  onMandateInspection: (instId?: string, alertId?: string, defaultReason?: string) => void;
  onSelectInstitution: (inst: Institution) => void;
}

export const DashboardHome: React.FC<DashboardHomeProps> = ({
  summary,
  institutions,
  alerts,
  isLoading,
  onNavigate,
  onMandateInspection,
  onSelectInstitution
}) => {
  const { canMandateInspection } = useAuth();

  const safeInstitutions = Array.isArray(institutions) ? institutions : (institutions as any)?.items || [];
  const safeAlerts = Array.isArray(alerts) ? alerts : (alerts as any)?.items || [];

  const totalInst = summary?.total_institutions ?? safeInstitutions.length;
  const totalBeneficiaries = summary?.total_beneficiaries ?? 2;
  const activeInspections = summary?.active_inspections ?? 1;
  const pendingAlerts = summary?.pending_ai_alerts ?? safeAlerts.filter(a => !a.is_acknowledged).length;
  const avgAttendance = summary?.average_daily_attendance_pct ?? 91.5;
  const cctvOnline = summary?.cctv_online_rate_pct ?? 99.2;

  const riskDist = summary?.risk_distribution || {
    critical: safeInstitutions.filter(i => i.risk_level === 'CRITICAL').length || 1,
    high: safeInstitutions.filter(i => i.risk_level === 'HIGH').length || 1,
    medium: safeInstitutions.filter(i => i.risk_level === 'MEDIUM').length || 0,
    low: safeInstitutions.filter(i => i.risk_level === 'LOW').length || 1
  };

  const totalRiskCount = (riskDist.critical + riskDist.high + riskDist.medium + riskDist.low) || 1;

  // High attention institutions
  const priorityInstitutions = [...safeInstitutions].sort(
    (a, b) => (b.current_risk_score || 0) - (a.current_risk_score || 0)
  );

  return (
    <div className="space-y-6 animate-in fade-in duration-150">
      {/* Official MoSJE Banner & Responsible AI Assurance */}
      <div className="bg-gradient-to-r from-[#0F172A] via-[#1E293B] to-indigo-950 rounded-2xl p-6 text-white shadow-md border border-slate-800 relative overflow-hidden">
        <div className="relative z-10 max-w-3xl">
          <div className="inline-flex items-center gap-2 bg-indigo-500/20 text-indigo-300 text-xs px-3 py-1 rounded-full border border-indigo-500/30 mb-3 font-medium">
            <ShieldCheck className="w-3.5 h-3.5 text-indigo-400" />
            <span>SIH 2026 Problem ID: 26095 • National Central Monitoring Cadre</span>
          </div>
          <h2 className="text-xl sm:text-2xl font-bold tracking-tight text-white mb-2">
            Centralized Scheme Governance & High-Risk Surveillance
          </h2>
          <p className="text-xs sm:text-sm text-slate-300 leading-relaxed">
            Real-time biometric attendance reconciliation, automated kitchen meal count telemetry,
            and machine learning anomaly flags across DDRS, AVYAY, NAPDDR, and PM-DAKSH facilities.
          </p>

          <div className="mt-4 flex flex-wrap gap-3">
            {canMandateInspection && (
              <button
                onClick={() => onMandateInspection()}
                className="bg-indigo-600 hover:bg-indigo-500 text-white text-xs font-semibold px-4 py-2 rounded-lg transition-colors flex items-center gap-1.5 shadow-xs"
              >
                <PlusCircle className="w-4 h-4" />
                <span>Mandate Unannounced Inspection</span>
              </button>
            )}
            <button
              onClick={() => onNavigate('alerts')}
              className="bg-slate-800/80 hover:bg-slate-700 text-slate-200 text-xs font-medium px-4 py-2 rounded-lg border border-slate-700 transition-colors flex items-center gap-1.5"
            >
              <BrainCircuit className="w-4 h-4 text-indigo-400" />
              <span>Review AI Attention Alerts ({pendingAlerts})</span>
            </button>
          </div>
        </div>

        {/* Responsible AI Watermark Badge */}
        <div className="mt-4 sm:mt-0 sm:absolute sm:bottom-4 sm:right-6 bg-slate-900/80 border border-slate-700/80 rounded-xl p-3 text-[11px] text-slate-400 max-w-xs">
          <div className="text-indigo-300 font-semibold mb-0.5 flex items-center gap-1">
            <CheckCircle2 className="w-3.5 h-3.5 text-emerald-400" />
            <span>Ethical AI Safeguard Protocol</span>
          </div>
          <span>
            Decision-support only. Statistical divergence prompts human field verification, never automated punitive actions.
          </span>
        </div>
      </div>

      {/* Primary KPI Grid */}
      <div className="grid grid-cols-2 lg:grid-cols-6 gap-3 sm:gap-4">
        {/* Monitored Institutions */}
        <div className="bg-white p-4 rounded-xl border border-slate-200 shadow-xs">
          <div className="flex items-center justify-between text-slate-500 mb-2">
            <span className="text-xs font-medium">Institutions</span>
            <Building2 className="w-4 h-4 text-indigo-600" />
          </div>
          <div className="text-2xl font-bold text-slate-900">{totalInst}</div>
          <div className="text-[11px] text-slate-500 mt-1 flex items-center gap-1">
            <span className="text-emerald-600 font-medium">100% active</span> in registry
          </div>
        </div>

        {/* Registered Beneficiaries */}
        <div className="bg-white p-4 rounded-xl border border-slate-200 shadow-xs">
          <div className="flex items-center justify-between text-slate-500 mb-2">
            <span className="text-xs font-medium">Beneficiaries</span>
            <Users className="w-4 h-4 text-blue-600" />
          </div>
          <div className="text-2xl font-bold text-slate-900">{totalBeneficiaries}</div>
          <div className="text-[11px] text-slate-500 mt-1">
            <span>Verified Aadhaar / Biometric</span>
          </div>
        </div>

        {/* Active Inspections */}
        <div className="bg-white p-4 rounded-xl border border-slate-200 shadow-xs">
          <div className="flex items-center justify-between text-slate-500 mb-2">
            <span className="text-xs font-medium">Inspections</span>
            <ClipboardCheck className="w-4 h-4 text-purple-600" />
          </div>
          <div className="text-2xl font-bold text-slate-900">{activeInspections}</div>
          <div className="text-[11px] text-indigo-600 font-medium mt-1">
            <span>Active in Field</span>
          </div>
        </div>

        {/* AI Alerts */}
        <div
          onClick={() => onNavigate('alerts')}
          className="bg-white p-4 rounded-xl border border-slate-200 shadow-xs cursor-pointer hover:border-red-300 transition-colors"
        >
          <div className="flex items-center justify-between text-slate-500 mb-2">
            <span className="text-xs font-medium">Pending Alerts</span>
            <AlertTriangle className="w-4 h-4 text-red-500" />
          </div>
          <div className="text-2xl font-bold text-red-600">{pendingAlerts}</div>
          <div className="text-[11px] text-red-700 font-medium mt-1">
            <span>Human review required</span>
          </div>
        </div>

        {/* Daily Attendance Rate */}
        <div className="bg-white p-4 rounded-xl border border-slate-200 shadow-xs">
          <div className="flex items-center justify-between text-slate-500 mb-2">
            <span className="text-xs font-medium">Avg Attendance</span>
            <Activity className="w-4 h-4 text-emerald-600" />
          </div>
          <div className="text-2xl font-bold text-slate-900">{avgAttendance}%</div>
          <div className="text-[11px] text-emerald-600 font-medium mt-1 flex items-center gap-0.5">
            <TrendingUp className="w-3 h-3" />
            <span>Target: &gt;85% baseline</span>
          </div>
        </div>

        {/* CCTV Health */}
        <div className="bg-white p-4 rounded-xl border border-slate-200 shadow-xs">
          <div className="flex items-center justify-between text-slate-500 mb-2">
            <span className="text-xs font-medium">CCTV Health</span>
            <Video className="w-4 h-4 text-teal-600" />
          </div>
          <div className="text-2xl font-bold text-slate-900">{cctvOnline}%</div>
          <div className="text-[11px] text-teal-700 font-medium mt-1">
            <span>Active streams online</span>
          </div>
        </div>
      </div>

      {/* Two Column Section: Risk Distribution & Scheme Stats */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Risk / Attention Distribution */}
        <div className="bg-white rounded-xl border border-slate-200 p-5 shadow-xs">
          <div className="flex items-center justify-between mb-4">
            <div>
              <h3 className="font-bold text-sm text-slate-900">Institution Attention Distribution</h3>
              <p className="text-xs text-slate-500">Calculated via Isolation Forest & Multi-factor Scoring</p>
            </div>
            <BrainCircuit className="w-4 h-4 text-slate-400" />
          </div>

          <div className="space-y-3">
            {/* Critical */}
            <div>
              <div className="flex justify-between text-xs font-medium mb-1">
                <span className="text-red-700 flex items-center gap-1.5">
                  <span className="w-2 h-2 rounded-full bg-red-600"></span>
                  Critical Attention (Score 80-100)
                </span>
                <span className="font-bold text-slate-900">
                  {riskDist.critical} ({Math.round((riskDist.critical / totalRiskCount) * 100)}%)
                </span>
              </div>
              <div className="w-full bg-slate-100 rounded-full h-2 overflow-hidden">
                <div
                  className="bg-red-600 h-2 rounded-full transition-all"
                  style={{ width: `${(riskDist.critical / totalRiskCount) * 100}%` }}
                />
              </div>
            </div>

            {/* High */}
            <div>
              <div className="flex justify-between text-xs font-medium mb-1">
                <span className="text-amber-700 flex items-center gap-1.5">
                  <span className="w-2 h-2 rounded-full bg-amber-500"></span>
                  High Priority (Score 60-79)
                </span>
                <span className="font-bold text-slate-900">
                  {riskDist.high} ({Math.round((riskDist.high / totalRiskCount) * 100)}%)
                </span>
              </div>
              <div className="w-full bg-slate-100 rounded-full h-2 overflow-hidden">
                <div
                  className="bg-amber-500 h-2 rounded-full transition-all"
                  style={{ width: `${(riskDist.high / totalRiskCount) * 100}%` }}
                />
              </div>
            </div>

            {/* Medium */}
            <div>
              <div className="flex justify-between text-xs font-medium mb-1">
                <span className="text-yellow-700 flex items-center gap-1.5">
                  <span className="w-2 h-2 rounded-full bg-yellow-400"></span>
                  Medium Watchlist (Score 30-59)
                </span>
                <span className="font-bold text-slate-900">
                  {riskDist.medium} ({Math.round((riskDist.medium / totalRiskCount) * 100)}%)
                </span>
              </div>
              <div className="w-full bg-slate-100 rounded-full h-2 overflow-hidden">
                <div
                  className="bg-yellow-400 h-2 rounded-full transition-all"
                  style={{ width: `${(riskDist.medium / totalRiskCount) * 100}%` }}
                />
              </div>
            </div>

            {/* Low */}
            <div>
              <div className="flex justify-between text-xs font-medium mb-1">
                <span className="text-emerald-700 flex items-center gap-1.5">
                  <span className="w-2 h-2 rounded-full bg-emerald-500"></span>
                  Low / Normal Baseline (Score 0-29)
                </span>
                <span className="font-bold text-slate-900">
                  {riskDist.low} ({Math.round((riskDist.low / totalRiskCount) * 100)}%)
                </span>
              </div>
              <div className="w-full bg-slate-100 rounded-full h-2 overflow-hidden">
                <div
                  className="bg-emerald-500 h-2 rounded-full transition-all"
                  style={{ width: `${(riskDist.low / totalRiskCount) * 100}%` }}
                />
              </div>
            </div>
          </div>

          <div className="mt-4 pt-3 border-t border-slate-100 text-[11px] text-slate-500">
            High scores prompt priority unannounced dispatch queue under District Welfare Officer jurisdiction.
          </div>
        </div>

        {/* Scheme Coverage Breakdown */}
        <div className="lg:col-span-2 bg-white rounded-xl border border-slate-200 p-5 shadow-xs">
          <div className="flex items-center justify-between mb-4">
            <div>
              <h3 className="font-bold text-sm text-slate-900">MoSJE Scheme Coverage Matrix</h3>
              <p className="text-xs text-slate-500">Active monitoring status across statutory welfare schemes</p>
            </div>
            <button
              onClick={() => onNavigate('institutions')}
              className="text-xs text-indigo-600 hover:text-indigo-800 font-medium flex items-center gap-1"
            >
              <span>View All</span>
              <ChevronRight className="w-3.5 h-3.5" />
            </button>
          </div>

          <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
            {/* DDRS */}
            <div className="p-3.5 rounded-xl border border-slate-200 bg-slate-50/50 hover:bg-slate-50 transition-colors">
              <div className="flex items-center justify-between mb-1.5">
                <span className="text-xs font-bold text-slate-900">DDRS Scheme</span>
                <span className="text-[10px] font-semibold bg-blue-100 text-blue-800 px-2 py-0.5 rounded">
                  Disability
                </span>
              </div>
              <div className="text-xs text-slate-600 mb-2 font-medium">
                Deendayal Disabled Rehabilitation Scheme
              </div>
              <div className="flex items-center justify-between text-xs text-slate-500 pt-2 border-t border-slate-200">
                <span>Facilities: 1</span>
                <span>Active Roster: 2</span>
              </div>
            </div>

            {/* AVYAY */}
            <div className="p-3.5 rounded-xl border border-slate-200 bg-slate-50/50 hover:bg-slate-50 transition-colors">
              <div className="flex items-center justify-between mb-1.5">
                <span className="text-xs font-bold text-slate-900">AVYAY Scheme</span>
                <span className="text-[10px] font-semibold bg-emerald-100 text-emerald-800 px-2 py-0.5 rounded">
                  Senior Citizens
                </span>
              </div>
              <div className="text-xs text-slate-600 mb-2 font-medium">
                Atal Vayo Abhyuday Yojana (Senior Living)
              </div>
              <div className="flex items-center justify-between text-xs text-slate-500 pt-2 border-t border-slate-200">
                <span>Facilities: 1</span>
                <span>Active Roster: Active</span>
              </div>
            </div>

            {/* NAPDDR */}
            <div className="p-3.5 rounded-xl border border-slate-200 bg-slate-50/50 hover:bg-slate-50 transition-colors">
              <div className="flex items-center justify-between mb-1.5">
                <span className="text-xs font-bold text-slate-900">NAPDDR Scheme</span>
                <span className="text-[10px] font-semibold bg-purple-100 text-purple-800 px-2 py-0.5 rounded">
                  Rehabilitation
                </span>
              </div>
              <div className="text-xs text-slate-600 mb-2 font-medium">
                National Action Plan for Drug Demand Reduction
              </div>
              <div className="flex items-center justify-between text-xs text-slate-500 pt-2 border-t border-slate-200">
                <span>Facilities: 1</span>
                <span className="text-red-600 font-semibold">1 Alert Active</span>
              </div>
            </div>

            {/* PM-DAKSH */}
            <div className="p-3.5 rounded-xl border border-slate-200 bg-slate-50/50 hover:bg-slate-50 transition-colors">
              <div className="flex items-center justify-between mb-1.5">
                <span className="text-xs font-bold text-slate-900">PM-DAKSH</span>
                <span className="text-[10px] font-semibold bg-amber-100 text-amber-800 px-2 py-0.5 rounded">
                  Skill Training
                </span>
              </div>
              <div className="text-xs text-slate-600 mb-2 font-medium">
                Pradhan Mantri Dakshta Aur Kushalta Sampann
              </div>
              <div className="flex items-center justify-between text-xs text-slate-500 pt-2 border-t border-slate-200">
                <span>Vocational Batches</span>
                <span>Scheduled</span>
              </div>
            </div>
          </div>
        </div>
      </div>

      {/* Priority High Attention Institutions Table */}
      <div className="bg-white rounded-xl border border-slate-200 overflow-hidden shadow-xs">
        <div className="px-6 py-4 border-b border-slate-200 flex items-center justify-between">
          <div>
            <h3 className="font-bold text-sm text-slate-900">Priority Surveillance & Attention Registry</h3>
            <p className="text-xs text-slate-500">
              Institutions ranked by composite attention score and statistical discrepancy flags
            </p>
          </div>
          <button
            onClick={() => onNavigate('institutions')}
            className="text-xs text-indigo-600 hover:text-indigo-800 font-semibold flex items-center gap-1"
          >
            <span>Complete Registry</span>
            <ChevronRight className="w-3.5 h-3.5" />
          </button>
        </div>

        <div className="overflow-x-auto">
          <table className="w-full text-left text-xs text-slate-700">
            <thead className="bg-slate-50 text-slate-500 font-semibold border-b border-slate-200">
              <tr>
                <th className="px-6 py-3">Institution & Code</th>
                <th className="px-6 py-3">Scheme & District</th>
                <th className="px-6 py-3">Risk Score</th>
                <th className="px-6 py-3">Occupancy</th>
                <th className="px-6 py-3">CCTV Status</th>
                <th className="px-6 py-3 text-right">Actions</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-100">
              {priorityInstitutions.map(inst => {
                const isCritical = inst.risk_level === 'CRITICAL' || inst.current_risk_score >= 80;
                const isHigh = inst.risk_level === 'HIGH' || (inst.current_risk_score >= 60 && inst.current_risk_score < 80);

                return (
                  <tr key={inst.id} className="hover:bg-slate-50/80 transition-colors">
                    <td className="px-6 py-3.5">
                      <div className="font-bold text-slate-900">{inst.name}</div>
                      <div className="text-[11px] text-slate-400 font-mono">{inst.registration_code}</div>
                    </td>
                    <td className="px-6 py-3.5">
                      <div className="font-medium text-slate-800">{inst.institution_type}</div>
                      <div className="text-[11px] text-slate-500">
                        {inst.district}, {inst.state}
                      </div>
                    </td>
                    <td className="px-6 py-3.5">
                      <div className="flex items-center gap-2">
                        <span
                          className={`inline-block font-bold text-xs px-2 py-0.5 rounded border ${
                            isCritical
                              ? 'bg-red-50 text-red-700 border-red-200'
                              : isHigh
                              ? 'bg-amber-50 text-amber-700 border-amber-200'
                              : 'bg-emerald-50 text-emerald-700 border-emerald-200'
                          }`}
                        >
                          {inst.current_risk_score} / 100
                        </span>
                        <span className="text-[10px] uppercase font-semibold text-slate-400">
                          {inst.risk_level}
                        </span>
                      </div>
                    </td>
                    <td className="px-6 py-3.5">
                      <div className="font-medium text-slate-900">
                        {inst.current_occupancy} / {inst.registered_capacity}
                      </div>
                      <div className="text-[11px] text-slate-400">
                        {Math.round((inst.current_occupancy / (inst.registered_capacity || 1)) * 100)}% capacity
                      </div>
                    </td>
                    <td className="px-6 py-3.5">
                      <span
                        className={`inline-flex items-center gap-1 text-[11px] font-medium px-2 py-0.5 rounded ${
                          inst.cctv_status === 'ACTIVE'
                            ? 'bg-emerald-50 text-emerald-700'
                            : 'bg-red-50 text-red-700'
                        }`}
                      >
                        <span
                          className={`w-1.5 h-1.5 rounded-full ${
                            inst.cctv_status === 'ACTIVE' ? 'bg-emerald-500' : 'bg-red-500'
                          }`}
                        />
                        {inst.cctv_status} ({inst.cctv_streams_count} streams)
                      </span>
                    </td>
                    <td className="px-6 py-3.5 text-right space-x-2">
                      <button
                        onClick={() => onSelectInstitution(inst)}
                        className="text-xs text-slate-600 hover:text-slate-900 font-medium px-2 py-1 rounded hover:bg-slate-100"
                      >
                        Details
                      </button>
                      {canMandateInspection && (
                        <button
                          onClick={() =>
                            onMandateInspection(
                              inst.id,
                              undefined,
                              `Unannounced inspection ordered due to elevated attention score (${inst.current_risk_score}/100).`
                            )
                          }
                          className="text-xs bg-indigo-50 hover:bg-indigo-100 text-indigo-700 font-semibold px-2.5 py-1 rounded border border-indigo-200 transition-colors"
                        >
                          Mandate Audit
                        </button>
                      )}
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
};
