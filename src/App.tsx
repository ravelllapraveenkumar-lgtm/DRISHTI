/**
 * DRISHTI: Government Central Dashboard (Phase 4)
 * Ministry of Social Justice and Empowerment (MoSJE) | SIH 2026 Problem ID: 26095
 * Official Live Monitoring & Decision-Support Interface
 */

import React, { useState, useEffect } from 'react';
import { AuthProvider, useAuth } from './context/AuthContext';
import { Header } from './components/Header';
import { Sidebar, ActiveTab } from './components/Sidebar';
import { DashboardHome } from './components/DashboardHome';
import { InstitutionsView } from './components/InstitutionsView';
import { MonitoringView } from './components/MonitoringView';
import { AttendanceView } from './components/AttendanceView';
import { InspectionsView } from './components/InspectionsView';
import { AssignmentsView } from './components/AssignmentsView';
import { ChecklistReviewView } from './components/ChecklistReviewView';
import { EvidenceReviewView } from './components/EvidenceReviewView';
import { AIAlertsView } from './components/AIAlertsView';
import { ReportsReviewView } from './components/ReportsReviewView';
import { NotificationsView } from './components/NotificationsView';
import { AuditActivityView } from './components/AuditActivityView';
import { MandateInspectionModal } from './components/MandateInspectionModal';

import { api } from './api/client';
import { DashboardSummary, Institution, AIAlert, DemoUser } from './types/api';
import { RefreshCw, Menu, X } from 'lucide-react';

