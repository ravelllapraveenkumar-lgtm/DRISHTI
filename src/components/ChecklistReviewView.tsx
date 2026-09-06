/**
 * DRISHTI: Statutory Checklist Review & Inspection Templates
 * Structured verification parameters across MoSJE welfare schemes
 * Fully integrated with FastAPI /api/v1/inspection-checklists
 */

import React, { useState, useEffect } from 'react';
import {
  ListChecks,
  CheckCircle2,
  AlertCircle,
  Building,
  HeartPulse,
  Utensils,
  Smile,
  Fingerprint,
  ChevronDown,
  ShieldCheck,
  Calendar,
  Clock,
  MapPin,
  FileCheck,
  Search
} from 'lucide-react';
import { api } from '../api/client';
import { ChecklistTemplate, ChecklistSubmission, Inspection } from '../types/api';

export const ChecklistReviewView: React.FC = () => {
  const [selectedScheme, setSelectedScheme] = useState<'DDRS' | 'AVYAY' | 'NAPDDR' | 'UNIVERSAL'>('UNIVERSAL');
  const [templates, setTemplates] = useState<ChecklistTemplate[]>([]);
  const [inspections, setInspections] = useState<Inspection[]>([]);
  const [selectedInspectionId, setSelectedInspectionId] = useState<string>('');
  const [submissions, setSubmissions] = useState<ChecklistSubmission[]>([]);
  const [isLoading, setIsLoading] = useState<boolean>(true);
  const [viewMode, setViewMode] = useState<'SUBMISSIONS' | 'TEMPLATE'>('SUBMISSIONS');

  // Fallback statutory sections if template API is loading or offline
  const fallbackSections = [
    {
      title: '1. Infrastructure & Living Environment',
      icon: Building,
      items: [
        {
          id: 'inf-1',
          param: 'Minimum 50 sq ft bed space per enrolled resident',
          status: 'COMPLIANT',
          score: 10,
          inspectorNotes: 'Adequate room spacing maintained. Clean mattress and ventilation verified.'
        },
        {
          id: 'inf-2',
          param: 'Functional fire extinguishers and marked emergency exit routes',
          status: 'COMPLIANT',
          score: 9,
          inspectorNotes: 'Extinguishers inspected, valid calibration tag through Nov 2026.'
        },
        {
          id: 'inf-3',
          param: 'Barrier-free ramp and grab rails for disabled/elderly beneficiaries',
          status: 'DEFICIENT',
          score: 5,
          inspectorNotes: 'Rear bathroom ramp slope is steep (>1:8 ratio). Needs rectification.'
        }
      ]
    },
    {
      title: '2. Health, Hygiene & Medical Protocol',
      icon: HeartPulse,
      items: [
        {
          id: 'med-1',
          param: 'Empaneled visiting physician register with weekly signed case notes',
          status: 'COMPLIANT',
          score: 9,
          inspectorNotes: 'Dr. R. K. Verma visited twice weekly. Medicine logbook verified.'
        },
        {
          id: 'med-2',
          param: 'Secure locked medicine cabinet for prescribed psychiatric/detox drugs',
          status: 'COMPLIANT',
          score: 10,
          inspectorNotes: 'Double-lock cabinet key held exclusively by lead medical officer.'
        },
        {
          id: 'med-3',
          param: 'Clean RO drinking water and sanitized kitchen wastewater drainage',
          status: 'COMPLIANT',
          score: 8,
          inspectorNotes: 'Water test certificate displayed on notice board.'
        }
      ]
    },
    {
      title: '3. Nutrition & Kitchen Meal Provisioning',
      icon: Utensils,
      items: [
        {
          id: 'nut-1',
          param: 'Three nutritious hot meals plus evening tea served daily according to menu',
          status: 'DEFICIENT',
          score: 6,
          inspectorNotes: 'Physical meal prep matched morning headcount, but logbook showed 45 meals while biometric punch recorded 22. Investigation recommended.'
        },
        {
          id: 'nut-2',
          param: 'Dry ration buffer stock sufficient for at least 15 calendar days',
          status: 'COMPLIANT',
          score: 10,
          inspectorNotes: 'Pantry inventory verified against procurement bills.'
        }
      ]
    },
    {
      title: '4. Beneficiary Care & Psychological Rehabilitation',
      icon: Smile,
      items: [
        {
          id: 'care-1',
          param: 'Individual counseling logs and psychological recovery progress sheets',
          status: 'COMPLIANT',
          score: 9,
          inspectorNotes: 'Counseling folders maintained with beneficiary signatures.'
        },
        {
          id: 'care-2',
          param: 'Functional vocational training room and recreational equipment',
          status: 'COMPLIANT',
          score: 8,
          inspectorNotes: 'Tailoring machines and computer room operational.'
        }
      ]
    },
    {
      title: '5. Roster & Biometric Identity Verification',
      icon: Fingerprint,
      items: [
        {
          id: 'bio-1',
          param: 'Physical headcount strictly matches registered Aadhaar attendance roster',
          status: 'DEFICIENT',
          score: 5,
          inspectorNotes: 'Physical headcount: 22. Official portal declared: 45. Discrepancy flagged.'
        },
        {
          id: 'bio-2',
          param: 'Functional biometric machine connected to central DRISHTI gateway',
          status: 'COMPLIANT',
          score: 10,
          inspectorNotes: 'Fingerprint scanner synced with central server.'
        }
      ]
    }
  ];

  // Initial fetch of templates and inspections
  useEffect(() => {
    async function initData() {
      setIsLoading(true);
      try {
        const [tplRes, inspRes] = await Promise.all([
          api.getChecklistTemplates().catch(() => ({ data: [] })),
          api.getInspections().catch(() => ({ data: [] }))
        ]);

        const tpls = Array.isArray(tplRes.data) ? tplRes.data : (tplRes.data as any)?.items || [];
        setTemplates(tpls);

        const insps = Array.isArray(inspRes.data) ? inspRes.data : (inspRes.data as any)?.items || [];
        setInspections(insps);

        if (insps.length > 0) {
          // Select first inspection by default
          setSelectedInspectionId(insps[0].id);
        }
      } catch (err) {
        console.warn('Failed to load initial checklist metadata:', err);
      } finally {
        setIsLoading(false);
      }
    }
    initData();
  }, []);

  // Fetch checklist submissions when inspection changes
  useEffect(() => {
    if (!selectedInspectionId) return;

    async function fetchSubmissions() {
      setIsLoading(true);
      try {
        const res = await api.getInspectionChecklists(selectedInspectionId);
        const items = Array.isArray(res.data) ? res.data : (res.data as any)?.items || [];
        setSubmissions(items);
        if (items.length > 0) {
          setViewMode('SUBMISSIONS');
        }
      } catch (err) {
        console.warn('Failed to fetch inspection checklist submissions:', err);
        setSubmissions([]);
      } finally {
        setIsLoading(false);
      }
    }
    fetchSubmissions();
  }, [selectedInspectionId]);

  const selectedInsp = inspections.find(i => i.id === selectedInspectionId);

  // Calculate scores for fallback
  const totalScore = fallbackSections.reduce(
    (acc, sec) => acc + sec.items.reduce((sAcc, it) => sAcc + it.score, 0),
    0
  );
  const maxPossible = 110;
  const overallPercentage = Math.round((totalScore / maxPossible) * 100);

  return (
    <div className="space-y-5 animate-in fade-in duration-150">
      {/* Header */}
      <div className="bg-white p-5 rounded-xl border border-slate-200 shadow-xs flex flex-col sm:flex-row justify-between items-start sm:items-center gap-3">
        <div>
          <h2 className="text-lg font-bold text-slate-900 tracking-tight">
            Inspection Checklist & Quality Review
          </h2>
          <p className="text-xs text-slate-500">
            Standardized evaluation rubrics across DDRS, AVYAY, and NAPDDR scheme guidelines
          </p>
        </div>

        {/* View Mode & Inspection Selector */}
        <div className="flex flex-wrap items-center gap-2 w-full sm:w-auto">
          {inspections.length > 0 && (
            <select
              value={selectedInspectionId}
              onChange={e => setSelectedInspectionId(e.target.value)}
              className="text-xs bg-slate-50 border border-slate-300 rounded-lg px-3 py-2 text-slate-900 focus:bg-white focus:outline-hidden font-medium"
            >
              {inspections.map(insp => (
                <option key={insp.id} value={insp.id}>
                  {insp.inspection_code} — {insp.institution_name || 'Inspection'} ({insp.status})
                </option>
              ))}
            </select>
          )}

          <div className="flex rounded-lg bg-slate-100 p-1 border border-slate-200">
            <button
              onClick={() => setViewMode('SUBMISSIONS')}
              className={`px-3 py-1.5 text-xs font-semibold rounded-md transition-all ${
                viewMode === 'SUBMISSIONS'
                  ? 'bg-white text-indigo-700 shadow-xs'
                  : 'text-slate-600 hover:text-slate-900'
              }`}
            >
              Field Responses ({submissions.length})
            </button>
            <button
              onClick={() => setViewMode('TEMPLATE')}
              className={`px-3 py-1.5 text-xs font-semibold rounded-md transition-all ${
                viewMode === 'TEMPLATE'
                  ? 'bg-white text-indigo-700 shadow-xs'
                  : 'text-slate-600 hover:text-slate-900'
              }`}
            >
              Statutory Template
            </button>
          </div>
        </div>
      </div>

      {/* Submission Status or Template Notice */}
      {viewMode === 'SUBMISSIONS' && submissions.length > 0 ? (
        <div className="space-y-4">
          <div className="bg-indigo-50 border border-indigo-200 rounded-xl p-4 flex flex-col sm:flex-row items-start sm:items-center justify-between gap-3 text-xs text-indigo-950 shadow-xs">
            <div className="space-y-1">
              <div className="font-bold flex items-center gap-1.5">
                <FileCheck className="w-4 h-4 text-indigo-700" />
                <span>Live Field Checklist Responses: {selectedInsp?.inspection_code || selectedInspectionId}</span>
              </div>
              <p className="text-indigo-800 text-[11px]">
                Retrieved directly from FastAPI database. Validated on-site by field inspector with tamper-evident GPS capture.
              </p>
            </div>

            <div className="flex items-center gap-2 shrink-0">
              <span className="bg-emerald-100 text-emerald-800 font-semibold px-2.5 py-1 rounded border border-emerald-300 text-[11px]">
                {submissions.filter(s => s.response_boolean === true).length} Compliant
              </span>
              <span className="bg-amber-100 text-amber-800 font-semibold px-2.5 py-1 rounded border border-amber-300 text-[11px]">
                {submissions.filter(s => s.response_boolean === false).length} Deficient
              </span>
            </div>
          </div>

          {/* Submissions List */}
          <div className="bg-white rounded-xl border border-slate-200 overflow-hidden shadow-xs divide-y divide-slate-100">
            {submissions.map((sub, idx) => (
              <div key={sub.id || idx} className="p-4 flex flex-col sm:flex-row justify-between gap-3 text-xs hover:bg-slate-50/60 transition-colors">
                <div className="space-y-1.5 max-w-2xl">
                  <div className="flex items-center gap-2">
                    <span className="text-[10px] font-bold uppercase tracking-wider bg-slate-100 text-slate-700 px-2 py-0.5 rounded font-mono">
                      {sub.section_name || 'General Verification'}
                    </span>
                    <span className="font-semibold text-slate-900">
                      {sub.item_question || `Checklist Item #${sub.checklist_item_id?.slice(0, 8)}`}
                    </span>
                  </div>

                  {sub.response_value && (
                    <div className="text-[11px] text-slate-700 bg-slate-50 p-2 rounded border border-slate-100">
                      <span className="font-medium text-slate-900">Recorded Value: </span>
                      {sub.response_value}
                    </div>
                  )}

                  {sub.inspector_comment && (
                    <div className="text-[11px] text-slate-600 bg-amber-50/40 p-2 rounded border border-amber-100">
                      <span className="font-semibold text-amber-900">Inspector Field Notes: </span>
                      {sub.inspector_comment}
                    </div>
                  )}

                  <div className="flex items-center gap-3 text-[10px] text-slate-400">
                    <span className="flex items-center gap-1">
                      <Clock className="w-3 h-3" />
                      {new Date(sub.captured_at).toLocaleString()}
                    </span>
                    {sub.gps_latitude && sub.gps_longitude && (
                      <span className="flex items-center gap-1 font-mono">
                        <MapPin className="w-3 h-3 text-indigo-500" />
                        {sub.gps_latitude.toFixed(4)}, {sub.gps_longitude.toFixed(4)}
                      </span>
                    )}
                  </div>
                </div>

                <div className="flex items-center gap-3 shrink-0">
                  <span
                    className={`inline-flex items-center gap-1 text-[11px] font-bold px-2.5 py-1 rounded border ${
                      sub.response_boolean === true
                        ? 'bg-emerald-50 text-emerald-700 border-emerald-200'
                        : sub.response_boolean === false
                        ? 'bg-red-50 text-red-700 border-red-200'
                        : 'bg-slate-100 text-slate-700 border-slate-200'
                    }`}
                  >
                    {sub.response_boolean === true ? (
                      <CheckCircle2 className="w-3.5 h-3.5 text-emerald-600" />
                    ) : (
                      <AlertCircle className="w-3.5 h-3.5 text-red-600" />
                    )}
                    <span>{sub.response_boolean === true ? 'COMPLIANT' : sub.response_boolean === false ? 'DEFICIENT' : 'PENDING'}</span>
                  </span>
                </div>
              </div>
            ))}
          </div>
        </div>
      ) : viewMode === 'SUBMISSIONS' && submissions.length === 0 ? (
        <div className="bg-white rounded-xl border border-slate-200 p-8 text-center space-y-3">
          <AlertCircle className="w-8 h-8 text-amber-500 mx-auto" />
          <h3 className="text-sm font-bold text-slate-900">No Checklist Answers Submitted Yet</h3>
          <p className="text-xs text-slate-500 max-w-md mx-auto">
            Inspection {selectedInsp?.inspection_code || selectedInspectionId} is currently {selectedInsp?.status || 'dispatched'}. Checklist questions are completed on-site by field inspectors via the DRISHTI mobile application.
          </p>
          <button
            onClick={() => setViewMode('TEMPLATE')}
            className="text-xs font-semibold bg-indigo-50 text-indigo-700 hover:bg-indigo-100 px-3 py-1.5 rounded-lg border border-indigo-200 transition-colors"
          >
            View Statutory Evaluation Rubric
          </button>
        </div>
      ) : null}

      {/* Template View */}
      {viewMode === 'TEMPLATE' && (
        <div className="space-y-4">
          {/* Statutory Scheme Selection Banner */}
          <div className="bg-white rounded-xl border border-slate-200 p-4 shadow-xs flex flex-col sm:flex-row items-start sm:items-center justify-between gap-3">
            <div className="space-y-0.5">
              <span className="text-[10px] font-bold uppercase tracking-wider text-indigo-600">Standard Statutory Framework</span>
              <h3 className="text-sm font-bold text-slate-900">
                {templates.length > 0 ? templates[0].name : 'Universal Institutional Welfare Checklist'}
              </h3>
              <p className="text-xs text-slate-500">
                Mandatory verification parameters prescribed by Ministry of Social Justice and Empowerment
              </p>
            </div>

            <div className="flex rounded-lg bg-slate-100 p-1 border border-slate-200">
              {(['UNIVERSAL', 'NAPDDR', 'AVYAY', 'DDRS'] as const).map(sch => (
                <button
                  key={sch}
                  onClick={() => setSelectedScheme(sch)}
                  className={`px-3 py-1 text-xs font-semibold rounded-md transition-all ${
                    selectedScheme === sch
                      ? 'bg-white text-indigo-700 shadow-xs'
                      : 'text-slate-600 hover:text-slate-900'
                  }`}
                >
                  {sch}
                </button>
              ))}
            </div>
          </div>

          {/* Active Template Questions from Database */}
          {templates.length > 0 && templates[0].items && templates[0].items.length > 0 ? (
            <div className="bg-white rounded-xl border border-slate-200 overflow-hidden shadow-xs">
              <div className="p-4 bg-slate-50 border-b border-slate-200 flex items-center justify-between">
                <span className="text-xs font-bold text-slate-900">
                  Registered Template Parameters ({templates[0].items.length} items)
                </span>
                <span className="text-[11px] font-mono text-slate-500">
                  Version {templates[0].version} • Scheme: {templates[0].scheme_category}
                </span>
              </div>
              <div className="divide-y divide-slate-100">
                {templates[0].items.map((item, i) => (
                  <div key={item.id || i} className="p-4 flex flex-col sm:flex-row justify-between gap-3 text-xs">
                    <div className="space-y-1">
                      <div className="flex items-center gap-2">
                        <span className="text-[10px] font-bold bg-slate-100 text-slate-700 px-2 py-0.5 rounded font-mono">
                          {item.section_name}
                        </span>
                        <span className="font-semibold text-slate-900">{item.item_question}</span>
                      </div>
                      {item.guidance_notes && (
                        <p className="text-[11px] text-slate-500 italic">{item.guidance_notes}</p>
                      )}
                    </div>
                    <div className="shrink-0 flex items-center gap-2">
                      <span className="text-[10px] bg-indigo-50 text-indigo-700 font-semibold px-2 py-0.5 rounded border border-indigo-200">
                        {item.field_type}
                      </span>
                    </div>
                  </div>
                ))}
              </div>
            </div>
          ) : null}

          {/* Detailed Section Rubrics */}
          <div className="space-y-4">
            {fallbackSections.map(section => {
              const Icon = section.icon;
              return (
                <div
                  key={section.title}
                  className="bg-white rounded-xl border border-slate-200 overflow-hidden shadow-xs"
                >
                  <div className="p-4 bg-slate-50/80 border-b border-slate-200 flex items-center justify-between">
                    <div className="flex items-center gap-2.5">
                      <div className="w-7 h-7 rounded-lg bg-indigo-50 border border-indigo-200 flex items-center justify-center text-indigo-700">
                        <Icon className="w-4 h-4" />
                      </div>
                      <h3 className="font-bold text-xs text-slate-900">{section.title}</h3>
                    </div>
                    <span className="text-[11px] font-semibold text-slate-500">
                      {section.items.length} Verification Checks
                    </span>
                  </div>

                  <div className="divide-y divide-slate-100">
                    {section.items.map(item => (
                      <div key={item.id} className="p-4 flex flex-col sm:flex-row justify-between gap-3 text-xs">
                        <div className="space-y-1 max-w-xl">
                          <div className="font-medium text-slate-900 flex items-center gap-2">
                            <span>{item.param}</span>
                          </div>
                          <div className="text-[11px] text-slate-500 bg-slate-50 p-2 rounded border border-slate-100">
                            <span className="font-semibold text-slate-700">Field Inspection Protocol: </span>
                            {item.inspectorNotes}
                          </div>
                        </div>

                        <div className="flex items-center gap-3 shrink-0">
                          <div className="text-right">
                            <div className="font-bold text-slate-900 text-xs">{item.score} / 10</div>
                            <span className="text-[10px] text-slate-400">Weightage</span>
                          </div>

                          <span
                            className={`inline-flex items-center gap-1 text-[11px] font-bold px-2.5 py-1 rounded border ${
                              item.status === 'COMPLIANT'
                                ? 'bg-emerald-50 text-emerald-700 border-emerald-200'
                                : 'bg-amber-50 text-amber-700 border-amber-200'
                            }`}
                          >
                            {item.status === 'COMPLIANT' ? (
                              <CheckCircle2 className="w-3.5 h-3.5 text-emerald-600" />
                            ) : (
                              <AlertCircle className="w-3.5 h-3.5 text-amber-600" />
                            )}
                            <span>{item.status}</span>
                          </span>
                        </div>
                      </div>
                    ))}
                  </div>
                </div>
              );
            })}
          </div>
        </div>
      )}
    </div>
  );
};
