/**
 * DRISHTI: Inspection Reports & Official Review Workflow
 * Headcount audit reconciliation, quality scorecards, and administrative sanctions
 */

import React, { useState, useEffect } from 'react';
import {
  FileText,
  CheckCircle2,
  AlertTriangle,
  Send,
  Building2,
  Calendar,
  User,
  Star,
  Shield,
  Clock,
  X
} from 'lucide-react';
import { api } from '../api/client';
import { InspectionReport, ReportStatus, ActionTakenType } from '../types/api';
import { useAuth } from '../context/AuthContext';

export const ReportsReviewView: React.FC = () => {
  const { canReviewReports } = useAuth();
  const [reports, setReports] = useState<InspectionReport[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [selectedReport, setSelectedReport] = useState<InspectionReport | null>(null);

  // Review modal state
  const [reviewStatus, setReviewStatus] = useState<ReportStatus>('REVIEWED_ACCEPTED');
  const [actionType, setActionType] = useState<ActionTakenType>('SHOW_CAUSE_NOTICE');
  const [reviewNotes, setReviewNotes] = useState('');
  const [isSubmittingReview, setIsSubmittingReview] = useState(false);

  const fetchReports = async () => {
    setIsLoading(true);
    try {
      const res = await api.getReports();
      const items = Array.isArray(res.data) ? res.data : (res.data as any)?.items || [];
      setReports(items);
    } catch (err) {
      console.warn('Failed to load reports:', err);
    } finally {
      setIsLoading(false);
    }
  };

  useEffect(() => {
    fetchReports();
  }, []);

  const handleReviewSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!selectedReport) return;

    setIsSubmittingReview(true);
    try {
      await api.reviewReport(selectedReport.id, {
        status: reviewStatus,
        official_review_notes: reviewNotes || 'Reviewed and validated by authorized Ministry / District Official.',
        action_taken_type: actionType
      });
      setSelectedReport(null);
      setReviewNotes('');
      await fetchReports();
    } catch (err: any) {
      alert(err.message || 'Failed to submit official review');
    } finally {
      setIsSubmittingReview(false);
    }
  };

  const getStatusBadge = (status: ReportStatus) => {
    switch (status) {
      case 'REVIEWED_ACCEPTED':
        return 'bg-emerald-50 text-emerald-700 border-emerald-200';
      case 'ACTION_INITIATED':
        return 'bg-red-50 text-red-700 border-red-200';
      case 'RE_INSPECTION_ORDERED':
        return 'bg-amber-50 text-amber-700 border-amber-200';
      default:
        return 'bg-indigo-50 text-indigo-700 border-indigo-200';
    }
  };

  return (
    <div className="space-y-5 animate-in fade-in duration-150">
      {/* Header */}
      <div className="bg-white p-5 rounded-xl border border-slate-200 shadow-xs flex flex-col sm:flex-row justify-between items-start sm:items-center gap-3">
        <div>
          <h2 className="text-lg font-bold text-slate-900 tracking-tight">
            Inspection Field Reports & Official Review
          </h2>
          <p className="text-xs text-slate-500">
            Inspector findings, physical headcount audits, statutory compliance ratings, and official action orders
          </p>
        </div>
      </div>

      {/* Reports Grid */}
      <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
        {(!Array.isArray(reports) || reports.length === 0) ? (
          <div className="col-span-full text-center py-12 bg-white rounded-xl border border-slate-200 text-slate-400 text-xs">
            {isLoading ? 'Loading inspection reports...' : 'No reports submitted currently.'}
          </div>
        ) : (
          reports.map(rep => {
            const reported = rep.reported_headcount ?? (rep.physical_beneficiary_count + (rep.roster_discrepancy_count || 0));
            const physical = rep.physical_headcount ?? rep.physical_beneficiary_count;
            const headcountDiff = reported - physical;
            const hasHeadcountMismatch = headcountDiff > 0;
            const currentStatus = rep.status || rep.official_review_status || 'REVIEWED_ACCEPTED';
            const submittedDate = rep.submitted_at || rep.submission_timestamp || rep.created_at;

            return (
              <div
                key={rep.id}
                className="bg-white rounded-xl border border-slate-200 p-5 shadow-xs flex flex-col justify-between space-y-4"
              >
                <div>
                  {/* Top Bar */}
                  <div className="flex items-center justify-between gap-2 mb-2">
                    <span className="text-[10px] font-mono font-bold text-slate-500 bg-slate-100 px-2 py-0.5 rounded">
                      Report #{rep.id.slice(0, 8)}
                    </span>
                    <span
                      className={`text-[10px] font-bold px-2 py-0.5 rounded border ${getStatusBadge(
                        currentStatus
                      )}`}
                    >
                      {currentStatus.replace(/_/g, ' ')}
                    </span>
                  </div>

                  <h3 className="font-bold text-sm text-slate-900 mb-1">
                    {rep.institution_name || 'MoSJE Grantee Facility'}
                  </h3>
                  <div className="text-xs text-slate-500 mb-3 flex items-center gap-1.5">
                    <User className="w-3.5 h-3.5 text-slate-400" />
                    <span>Submitted by {rep.inspector_name || 'Empaneled Inspector'}</span>
                    <span>•</span>
                    <Clock className="w-3.5 h-3.5 text-slate-400" />
                    <span>{new Date(submittedDate).toLocaleDateString()}</span>
                  </div>

                  {/* Physical Headcount Reconciliation Box */}
                  <div className="bg-slate-50 rounded-xl p-3 border border-slate-200 text-xs mb-3">
                    <div className="text-[11px] font-bold text-slate-700 mb-1.5">
                      On-Site Physical Headcount Reconciliation
                    </div>
                    <div className="grid grid-cols-2 gap-2 text-xs">
                      <div>
                        <span className="text-slate-500 text-[11px]">Portal Declared: </span>
                        <span className="font-bold text-slate-900">{reported}</span>
                      </div>
                      <div>
                        <span className="text-slate-500 text-[11px]">Physical Count: </span>
                        <span className="font-bold text-emerald-700">{physical}</span>
                      </div>
                    </div>
                    {hasHeadcountMismatch && (
                      <div className="mt-2 text-[11px] text-red-700 bg-red-50 p-1.5 rounded border border-red-200 font-medium">
                        ⚠️ Discrepancy: {headcountDiff} beneficiaries declared on portal were not physically present on site.
                      </div>
                    )}
                  </div>

                  {/* Scorecard Metrics */}
                  <div className="grid grid-cols-3 gap-2 text-center text-xs mb-3">
                    <div className="p-2 bg-slate-50 rounded-lg border border-slate-100">
                      <span className="text-[10px] text-slate-400 block">Cleanliness</span>
                      <span className="font-bold text-slate-900">{rep.cleanliness_rating ?? rep.cleanliness_score ?? 8} / 10</span>
                    </div>
                    <div className="p-2 bg-slate-50 rounded-lg border border-slate-100">
                      <span className="text-[10px] text-slate-400 block">Nutrition</span>
                      <span className="font-bold text-slate-900">{rep.nutrition_rating ?? rep.food_nutrition_score ?? 7} / 10</span>
                    </div>
                    <div className="p-2 bg-slate-50 rounded-lg border border-slate-100">
                      <span className="text-[10px] text-slate-400 block">Infrastructure</span>
                      <span className="font-bold text-slate-900">{rep.infrastructure_rating ?? rep.infrastructure_condition_score ?? 8} / 10</span>
                    </div>
                  </div>

                  {/* Executive Findings */}
                  <div className="text-xs text-slate-600 line-clamp-3 leading-relaxed mb-2">
                    <span className="font-bold text-slate-800">Inspector Findings: </span>
                    {rep.findings_summary || rep.inspector_summary}
                  </div>
                </div>

                {/* Official Actions */}
                <div className="pt-3 border-t border-slate-100 flex items-center justify-between">
                  <span className="text-[11px] text-slate-400">
                    Inspection #{rep.inspection_id.slice(0, 8)}
                  </span>

                  {canReviewReports && (
                    <button
                      onClick={() => {
                        setSelectedReport(rep);
                        setReviewStatus(currentStatus === 'SUBMITTED' ? 'REVIEWED_ACCEPTED' : currentStatus);
                        setReviewNotes(rep.official_decision_notes || rep.official_review_notes || '');
                      }}
                      className="text-xs font-semibold bg-indigo-600 hover:bg-indigo-700 text-white px-3 py-1.5 rounded-lg transition-colors shadow-xs"
                    >
                      Official Review & Decision
                    </button>
                  )}
                </div>
              </div>
            );
          })
        )}
      </div>

      {/* Official Review Modal */}
      {selectedReport && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-slate-900/60 backdrop-blur-xs animate-in fade-in">
          <div className="bg-white rounded-2xl shadow-2xl border border-slate-200 w-full max-w-xl overflow-hidden">
            <div className="px-6 py-4 bg-[#0F172A] text-white flex items-center justify-between border-b border-slate-800">
              <h3 className="font-bold text-sm text-white">
                Official Report Adjudication & Directive
              </h3>
              <button
                onClick={() => setSelectedReport(null)}
                className="text-slate-400 hover:text-white p-1 rounded-lg"
              >
                <X className="w-5 h-5" />
              </button>
            </div>

            <form onSubmit={handleReviewSubmit} className="p-6 space-y-4 text-xs">
              <div>
                <label className="block font-semibold text-slate-700 mb-1">
                  Adjudication Verdict <span className="text-red-500">*</span>
                </label>
                <select
                  value={reviewStatus}
                  onChange={e => setReviewStatus(e.target.value as ReportStatus)}
                  className="w-full text-xs p-2.5 bg-slate-50 border border-slate-300 rounded-lg text-slate-900 font-semibold"
                >
                  <option value="REVIEWED_ACCEPTED">REVIEWED & ACCEPTED (No Irregularity)</option>
                  <option value="ACTION_INITIATED">ACTION INITIATED (Sanctions / Notice Mandated)</option>
                  <option value="RE_INSPECTION_ORDERED">RE-INSPECTION ORDERED (Independent Cadre)</option>
                </select>
              </div>

              {reviewStatus === 'ACTION_INITIATED' && (
                <div>
                  <label className="block font-semibold text-slate-700 mb-1">
                    Administrative Action Type
                  </label>
                  <select
                    value={actionType}
                    onChange={e => setActionType(e.target.value as ActionTakenType)}
                    className="w-full text-xs p-2.5 bg-slate-50 border border-slate-300 rounded-lg text-slate-900"
                  >
                    <option value="SHOW_CAUSE_NOTICE">Issue Formal Show-Cause Notice</option>
                    <option value="FREEZE_GRANT_INSTALLMENT">Freeze Subsequent Grant-in-Aid Installment</option>
                    <option value="MANDATORY_RECTIFICATION_AUDIT">Mandate 14-Day Compliance Rectification</option>
                  </select>
                </div>
              )}

              <div>
                <label className="block font-semibold text-slate-700 mb-1">
                  Official Decision Notes & Rationale
                </label>
                <textarea
                  rows={3}
                  value={reviewNotes}
                  onChange={e => setReviewNotes(e.target.value)}
                  placeholder="Record formal reasons for administrative record..."
                  className="w-full text-xs p-2.5 bg-slate-50 border border-slate-300 rounded-lg text-slate-900"
                  required
                />
              </div>

              <div className="pt-3 border-t border-slate-200 flex justify-end gap-2">
                <button
                  type="button"
                  onClick={() => setSelectedReport(null)}
                  className="px-4 py-2 text-xs font-medium text-slate-600 hover:bg-slate-100 rounded-lg"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  disabled={isSubmittingReview}
                  className="px-4 py-2 text-xs font-semibold text-white bg-indigo-600 hover:bg-indigo-700 rounded-lg shadow-xs"
                >
                  {isSubmittingReview ? 'Submitting...' : 'Sign & Submit Official Ruling'}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
};
