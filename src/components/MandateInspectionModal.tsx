/**
 * DRISHTI: Mandate Unannounced Inspection Modal
 * Enables authorized officials to dispatch field cadre with geo-instructions
 */

import React, { useState } from 'react';
import {
  X,
  ClipboardCheck,
  AlertTriangle,
  Calendar,
  User,
  Shield,
  Send,
  Building2,
  CheckCircle2
} from 'lucide-react';
import { api } from '../api/client';
import { Institution, DemoUser, PriorityLevel } from '../types/api';

interface MandateInspectionModalProps {
  isOpen: boolean;
  onClose: () => void;
  onInspectionCreated: () => void;
  institutions: Institution[];
  inspectors: DemoUser[];
  preselectedInstitutionId?: string;
  preselectedAlertId?: string;
  defaultReason?: string;
}

export const MandateInspectionModal: React.FC<MandateInspectionModalProps> = ({
  isOpen,
  onClose,
  onInspectionCreated,
  institutions,
  inspectors,
  preselectedInstitutionId,
  preselectedAlertId,
  defaultReason
}) => {
  const [institutionId, setInstitutionId] = useState(preselectedInstitutionId || (institutions[0]?.id ?? ''));
  const [priority, setPriority] = useState<PriorityLevel>('URGENT');
  const [mandatedDate, setMandatedDate] = useState(new Date().toISOString().split('T')[0]);
  const [dueDate, setDueDate] = useState(
    new Date(Date.now() + 3 * 86400000).toISOString().split('T')[0]
  );
  const [reason, setReason] = useState(
    defaultReason || 'Unannounced field verification mandated based on algorithmic attention divergence.'
  );
  const [specialInstructions, setSpecialInstructions] = useState(
    'Conduct comprehensive physical headcount against biometric roster, verify kitchen meal ledger, and capture geofenced infrastructure photographs.'
  );
  const [inspectorId, setInspectorId] = useState(
    inspectors.find(i => i.roles.includes('FIELD_INSPECTOR'))?.id || ''
  );
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [errorMessage, setErrorMessage] = useState<string | null>(null);

  if (!isOpen) return null;

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!institutionId) {
      setErrorMessage('Please select a target institution');
      return;
    }
    if (!reason || reason.length < 5) {
      setErrorMessage('Inspection reason must be at least 5 characters');
      return;
    }

    setIsSubmitting(true);
    setErrorMessage(null);

    try {
      await api.createInspection({
        institution_id: institutionId,
        priority,
        mandated_date: mandatedDate,
        due_date: dueDate,
        inspection_reason: reason,
        special_instructions: specialInstructions,
        inspector_user_id: inspectorId || undefined,
        origin_ai_alert_id: preselectedAlertId
      });

      onInspectionCreated();
      onClose();
    } catch (err: any) {
      setErrorMessage(err.message || 'Failed to mandate inspection');
    } finally {
      setIsSubmitting(false);
    }
  };

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-slate-900/60 backdrop-blur-xs animate-in fade-in">
      <div className="bg-white rounded-2xl shadow-2xl border border-slate-200 w-full max-w-2xl overflow-hidden">
        {/* Header */}
        <div className="px-6 py-4 bg-[#0F172A] text-white flex items-center justify-between border-b border-slate-800">
          <div className="flex items-center gap-2.5">
            <div className="w-8 h-8 rounded-lg bg-indigo-600 flex items-center justify-center text-white">
              <ClipboardCheck className="w-4 h-4" />
            </div>
            <div>
              <h3 className="font-bold text-sm tracking-tight text-white">
                Mandate Unannounced Inspection
              </h3>
              <p className="text-[11px] text-slate-400">
                Official Ministry Directive under MoSJE Monitoring Protocol
              </p>
            </div>
          </div>
          <button
            onClick={onClose}
            className="text-slate-400 hover:text-white p-1 rounded-lg transition-colors"
          >
            <X className="w-5 h-5" />
          </button>
        </div>

        {/* Responsible AI Safeguard Banner */}
        <div className="bg-amber-50 border-b border-amber-200 px-6 py-2.5 flex items-start gap-2.5 text-xs text-amber-900">
          <AlertTriangle className="w-4 h-4 text-amber-600 shrink-0 mt-0.5" />
          <div>
            <span className="font-bold">Human Verification Directive: </span>
            <span>
              Inspections verify field conditions objectively. The inspection team must assess
              physical attendance, meal nutrition, and beneficiary care without presupposing irregularity.
            </span>
          </div>
        </div>

        {/* Form */}
        <form onSubmit={handleSubmit} className="p-6 space-y-4 max-h-[75vh] overflow-y-auto">
          {errorMessage && (
            <div className="p-3 bg-red-50 border border-red-200 rounded-lg text-xs text-red-700 font-medium">
              {errorMessage}
            </div>
          )}

          {/* Institution Selector */}
          <div>
            <label className="block text-xs font-semibold text-slate-700 mb-1">
              Target Institution <span className="text-red-500">*</span>
            </label>
            <div className="relative">
              <select
                value={institutionId}
                onChange={e => setInstitutionId(e.target.value)}
                className="w-full text-xs bg-slate-50 border border-slate-300 rounded-lg px-3 py-2 text-slate-900 focus:bg-white focus:outline-hidden focus:ring-2 focus:ring-indigo-500"
                required
              >
                <option value="">Select Institution...</option>
                {institutions.map(inst => (
                  <option key={inst.id} value={inst.id}>
                    {inst.name} ({inst.district}, {inst.state}) - [Risk: {inst.current_risk_score}/100 -{' '}
                    {inst.risk_level}]
                  </option>
                ))}
              </select>
            </div>
          </div>

          {/* Priority & Due Date */}
          <div className="grid grid-cols-1 sm:grid-cols-3 gap-3">
            <div>
              <label className="block text-xs font-semibold text-slate-700 mb-1">Priority Level</label>
              <select
                value={priority}
                onChange={e => setPriority(e.target.value as PriorityLevel)}
                className="w-full text-xs bg-slate-50 border border-slate-300 rounded-lg px-3 py-2 text-slate-900 focus:bg-white focus:outline-hidden focus:ring-2 focus:ring-indigo-500 font-medium"
              >
                <option value="ROUTINE">ROUTINE (Standard Audit)</option>
                <option value="URGENT">URGENT (48h Verification)</option>
                <option value="EMERGENCY">EMERGENCY (Immediate Dispatch)</option>
              </select>
            </div>

            <div>
              <label className="block text-xs font-semibold text-slate-700 mb-1">Mandated Date</label>
              <input
                type="date"
                value={mandatedDate}
                onChange={e => setMandatedDate(e.target.value)}
                className="w-full text-xs bg-slate-50 border border-slate-300 rounded-lg px-3 py-2 text-slate-900 focus:bg-white focus:outline-hidden focus:ring-2 focus:ring-indigo-500"
                required
              />
            </div>

            <div>
              <label className="block text-xs font-semibold text-slate-700 mb-1">Due Date</label>
              <input
                type="date"
                value={dueDate}
                onChange={e => setDueDate(e.target.value)}
                className="w-full text-xs bg-slate-50 border border-slate-300 rounded-lg px-3 py-2 text-slate-900 focus:bg-white focus:outline-hidden focus:ring-2 focus:ring-indigo-500"
                required
              />
            </div>
          </div>

          {/* Assign Field Inspector */}
          <div>
            <label className="block text-xs font-semibold text-slate-700 mb-1">
              Assign Field Inspector (Optional / Auto-Dispatch)
            </label>
            <select
              value={inspectorId}
              onChange={e => setInspectorId(e.target.value)}
              className="w-full text-xs bg-slate-50 border border-slate-300 rounded-lg px-3 py-2 text-slate-900 focus:bg-white focus:outline-hidden focus:ring-2 focus:ring-indigo-500"
            >
              <option value="">Unassigned (Queue for District Dispatch)</option>
              {inspectors
                .filter(i => i.roles.includes('FIELD_INSPECTOR') || i.roles.includes('SUPER_ADMIN'))
                .map(insp => (
                  <option key={insp.id} value={insp.id}>
                    {insp.full_name} ({insp.designation} • {insp.district || insp.state})
                  </option>
                ))}
            </select>
          </div>

          {/* Reason */}
          <div>
            <label className="block text-xs font-semibold text-slate-700 mb-1">
              Official Directive Reason <span className="text-red-500">*</span>
            </label>
            <textarea
              value={reason}
              onChange={e => setReason(e.target.value)}
              rows={2}
              className="w-full text-xs bg-slate-50 border border-slate-300 rounded-lg p-2.5 text-slate-900 focus:bg-white focus:outline-hidden focus:ring-2 focus:ring-indigo-500"
              placeholder="State the regulatory grounds or anomaly trigger..."
              required
            />
          </div>

          {/* Special Instructions */}
          <div>
            <label className="block text-xs font-semibold text-slate-700 mb-1">
              Special Field Instructions & Checklist Focus
            </label>
            <textarea
              value={specialInstructions}
              onChange={e => setSpecialInstructions(e.target.value)}
              rows={3}
              className="w-full text-xs bg-slate-50 border border-slate-300 rounded-lg p-2.5 text-slate-900 focus:bg-white focus:outline-hidden focus:ring-2 focus:ring-indigo-500"
              placeholder="e.g., Cross-verify CCTV log timestamp with biometric punch file..."
            />
          </div>

          {/* Buttons */}
          <div className="pt-3 border-t border-slate-200 flex justify-end items-center gap-3">
            <button
              type="button"
              onClick={onClose}
              className="px-4 py-2 text-xs font-medium text-slate-600 hover:text-slate-900 hover:bg-slate-100 rounded-lg transition-colors"
            >
              Cancel
            </button>
            <button
              type="submit"
              disabled={isSubmitting}
              className="px-4 py-2 text-xs font-semibold text-white bg-indigo-600 hover:bg-indigo-700 rounded-lg transition-all shadow-xs flex items-center gap-1.5 disabled:opacity-50"
            >
              <Send className="w-3.5 h-3.5" />
              <span>{isSubmitting ? 'Dispatching Directive...' : 'Issue Inspection Order'}</span>
            </button>
          </div>
        </form>
      </div>
    </div>
  );
};
