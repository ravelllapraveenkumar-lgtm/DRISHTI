/**
 * DRISHTI: Government Central Dashboard Sidebar Navigation
 * MoSJE Official Color Palette & Clean Functional Hierarchy
 */

import React from 'react';
import {
  Layers,
  Building2,
  Activity,
  Users,
  ClipboardCheck,
  UserCheck,
  ListChecks,
  ShieldCheck,
  BrainCircuit,
  FileText,
  Bell,
  History,
  Lock,
  CheckCircle2
} from 'lucide-react';
import { useAuth } from '../context/AuthContext';

export type ActiveTab =
  | 'dashboard'
  | 'institutions'
  | 'monitoring'
  | 'attendance'
  | 'inspections'
  | 'assignments'
  | 'checklists'
  | 'evidence'
  | 'alerts'
  | 'reports'
  | 'notifications'
  | 'audit';

interface SidebarProps {
  activeTab: ActiveTab;
  onSelectTab: (tab: ActiveTab) => void;
  pendingAlertsCount: number;
  activeInspectionsCount: number;
}

export const Sidebar: React.FC<SidebarProps> = ({
  activeTab,
  onSelectTab,
  pendingAlertsCount,
  activeInspectionsCount
}) => {
  const { canMandateInspection, canReviewReports, isInspector, isInstitutionHead } = useAuth();

  const navigationSections = [
    {
      group: 'SURVEILLANCE & OVERVIEW',
      items: [
        { id: 'dashboard' as ActiveTab, label: 'Dashboard Home', icon: Layers },
        { id: 'institutions' as ActiveTab, label: 'Institutions', icon: Building2 },
        { id: 'monitoring' as ActiveTab, label: 'Daily Telemetry', icon: Activity },
        { id: 'attendance' as ActiveTab, label: 'Attendance', icon: Users }
      ]
    },
    {
      group: 'INSPECTION CADRE',
      items: [
        {
          id: 'inspections' as ActiveTab,
          label: 'Inspections',
          icon: ClipboardCheck,
          badge: activeInspectionsCount > 0 ? activeInspectionsCount : undefined,
          badgeColor: 'bg-indigo-100 text-indigo-700'
        },
        { id: 'assignments' as ActiveTab, label: 'Assignments', icon: UserCheck },
        { id: 'checklists' as ActiveTab, label: 'Checklist Review', icon: ListChecks },
        { id: 'evidence' as ActiveTab, label: 'Evidence Vault', icon: ShieldCheck }
      ]
    },
    {
      group: 'DECISION SUPPORT & OVERSIGHT',
      items: [
        {
          id: 'alerts' as ActiveTab,
          label: 'AI Alerts',
          icon: BrainCircuit,
          badge: pendingAlertsCount > 0 ? pendingAlertsCount : undefined,
          badgeColor: 'bg-red-100 text-red-700 font-bold'
        },
        { id: 'reports' as ActiveTab, label: 'Inspection Reports', icon: FileText },
        { id: 'notifications' as ActiveTab, label: 'Notifications', icon: Bell },
        { id: 'audit' as ActiveTab, label: 'Audit Activity', icon: History }
      ]
    }
  ];

  return (
    <aside className="w-64 bg-[#0F172A] text-slate-300 flex flex-col shrink-0 min-h-[calc(100vh-69px)] border-r border-slate-800">
      <div className="p-4 space-y-6 flex-1">
        {navigationSections.map(section => (
          <div key={section.group}>
            <div className="text-[10px] font-bold tracking-wider text-slate-500 uppercase px-3 mb-2">
              {section.group}
            </div>
            <div className="space-y-1">
              {section.items.map(item => {
                const Icon = item.icon;
                const isActive = activeTab === item.id;

                return (
                  <button
                    key={item.id}
                    onClick={() => onSelectTab(item.id)}
                    className={`w-full flex items-center justify-between px-3 py-2 rounded-lg text-xs font-medium transition-all ${
                      isActive
                        ? 'bg-indigo-600 text-white shadow-xs font-semibold'
                        : 'text-slate-300 hover:text-white hover:bg-slate-800/70'
                    }`}
                  >
                    <div className="flex items-center gap-2.5">
                      <Icon className={`w-4 h-4 ${isActive ? 'text-white' : 'text-slate-400'}`} />
                      <span>{item.label}</span>
                    </div>
                    {item.badge !== undefined && (
                      <span
                        className={`text-[10px] px-1.5 py-0.2 rounded-full font-mono ${
                          isActive ? 'bg-white/20 text-white' : item.badgeColor
                        }`}
                      >
                        {item.badge}
                      </span>
                    )}
                  </button>
                );
              })}
            </div>
          </div>
        ))}
      </div>

      {/* Role Context Footer Card */}
      <div className="p-4 border-t border-slate-800 bg-[#0B1120]">
        <div className="flex items-center gap-2 mb-1.5 text-[11px] font-semibold text-slate-400">
          <Lock className="w-3.5 h-3.5 text-indigo-400" />
          <span>Active Role Privileges</span>
        </div>
        <div className="text-[10px] text-slate-400 space-y-1">
          {canMandateInspection && (
            <div className="text-emerald-400 flex items-center gap-1.5">
              <CheckCircle2 className="w-3 h-3 text-emerald-400 shrink-0" />
              <span>Can Mandate Inspections</span>
            </div>
          )}
          {canReviewReports && (
            <div className="text-emerald-400 flex items-center gap-1.5">
              <CheckCircle2 className="w-3 h-3 text-emerald-400 shrink-0" />
              <span>Can Issue Sanctions & Reviews</span>
            </div>
          )}
          {isInspector && (
            <div className="text-amber-400 flex items-center gap-1.5">
              <span className="w-1.5 h-1.5 rounded-full bg-amber-400 shrink-0"></span>
              <span>Field Cadre: Checklists & Evidence</span>
            </div>
          )}
          {isInstitutionHead && (
            <div className="text-blue-400 flex items-center gap-1.5">
              <span className="w-1.5 h-1.5 rounded-full bg-blue-400 shrink-0"></span>
              <span>Institution View: Telemetry & Attendance</span>
            </div>
          )}
        </div>
      </div>
    </aside>
  );
};
