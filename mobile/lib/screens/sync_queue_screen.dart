import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_colors.dart';
import '../data/local/database_helper.dart';
import '../models/sync_queue_item.dart';
import '../services/sync_manager.dart';
import '../widgets/government_header.dart';

// =====================================================================
// DRISHTI Mobile App: Outbox Synchronization Queue Screen
// Displays pending background uploads and allows manual retry
// =====================================================================

class SyncQueueScreen extends StatefulWidget {
  const SyncQueueScreen({Key? key}) : super(key: key);

  @override
  State<SyncQueueScreen> createState() => _SyncQueueScreenState();
}

class _SyncQueueScreenState extends State<SyncQueueScreen> {
  List<SyncQueueItem> _queueItems = [];
  bool _isLoading = true;
  String _filter = 'ALL'; // ALL, PENDING, FAILED, SYNCED

  @override
  void initState() {
    super.initState();
    _loadQueue();
  }

  Future<void> _loadQueue() async {
    setState(() => _isLoading = true);
    final items = await DatabaseHelper.instance.getAllSyncQueueItems();
    if (mounted) {
      setState(() {
        _queueItems = items;
        _isLoading = false;
      });
    }
  }

  Future<void> _triggerSync() async {
    final syncManager = context.read<SyncManager>();
    await syncManager.processSyncQueue();
    await _loadQueue();
  }

  List<SyncQueueItem> get _filteredItems {
    switch (_filter) {
      case 'PENDING':
        return _queueItems.where((i) => i.isPending || i.isSyncing).toList();
      case 'FAILED':
        return _queueItems.where((i) => i.isFailed).toList();
      case 'SYNCED':
        return _queueItems.where((i) => i.isSynced).toList();
      case 'ALL':
      default:
        return _queueItems;
    }
  }

  @override
  Widget build(BuildContext context) {
    final syncManager = context.watch<SyncManager>();
    final syncState = syncManager.stateNotifier.value;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          GovernmentHeader(
            subtitle: 'Outbox Synchronization Monitor',
            trailing: IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              onPressed: _loadQueue,
            ),
          ),

          // Status & Progress Banner
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Synchronization Outbox',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          syncState.lastMessage ?? '${_queueItems.where((i) => i.isPending).length} pending updates queued',
                          style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                    ElevatedButton.icon(
                      onPressed: syncState.isSyncing ? null : _triggerSync,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryNavy,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      ),
                      icon: syncState.isSyncing
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Icon(Icons.sync, size: 16),
                      label: Text(syncState.isSyncing ? 'Syncing...' : 'SYNC ALL NOW'),
                    ),
                  ],
                ),
                if (syncState.isSyncing) ...[
                  const SizedBox(height: 12),
                  const LinearProgressIndicator(
                    backgroundColor: AppColors.surfaceVariant,
                    color: AppColors.primaryNavy,
                  ),
                ],
              ],
            ),
          ),

          // Filter bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            color: AppColors.surfaceVariant,
            child: Row(
              children: [
                _buildFilterButton('ALL', 'All (${_queueItems.length})'),
                const SizedBox(width: 8),
                _buildFilterButton('PENDING', 'Pending (${_queueItems.where((i) => i.isPending).length})'),
                const SizedBox(width: 8),
                _buildFilterButton('FAILED', 'Failed (${_queueItems.where((i) => i.isFailed).length})'),
                const SizedBox(width: 8),
                _buildFilterButton('SYNCED', 'Synced (${_queueItems.where((i) => i.isSynced).length})'),
              ],
            ),
          ),

          // Items List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredItems.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _filteredItems.length,
                        itemBuilder: (context, index) {
                          final item = _filteredItems[index];
                          return _buildQueueCard(item);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterButton(String key, String label) {
    final isSelected = _filter == key;
    return InkWell(
      onTap: () => setState(() => _filter = key),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryNavy : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildQueueCard(SyncQueueItem item) {
    Color statusColor;
    IconData statusIcon;

    switch (item.syncStatus) {
      case SyncStatus.synced:
        statusColor = AppColors.statusSuccess;
        statusIcon = Icons.check_circle;
        break;
      case SyncStatus.syncing:
        statusColor = AppColors.statusInfo;
        statusIcon = Icons.sync;
        break;
      case SyncStatus.failed:
        statusColor = AppColors.statusCritical;
        statusIcon = Icons.error_outline;
        break;
      case SyncStatus.pending:
      default:
        statusColor = AppColors.statusWarning;
        statusIcon = Icons.schedule;
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    item.entityType,
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  item.endpoint,
                  style: const TextStyle(fontSize: 12, fontFamily: 'monospace', fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                Icon(statusIcon, size: 16, color: statusColor),
                const SizedBox(width: 4),
                Text(
                  item.syncStatus.code,
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: statusColor),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Text(
                  'Method: ${item.httpMethod} • Attempts: ${item.attemptCount}',
                  style: const TextStyle(fontSize: 10.5, color: AppColors.textMuted),
                ),
                const Spacer(),
                Text(
                  'Queued: ${item.createdAt.toLocal().toString().split('.').first}',
                  style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                ),
              ],
            ),
            if (item.errorMessage != null) ...[
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.statusCriticalBg,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Error: ${item.errorMessage!}',
                  style: const TextStyle(fontSize: 10.5, color: AppColors.statusCritical),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.cloud_done, size: 56, color: AppColors.statusSuccess),
          SizedBox(height: 12),
          Text(
            'Outbox Queue Clear',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 4),
          Text(
            'All local field inspection records have been synchronized.',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
