import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_strings.dart';
import '../models/inspection_model.dart';
import '../providers/auth_provider.dart';
import '../providers/inspections_provider.dart';
import '../widgets/ai_anomaly_card.dart';
import '../widgets/government_header.dart';
import '../widgets/sync_status_badge.dart';
import 'inspection_detail_screen.dart';
import 'login_screen.dart';
import 'settings_screen.dart';
import 'sync_queue_screen.dart';

// =====================================================================
// DRISHTI Mobile App: Inspector Central Dashboard
// Displays assigned field inspections, local offline cache status, and metrics
// =====================================================================

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final inspectionsProv = context.read<InspectionsProvider>();
    final authProv = context.read<AuthProvider>();

    // 1. Load SQLite cache immediately (zero delay)
    await inspectionsProv.loadLocalInspections();

    // 2. Fetch fresh assignments from FastAPI if user is authenticated
    if (authProv.currentUser != null) {
      await inspectionsProv.refreshFromBackend(authProv.currentUser!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final inspectionsProv = context.watch<InspectionsProvider>();
    final user = auth.currentUser;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Government Header Banner
          GovernmentHeader(
            subtitle: user != null
                ? '${user.fullName} • ${user.district ?? 'North Zone'}, ${user.state ?? 'UP'}'
                : 'Officer Session Active',
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Outbox Sync Queue Button with live badge
                IconButton(
                  icon: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      const Icon(Icons.sync_alt, color: Colors.white, size: 22),
                      if (inspectionsProv.pendingSyncCount > 0)
                        Positioned(
                          right: -6,
                          top: -6,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: AppColors.saffronAccent,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              '${inspectionsProv.pendingSyncCount}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  tooltip: 'Sync Queue',
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const SyncQueueScreen()),
                    );
                  },
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: Colors.white),
                  onSelected: (val) {
                    if (val == 'settings') {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const SettingsScreen()),
                      );
                    } else if (val == 'logout') {
                      auth.logout();
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                      );
                    }
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                      value: 'settings',
                      child: Row(
                        children: [
                          Icon(Icons.settings, size: 18),
                          SizedBox(width: 8),
                          Text('Settings & Host'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'logout',
                      child: Row(
                        children: [
                          Icon(Icons.logout, size: 18, color: AppColors.statusCritical),
                          SizedBox(width: 8),
                          Text('Logout', style: TextStyle(color: AppColors.statusCritical)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Offline Status Bar (if any pending items)
          if (inspectionsProv.pendingSyncCount > 0)
            Container(
              width: double.infinity,
              color: AppColors.saffronLight,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Row(
                children: [
                  const Icon(Icons.cloud_off, size: 14, color: AppColors.saffronAccent),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${inspectionsProv.pendingSyncCount} record(s) queued offline. Tap sync icon to push.',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.saffronAccent),
                    ),
                  ),
                ],
              ),
            ),

          // Summary Metrics Cards
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                _buildMetricTile(
                  label: 'Assigned',
                  count: inspectionsProv.totalCount,
                  color: AppColors.primaryNavy,
                ),
                const SizedBox(width: 8),
                _buildMetricTile(
                  label: 'In-Progress',
                  count: inspectionsProv.inProgressCount,
                  color: AppColors.statusInfo,
                ),
                const SizedBox(width: 8),
                _buildMetricTile(
                  label: 'Submitted',
                  count: inspectionsProv.submittedCount,
                  color: AppColors.statusSuccess,
                ),
                const SizedBox(width: 8),
                _buildMetricTile(
                  label: 'Urgent',
                  count: inspectionsProv.highPriorityCount,
                  color: AppColors.statusCritical,
                ),
              ],
            ),
          ),

          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                _buildFilterChip('ALL', 'All Inspections (${inspectionsProv.totalCount})'),
                const SizedBox(width: 8),
                _buildFilterChip('HIGH_PRIORITY', 'High Priority (${inspectionsProv.highPriorityCount})'),
                const SizedBox(width: 8),
                _buildFilterChip('IN_PROGRESS', 'In Progress (${inspectionsProv.inProgressCount})'),
                const SizedBox(width: 8),
                _buildFilterChip('SUBMITTED', 'Submitted (${inspectionsProv.submittedCount})'),
              ],
            ),
          ),

          const SizedBox(height: 6),

          // Inspection Cards List
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                if (user != null) {
                  await inspectionsProv.refreshFromBackend(user);
                } else {
                  await inspectionsProv.loadLocalInspections();
                }
              },
              child: inspectionsProv.isLoading && inspectionsProv.inspections.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : inspectionsProv.inspections.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
                          itemCount: inspectionsProv.inspections.length,
                          itemBuilder: (context, index) {
                            final inspection = inspectionsProv.inspections[index];
                            return _buildInspectionCard(inspection);
                          },
                        ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primaryNavy,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.sync),
        label: Text(
          inspectionsProv.pendingSyncCount > 0
              ? 'Sync Outbox (${inspectionsProv.pendingSyncCount})'
              : 'Sync Central',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const SyncQueueScreen()),
          );
        },
      ),
    );
  }

  Widget _buildMetricTile({
    required String label,
    required int count,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Text(
              '$count',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String filterKey, String label) {
    final prov = context.watch<InspectionsProvider>();
    final isSelected = prov.currentFilter == filterKey;

    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? Colors.white : AppColors.textPrimary,
        ),
      ),
      selected: isSelected,
      selectedColor: AppColors.primaryNavy,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      onSelected: (_) => prov.setFilter(filterKey),
    );
  }

  Widget _buildInspectionCard(InspectionModel item) {
    Color priorityColor;
    switch (item.priority) {
      case 'EMERGENCY':
        priorityColor = AppColors.statusCritical;
        break;
      case 'URGENT':
        priorityColor = AppColors.statusWarning;
        break;
      default:
        priorityColor = AppColors.statusInfo;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: item.isHighPriority ? priorityColor.withOpacity(0.4) : AppColors.border,
          width: item.isHighPriority ? 1.5 : 1.0,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => InspectionDetailScreen(inspectionLocalId: item.localId),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Code, Priority, and Sync Status
              Row(
                children: [
                  Text(
                    item.inspectionCode,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: AppColors.primaryNavy,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: priorityColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      item.priority,
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.bold,
                        color: priorityColor,
                      ),
                    ),
                  ),
                  const Spacer(),
                  SyncStatusBadge(status: item.syncStatus),
                ],
              ),
              const SizedBox(height: 8),

              // Institution Name
              Text(
                item.institutionName,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),

              // Location & Mandated Date
              Row(
                children: [
                  const Icon(Icons.place, size: 13, color: AppColors.textMuted),
                  const SizedBox(width: 4),
                  Text(
                    '${item.institutionDistrict}, ${item.institutionState}',
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                  const Spacer(),
                  const Icon(Icons.event, size: 13, color: AppColors.textMuted),
                  const SizedBox(width: 4),
                  Text(
                    'Due: ${item.dueDate.split('T').first}',
                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                  ),
                ],
              ),

              // Responsible AI Advisory Card
              if (item.aiAttentionScore != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: AiAnomalyCard(
                    attentionScore: item.aiAttentionScore,
                    anomalySummary: item.aiAlertSummary,
                  ),
                ),

              const SizedBox(height: 8),

              // Status and CTA
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: item.isInProgress
                          ? AppColors.statusInfoBg
                          : (item.isSubmitted ? AppColors.statusSuccessBg : AppColors.surfaceVariant),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      item.status,
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                        color: item.isInProgress
                            ? AppColors.statusInfo
                            : (item.isSubmitted ? AppColors.statusSuccess : AppColors.textSecondary),
                      ),
                    ),
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      Text(
                        item.isInProgress ? 'Continue Inspection' : 'View Details',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryNavy,
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios, size: 12, color: AppColors.primaryNavy),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.assignment_turned_in, size: 56, color: AppColors.textMuted),
          const SizedBox(height: 16),
          const Text(
            'No Inspections Found',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 6),
          const Text(
            'Assignments will appear here once dispatched from DRISHTI Central.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () {
              final auth = context.read<AuthProvider>();
              if (auth.currentUser != null) {
                context.read<InspectionsProvider>().refreshFromBackend(auth.currentUser!);
              }
            },
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Refresh from Central Backend'),
          ),
        ],
      ),
    );
  }
}
