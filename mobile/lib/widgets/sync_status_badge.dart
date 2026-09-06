import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

// =====================================================================
// DRISHTI Mobile App: Sync Status Indicator Badge
// Provides clear visual distinction between Local Pending, Synced, and Failed
// =====================================================================

class SyncStatusBadge extends StatelessWidget {
  final String status; // PENDING, SYNCING, SYNCED, FAILED
  final VoidCallback? onRetry;
  final bool showLabel;

  const SyncStatusBadge({
    Key? key,
    required this.status,
    this.onRetry,
    this.showLabel = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    IconData icon;
    String label;

    switch (status.toUpperCase()) {
      case 'SYNCED':
      case 'SYNCED_SUCCESS':
        bg = AppColors.statusSuccessBg;
        fg = AppColors.statusSuccess;
        icon = Icons.cloud_done;
        label = 'Synced';
        break;

      case 'SYNCING':
        bg = AppColors.statusInfoBg;
        fg = AppColors.statusInfo;
        icon = Icons.sync;
        label = 'Syncing...';
        break;

      case 'FAILED':
      case 'SYNC_FAILED':
        bg = AppColors.statusCriticalBg;
        fg = AppColors.statusCritical;
        icon = Icons.sync_problem;
        label = 'Sync Failed';
        break;

      case 'PENDING':
      case 'LOCAL_PENDING':
      default:
        bg = AppColors.statusWarningBg;
        fg = AppColors.statusWarning;
        icon = Icons.cloud_queue;
        label = 'Local Only';
        break;
    }

    Widget badge = Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: fg.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: fg),
          if (showLabel) ...[
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: fg,
              ),
            ),
          ],
        ],
      ),
    );

    if ((status.toUpperCase() == 'FAILED' || status.toUpperCase() == 'SYNC_FAILED') && onRetry != null) {
      return InkWell(
        onTap: onRetry,
        borderRadius: BorderRadius.circular(12),
        child: badge,
      );
    }

    return badge;
  }
}
