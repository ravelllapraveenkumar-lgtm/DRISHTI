import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_colors.dart';
import '../models/inspection_model.dart';
import '../providers/inspection_detail_provider.dart';
import '../widgets/ai_anomaly_card.dart';
import '../widgets/geofence_status_card.dart';
import '../widgets/government_header.dart';
import '../widgets/sync_status_badge.dart';
import 'checklist_screen.dart';
import 'evidence_screen.dart';
import 'notes_screen.dart';
import 'report_submission_screen.dart';
import 'sync_queue_screen.dart';

// =====================================================================
// DRISHTI Mobile App: Inspection Workspace Hub
// Coordinates GPS Arrival, Physical Checklist, Evidence Vault, Notes, & Report
// =====================================================================

class InspectionDetailScreen extends StatefulWidget {
  final String inspectionLocalId;

  const InspectionDetailScreen({Key? key, required this.inspectionLocalId}) : super(key: key);

  @override
  State<InspectionDetailScreen> createState() => _InspectionDetailScreenState();
}

class _InspectionDetailScreenState extends State<InspectionDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<InspectionDetailProvider>().loadInspection(widget.inspectionLocalId);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final detailProv = context.watch<InspectionDetailProvider>();
    final inspection = detailProv.inspection;

    if (detailProv.isLoading && inspection == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (inspection == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Inspection Not Found')),
        body: const Center(child: Text('The requested inspection could not be loaded.')),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Government Header
          GovernmentHeader(
            subtitle: '${inspection.inspectionCode} • ${inspection.institutionName}',
            trailing: IconButton(
              icon: const Icon(Icons.sync, color: Colors.white),
              tooltip: 'Sync Queue',
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SyncQueueScreen()),
                );
              },
            ),
          ),

          // Sub-Header with Status & Server UUID Mapping
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        inspection.inspectionCode,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryNavy,
                        ),
                      ),
                      Text(
                        inspection.serverId != null
                            ? 'Server UUID: ${inspection.serverId!.substring(0, 8)}...'
                            : 'Local Record ID: ${inspection.localId}',
                        style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
                SyncStatusBadge(status: inspection.syncStatus),
              ],
            ),
          ),

          // Workspace Tab Bar
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              labelColor: AppColors.primaryNavy,
              unselectedLabelColor: AppColors.textMuted,
              indicatorColor: AppColors.primaryNavy,
              indicatorWeight: 3,
              labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              tabs: [
                const Tab(icon: Icon(Icons.info_outline, size: 18), text: 'Overview'),
                Tab(
                  icon: const Icon(Icons.checklist, size: 18),
                  text: 'Checklist (${detailProv.responses.length}/${detailProv.checklistItems.length})',
                ),
                Tab(
                  icon: const Icon(Icons.camera_alt_outlined, size: 18),
                  text: 'Evidence (${detailProv.evidences.length})',
                ),
                Tab(
                  icon: const Icon(Icons.note_alt_outlined, size: 18),
                  text: 'Notes (${detailProv.notes.length})',
                ),
                Tab(
                  icon: const Icon(Icons.assignment_turned_in_outlined, size: 18),
                  text: detailProv.reportDraft != null ? 'Report Draft' : 'Report',
                ),
              ],
            ),
          ),

          // Tab Views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(inspection, detailProv),
                ChecklistScreen(inspectionLocalId: widget.inspectionLocalId),
                EvidenceScreen(inspectionLocalId: widget.inspectionLocalId),
                NotesScreen(inspectionLocalId: widget.inspectionLocalId),
                ReportSubmissionScreen(inspectionLocalId: widget.inspectionLocalId),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewTab(InspectionModel inspection, InspectionDetailProvider detailProv) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Geofence & GPS Verification Card
          GeofenceStatusCard(
            targetLat: inspection.targetLatitude,
            targetLon: inspection.targetLongitude,
            geofenceRadiusMeters: inspection.geofenceRadiusMeters,
            currentLocation: detailProv.lastLocation,
            isVerified: detailProv.isGeofenceVerified,
            distanceMeters: detailProv.distanceToTargetMeters,
            isVerifying: detailProv.isLoading,
            onVerifyPressed: () => detailProv.verifyArrivalGeofence(allowDemoFallback: true),
          ),
          const SizedBox(height: 16),

          // AI Advisory Card
          if (inspection.aiAttentionScore != null)
            AiAnomalyCard(
              attentionScore: inspection.aiAttentionScore,
              anomalySummary: inspection.aiAlertSummary,
            ),
          const SizedBox(height: 12),

          // Institution Details Container
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Institution Profile',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                _buildDetailRow('Institution Name', inspection.institutionName),
                _buildDetailRow('District / State', '${inspection.institutionDistrict}, ${inspection.institutionState}'),
                _buildDetailRow('Reason for Audit', inspection.inspectionReason),
                _buildDetailRow('Mandated Due Date', inspection.dueDate.split('T').first),
                _buildDetailRow('Priority Classification', inspection.priority),
                if (inspection.specialInstructions != null)
                  _buildDetailRow('Special Instructions', inspection.specialInstructions!),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Quick Workflow Progression Action
          Container(
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Inspector Progression Checklist',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                _buildStepItem('1. Verify On-Site Geofence', detailProv.isGeofenceVerified),
                _buildStepItem('2. Complete Sectional Checklist', detailProv.responses.isNotEmpty),
                _buildStepItem('3. Register Tamper-Proof Evidence', detailProv.evidences.isNotEmpty),
                _buildStepItem('4. Draft & Submit Final Report', detailProv.reportDraft != null),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      _tabController.animateTo(1); // Jump to checklist
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryNavy,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('PROCEED TO CHECKLIST'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepItem(String title, bool isCompleted) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(
            isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 16,
            color: isCompleted ? AppColors.statusSuccess : AppColors.textMuted,
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isCompleted ? FontWeight.w600 : FontWeight.normal,
              color: isCompleted ? AppColors.textPrimary : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