function DashboardContent() {
  const { isBackendConnected, demoUsers } = useAuth();

  const [activeTab, setActiveTab] = useState<ActiveTab>('dashboard');
  const [mobileSidebarOpen, setMobileSidebarOpen] = useState(false);
  const [isRefreshing, setIsRefreshing] = useState(false);

  // Global State
  const [summary, setSummary] = useState<DashboardSummary | null>(null);
  const [institutions, setInstitutions] = useState<Institution[]>([]);
  const [alerts, setAlerts] = useState<AIAlert[]>([]);
  const [selectedInstForMonitoring, setSelectedInstForMonitoring] = useState<string | undefined>();

  // Mandate Inspection Modal State
  const [mandateModalOpen, setMandateModalOpen] = useState(false);
  const [preselectedInstId, setPreselectedInstId] = useState<string | undefined>();
  const [preselectedAlertId, setPreselectedAlertId] = useState<string | undefined>();
  const [defaultReason, setDefaultReason] = useState<string | undefined>();

  const loadData = async () => {
    setIsRefreshing(true);
    try {
      const [sumRes, instRes, alertRes] = await Promise.all([
        api.getDashboardSummary(),
        api.getInstitutions(),
        api.getAIAlerts()
      ]);
      setSummary(sumRes.data);
      setInstitutions(Array.isArray(instRes.data) ? instRes.data : (instRes.data as any)?.items || []);
      setAlerts(Array.isArray(alertRes.data) ? alertRes.data : (alertRes.data as any)?.items || []);
    } catch (err) {
      console.warn('Dashboard initialization fetch warning:', err);
    } finally {
      setIsRefreshing(false);
    }
  };

  useEffect(() => {
    loadData();
    const interval = setInterval(loadData, 30000);
    return () => clearInterval(interval);
  }, []);

  const openMandateModal = (instId?: string, alertId?: string, reason?: string) => {
    setPreselectedInstId(instId);
    setPreselectedAlertId(alertId);
    setDefaultReason(reason);
    setMandateModalOpen(true);
  };

  const handleNavigateToMonitoring = (instId: string) => {
    setSelectedInstForMonitoring(instId);
    setActiveTab('monitoring');
  };

  const alertList = Array.isArray(alerts) ? alerts : (alerts as any)?.items || [];
  const pendingAlertsCount = alertList.filter(a => !a.is_acknowledged).length;
  const activeInspectionsCount = summary?.active_inspections ?? 1;

  return (
    <div className="min-h-screen bg-slate-100/70 text-slate-900 flex flex-col antialiased">
      {/* Official Government Header */}
      <Header
        onOpenNotifications={() => setActiveTab('notifications')}
        onNavigateTab={(t: string) => setActiveTab(t as ActiveTab)}
      />

      {/* Main Layout Container */}
      <div className="flex-1 flex overflow-hidden">
        {/* Desktop Sidebar */}
        <div className="hidden lg:block">
          <Sidebar
            activeTab={activeTab}
            onSelectTab={tab => setActiveTab(tab)}
            pendingAlertsCount={pendingAlertsCount}
            activeInspectionsCount={activeInspectionsCount}
          />
        </div>

        {/* Mobile Drawer */}
        {mobileSidebarOpen && (
          <div className="fixed inset-0 z-40 lg:hidden flex">
            <div
              className="fixed inset-0 bg-slate-900/60 backdrop-blur-xs"
              onClick={() => setMobileSidebarOpen(false)}
            />
            <div className="relative z-50 w-72 bg-[#0F172A] flex flex-col h-full">
              <div className="p-4 flex justify-between items-center border-b border-slate-800 text-white">
                <span className="font-bold text-sm">Navigation Menu</span>
                <button
                  onClick={() => setMobileSidebarOpen(false)}
                  className="text-slate-400 hover:text-white"
                >
                  <X className="w-5 h-5" />
                </button>
              </div>
              <div className="flex-1 overflow-y-auto">
                <Sidebar
                  activeTab={activeTab}
                  onSelectTab={tab => {
                    setActiveTab(tab);
                    setMobileSidebarOpen(false);
                  }}
                  pendingAlertsCount={pendingAlertsCount}
                  activeInspectionsCount={activeInspectionsCount}
                />
              </div>
            </div>
          </div>
        )}

        {/* Main Content Area */}
        <main className="flex-1 overflow-y-auto p-4 sm:p-6 lg:p-8">
          {/* Mobile sub-bar with toggle and refresh */}
          <div className="flex items-center justify-between lg:hidden mb-4 bg-white p-3 rounded-xl border border-slate-200 shadow-xs">
            <button
              onClick={() => setMobileSidebarOpen(true)}
              className="flex items-center gap-2 text-xs font-semibold text-slate-700 hover:text-slate-900"
            >
              <Menu className="w-4 h-4" />
              <span>Menu</span>
            </button>
            <button
              onClick={loadData}
              disabled={isRefreshing}
              className="flex items-center gap-1.5 text-xs text-indigo-600 hover:text-indigo-800 font-medium"
            >
              <RefreshCw className={`w-3.5 h-3.5 ${isRefreshing ? 'animate-spin' : ''}`} />
              <span>Refresh</span>
            </button>
          </div>

          {/* Views Switching */}
          {activeTab === 'dashboard' && (
            <DashboardHome
              summary={summary}
              institutions={institutions}
              alerts={alerts}
              isLoading={isRefreshing}
              onNavigate={(tab: string) => setActiveTab(tab as ActiveTab)}
              onMandateInspection={openMandateModal}
              onSelectInstitution={inst => {
                handleNavigateToMonitoring(inst.id);
              }}
            />
          )}

          {activeTab === 'institutions' && (
            <InstitutionsView
              institutions={institutions}
              onMandateInspection={openMandateModal}
              onNavigateToMonitoring={handleNavigateToMonitoring}
            />
          )}

          {activeTab === 'monitoring' && (
            <MonitoringView
              institutions={institutions}
              initialInstitutionId={selectedInstForMonitoring}
              onMandateInspection={openMandateModal}
            />
          )}

          {activeTab === 'attendance' && <AttendanceView institutions={institutions} />}

          {activeTab === 'inspections' && (
            <InspectionsView onMandateInspection={openMandateModal} />
          )}

          {activeTab === 'assignments' && <AssignmentsView />}

          {activeTab === 'checklists' && <ChecklistReviewView />}

          {activeTab === 'evidence' && <EvidenceReviewView />}

          {activeTab === 'alerts' && <AIAlertsView onMandateInspection={openMandateModal} />}

          {activeTab === 'reports' && <ReportsReviewView />}

          {activeTab === 'notifications' && (
            <NotificationsView onNavigateToTab={tab => setActiveTab(tab as ActiveTab)} />
          )}

          {activeTab === 'audit' && <AuditActivityView />}
        </main>
      </div>

      {/* Mandate Unannounced Inspection Dialog */}
      <MandateInspectionModal
        isOpen={mandateModalOpen}
        onClose={() => {
          setMandateModalOpen(false);
          setPreselectedInstId(undefined);
          setPreselectedAlertId(undefined);
          setDefaultReason(undefined);
        }}
        onInspectionCreated={() => {
          loadData();
          setActiveTab('inspections');
        }}
        institutions={institutions}
        inspectors={demoUsers}
        preselectedInstitutionId={preselectedInstId}
        preselectedAlertId={preselectedAlertId}
        defaultReason={defaultReason}
      />
    </div>
  );
}

export default function App() {
  return (
    <AuthProvider>
      <DashboardContent />
    </AuthProvider>
  );
}
