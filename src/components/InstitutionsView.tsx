/**
 * DRISHTI: Institutions & Monitoring Directory
 * Filterable registry of MoSJE grantee institutions with geofence and risk metrics
 */

import React, { useState } from 'react';
import {
  Building2,
  Search,
  Filter,
  MapPin,
  Phone,
  Mail,
  User,
  ShieldAlert,
  CheckCircle2,
  AlertTriangle,
  Radio,
  ExternalLink,
  PlusCircle,
  X,
  Layers,
  ChevronRight
} from 'lucide-react';
import { Institution } from '../types/api';
import { useAuth } from '../context/AuthContext';

interface InstitutionsViewProps {
  institutions: Institution[];
  onMandateInspection: (instId?: string, alertId?: string, defaultReason?: string) => void;
  onNavigateToMonitoring: (instId: string) => void;
}

export const InstitutionsView: React.FC<InstitutionsViewProps> = ({
  institutions,
  onMandateInspection,
  onNavigateToMonitoring
}) => {
  const { canMandateInspection } = useAuth();
  const [searchQuery, setSearchQuery] = useState('');
  const [schemeFilter, setSchemeFilter] = useState('ALL');
  const [riskFilter, setRiskFilter] = useState('ALL');
  const [selectedInst, setSelectedInst] = useState<Institution | null>(null);

  const instList = Array.isArray(institutions) ? institutions : (institutions as any)?.items || [];

  const filteredInstitutions = instList.filter(inst => {
    const matchesSearch =
      inst.name.toLowerCase().includes(searchQuery.toLowerCase()) ||
      inst.registration_code.toLowerCase().includes(searchQuery.toLowerCase()) ||
      inst.district.toLowerCase().includes(searchQuery.toLowerCase());

    const matchesScheme =
      schemeFilter === 'ALL' ||
      inst.institution_type.toLowerCase().includes(schemeFilter.toLowerCase()) ||
      (inst.primary_scheme_name && inst.primary_scheme_name.toLowerCase().includes(schemeFilter.toLowerCase()));

    const matchesRisk = riskFilter === 'ALL' || inst.risk_level === riskFilter;

    return matchesSearch && matchesScheme && matchesRisk;
  });

  return (
    <div className="space-y-5 animate-in fade-in duration-150">
      {/* Top Header & Stats */}
      <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-3 bg-white p-5 rounded-xl border border-slate-200 shadow-xs">
        <div>
          <h2 className="text-lg font-bold text-slate-900 tracking-tight">Institutions Registry</h2>
          <p className="text-xs text-slate-500">
            Registered grantee organizations, rehabilitation centers, and senior living facilities under MoSJE
          </p>
        </div>
        {canMandateInspection && (
          <button
            onClick={() => onMandateInspection()}
            className="bg-indigo-600 hover:bg-indigo-700 text-white text-xs font-semibold px-4 py-2 rounded-lg flex items-center gap-1.5 shadow-xs transition-colors"
          >
            <PlusCircle className="w-4 h-4" />
            <span>Mandate Inspection</span>
          </button>
        )}
      </div>

      {/* Filter & Search Bar */}
      <div className="bg-white p-4 rounded-xl border border-slate-200 shadow-xs space-y-3">
        <div className="grid grid-cols-1 sm:grid-cols-4 gap-3">
          {/* Search */}
          <div className="sm:col-span-2 relative">
            <Search className="w-4 h-4 text-slate-400 absolute left-3 top-2.5" />
            <input
              type="text"
              placeholder="Search by institution name, code, or district..."
              value={searchQuery}
              onChange={e => setSearchQuery(e.target.value)}
              className="w-full text-xs pl-9 pr-3 py-2 bg-slate-50 border border-slate-300 rounded-lg focus:bg-white focus:outline-hidden focus:ring-2 focus:ring-indigo-500 text-slate-900"
            />
          </div>

          {/* Scheme Filter */}
          <div>
            <select
              value={schemeFilter}
              onChange={e => setSchemeFilter(e.target.value)}
              className="w-full text-xs px-3 py-2 bg-slate-50 border border-slate-300 rounded-lg focus:bg-white focus:outline-hidden focus:ring-2 focus:ring-indigo-500 text-slate-800"
            >
              <option value="ALL">All Schemes</option>
              <option value="DDRS">DDRS (Disability)</option>
              <option value="AVYAY">AVYAY (Senior Citizens)</option>
              <option value="NAPDDR">NAPDDR (Rehabilitation)</option>
              <option value="PM-DAKSH">PM-DAKSH (Skill Training)</option>
            </select>
          </div>

          {/* Risk Filter */}
          <div>
            <select
              value={riskFilter}
              onChange={e => setRiskFilter(e.target.value)}
              className="w-full text-xs px-3 py-2 bg-slate-50 border border-slate-300 rounded-lg focus:bg-white focus:outline-hidden focus:ring-2 focus:ring-indigo-500 text-slate-800"
            >
              <option value="ALL">All Risk Tiers</option>
              <option value="CRITICAL">Critical Attention (80-100)</option>
              <option value="HIGH">High Risk (60-79)</option>
              <option value="MEDIUM">Medium Risk (30-59)</option>
              <option value="LOW">Low Risk (0-29)</option>
            </select>
          </div>
        </div>
      </div>

      {/* Grid of Institution Cards */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
        {filteredInstitutions.length === 0 ? (
          <div className="col-span-full text-center py-12 bg-white rounded-xl border border-slate-200 text-slate-400 text-xs">
            No institutions found matching the selected filters.
          </div>
        ) : (
          filteredInstitutions.map(inst => {
            const isCritical = inst.risk_level === 'CRITICAL' || inst.current_risk_score >= 80;
            const isHigh = inst.risk_level === 'HIGH' || (inst.current_risk_score >= 60 && inst.current_risk_score < 80);

            return (
              <div
                key={inst.id}
                className="bg-white rounded-xl border border-slate-200 hover:border-indigo-300 transition-all shadow-xs p-5 flex flex-col justify-between"
              >
                <div>
                  {/* Top Tags */}
                  <div className="flex items-center justify-between gap-2 mb-2">
                    <span className="text-[10px] font-mono font-semibold text-slate-500 bg-slate-100 px-2 py-0.5 rounded">
                      {inst.registration_code}
                    </span>
                    <span
                      className={`text-[10px] font-bold px-2 py-0.5 rounded border ${
                        isCritical
                          ? 'bg-red-50 text-red-700 border-red-200'
                          : isHigh
                          ? 'bg-amber-50 text-amber-700 border-amber-200'
                          : 'bg-emerald-50 text-emerald-700 border-emerald-200'
                      }`}
                    >
                      Risk: {inst.current_risk_score}/100 • {inst.risk_level}
                    </span>
                  </div>

                  {/* Title */}
                  <h3 className="font-bold text-sm text-slate-900 line-clamp-1 mb-1">{inst.name}</h3>
                  <div className="text-xs text-indigo-700 font-medium mb-3">
                    {inst.institution_type.replace(/_/g, ' ')}
                  </div>

                  {/* Info points */}
                  <div className="space-y-1.5 text-xs text-slate-600 mb-4">
                    <div className="flex items-center gap-1.5 text-[11px]">
                      <MapPin className="w-3.5 h-3.5 text-slate-400 shrink-0" />
                      <span className="line-clamp-1">
                        {inst.district}, {inst.state} (Pincode: {inst.pincode})
                      </span>
                    </div>
                    <div className="flex items-center gap-1.5 text-[11px]">
                      <User className="w-3.5 h-3.5 text-slate-400 shrink-0" />
                      <span>
                        {inst.contact_person_name} • {inst.contact_phone}
                      </span>
                    </div>
                    <div className="flex items-center gap-1.5 text-[11px]">
                      <Radio className="w-3.5 h-3.5 text-slate-400 shrink-0" />
                      <span>
                        Geofence Radius: {inst.geofence_radius_meters}m • CCTV: {inst.cctv_status} (
                        {inst.cctv_streams_count} streams)
                      </span>
                    </div>
                  </div>

                  {/* Capacity Bar */}
                  <div className="bg-slate-50 p-2.5 rounded-lg border border-slate-100 text-xs mb-4">
                    <div className="flex justify-between text-[11px] font-medium text-slate-700 mb-1">
                      <span>Occupancy / Sanctioned</span>
                      <span className="font-bold">
                        {inst.current_occupancy} / {inst.registered_capacity} (
                        {Math.round((inst.current_occupancy / (inst.registered_capacity || 1)) * 100)}%)
                      </span>
                    </div>
                    <div className="w-full bg-slate-200 rounded-full h-1.5 overflow-hidden">
                      <div
                        className="bg-indigo-600 h-1.5 rounded-full"
                        style={{
                          width: `${Math.min(
                            100,
                            (inst.current_occupancy / (inst.registered_capacity || 1)) * 100
                          )}%`
                        }}
                      />
                    </div>
                  </div>
                </div>

                {/* Bottom Actions */}
                <div className="pt-3 border-t border-slate-100 flex items-center justify-between gap-2">
                  <button
                    onClick={() => setSelectedInst(inst)}
                    className="text-xs text-slate-700 hover:text-slate-900 font-medium px-3 py-1.5 rounded-lg hover:bg-slate-100 transition-colors"
                  >
                    View Details
                  </button>

                  {canMandateInspection && (
                    <button
                      onClick={() =>
                        onMandateInspection(
                          inst.id,
                          undefined,
                          `Unannounced inspection ordered for ${inst.name} (${inst.registration_code}).`
                        )
                      }
                      className="text-xs font-semibold bg-indigo-50 hover:bg-indigo-100 text-indigo-700 px-3 py-1.5 rounded-lg border border-indigo-200 transition-colors"
                    >
                      Mandate Inspection
                    </button>
                  )}
                </div>
              </div>
            );
          })
        )}
      </div>

      {/* Institution Details Drawer / Modal */}
      {selectedInst && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-slate-900/60 backdrop-blur-xs animate-in fade-in">
          <div className="bg-white rounded-2xl shadow-2xl border border-slate-200 w-full max-w-2xl overflow-hidden">
            <div className="px-6 py-4 bg-[#0F172A] text-white flex items-center justify-between border-b border-slate-800">
              <div>
                <h3 className="font-bold text-sm text-white">{selectedInst.name}</h3>
                <p className="text-[11px] text-slate-400 font-mono">{selectedInst.registration_code}</p>
              </div>
              <button
                onClick={() => setSelectedInst(null)}
                className="text-slate-400 hover:text-white p-1 rounded-lg"
              >
                <X className="w-5 h-5" />
              </button>
            </div>

            <div className="p-6 space-y-4 max-h-[75vh] overflow-y-auto text-xs text-slate-700">
              {/* Address & GPS */}
              <div className="bg-slate-50 p-3.5 rounded-xl border border-slate-200 space-y-1.5">
                <div className="font-bold text-slate-900 text-xs">Geographical & Facility Location</div>
                <div>
                  <span className="text-slate-500">Address: </span>
                  {selectedInst.address}
                </div>
                <div className="flex gap-4">
                  <span>
                    <span className="text-slate-500">Coordinates: </span>
                    {selectedInst.latitude != null && selectedInst.longitude != null
                      ? `${Number(selectedInst.latitude).toFixed(4)}, ${Number(selectedInst.longitude).toFixed(4)}`
                      : 'Geotagging Pending'}
                  </span>
                  <span>
                    <span className="text-slate-500">Geofence Radius: </span>
                    {selectedInst.geofence_radius_meters} meters
                  </span>
                </div>
              </div>

              {/* Scheme & Contact */}
              <div className="grid grid-cols-2 gap-3">
                <div className="p-3 bg-slate-50 rounded-xl border border-slate-200">
                  <div className="font-bold text-slate-900 text-xs mb-1">Scheme Affiliation</div>
                  <div className="text-slate-600">{selectedInst.institution_type}</div>
                  <div className="text-[11px] text-slate-500 mt-1">Status: Verified Grantee</div>
                </div>

                <div className="p-3 bg-slate-50 rounded-xl border border-slate-200">
                  <div className="font-bold text-slate-900 text-xs mb-1">Contact Authority</div>
                  <div className="text-slate-800 font-medium">{selectedInst.contact_person_name}</div>
                  <div className="text-[11px] text-slate-500">{selectedInst.contact_phone}</div>
                  <div className="text-[11px] text-slate-500">{selectedInst.contact_email}</div>
                </div>
              </div>

              {/* Risk Breakdown */}
              <div className="p-4 rounded-xl border border-indigo-100 bg-indigo-50/50">
                <div className="flex items-center justify-between mb-1.5">
                  <span className="font-bold text-slate-900 text-xs">Algorithmic Attention Assessment</span>
                  <span className="font-bold text-indigo-700">Score: {selectedInst.current_risk_score} / 100</span>
                </div>
                <p className="text-[11px] text-slate-600 leading-relaxed">
                  Composite attention score calculated across 4 features: 30-day attendance standard deviation,
                  biometric vs declared divergence, kitchen meal count discrepancy, and CCTV uptime consistency.
                </p>
              </div>

              {/* Action Buttons */}
              <div className="pt-3 border-t border-slate-200 flex justify-end gap-2">
                <button
                  onClick={() => {
                    setSelectedInst(null);
                    onNavigateToMonitoring(selectedInst.id);
                  }}
                  className="px-4 py-2 text-xs font-semibold text-slate-700 bg-slate-100 hover:bg-slate-200 rounded-lg transition-colors"
                >
                  View Telemetry Logs
                </button>

                {canMandateInspection && (
                  <button
                    onClick={() => {
                      const id = selectedInst.id;
                      setSelectedInst(null);
                      onMandateInspection(id, undefined, `Mandated inspection for ${selectedInst.name}`);
                    }}
                    className="px-4 py-2 text-xs font-semibold text-white bg-indigo-600 hover:bg-indigo-700 rounded-lg transition-colors shadow-xs"
                  >
                    Mandate Inspection Directive
                  </button>
                )}
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};
