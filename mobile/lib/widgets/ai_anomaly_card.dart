import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_strings.dart';

// =====================================================================
// DRISHTI Mobile App: Responsible AI Anomaly Context Widget
// Strictly adheres to mandated advisory phrasing without automated conclusions
// =====================================================================

class AiAnomalyCard extends StatelessWidget {
  final double? attentionScore;
  final String? anomalySummary;

  const AiAnomalyCard({
    Key? key,
    this.attentionScore,
    this.anomalySummary,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (anomalySummary == null && attentionScore == null) {
      return const SizedBox.shrink();
    }

    final score = attentionScore ?? 45.0;
    final isHighAttention = score >= 70.0;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isHighAttention ? AppColors.saffronAccent : AppColors.border,
          width: 1.2,
        ),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.insights,
                size: 18,
                color: isHighAttention ? AppColors.saffronAccent : AppColors.primaryNavy,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  AppStrings.aiPotentialAnomaly,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: isHighAttention ? AppColors.saffronAccent : AppColors.textPrimary,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isHighAttention ? AppColors.statusWarningBg : Colors.white,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.border),
                ),
                child: Text(
                  '${AppStrings.aiAttentionScore}: ${score.toStringAsFixed(1)}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isHighAttention ? AppColors.statusWarning : AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            anomalySummary ??
                'Prior inspection discrepancies or operational variation detected. Physical visual inspection is recommended to verify current status.',
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.info_outline, size: 12, color: AppColors.textMuted),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  AppStrings.aiDisclaimer,
                  style: const TextStyle(
                    fontSize: 9.5,
                    fontStyle: FontStyle.italic,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
