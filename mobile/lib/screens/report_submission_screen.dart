import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_colors.dart';
import '../providers/inspection_detail_provider.dart';

// =====================================================================
// DRISHTI Mobile App: Consolidated Final Report Submission Screen
// Submits beneficiary headcounts, facility rating scores, and verdicts
// =====================================================================

class ReportSubmissionScreen extends StatefulWidget {
  final String inspectionLocalId;

  const ReportSubmissionScreen({Key? key, required this.inspectionLocalId}) : super(key: key);

  @override
  State<ReportSubmissionScreen> createState() => _ReportSubmissionScreenState();
}

class _ReportSubmissionScreenState extends State<ReportSubmissionScreen> {
  final _beneficiaryController = TextEditingController(text: '48');
  final _discrepancyController = TextEditingController(text: '2');
  final _summaryController = TextEditingController(
    text: 'Physical audit completed on-site. Beneficiary attendance largely corresponds with records. Kitchen hygiene requires minor improvements. Fire safety equipment verified.',
  );

  double _cleanlinessScore = 8.0;
  double _nutritionScore = 7.0;
  double _infraScore = 8.0;
  String _overallVerdict = 'COMPLIANT';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final draft = context.read<InspectionDetailProvider>().reportDraft;
      if (draft != null) {
        setState(() {
          _beneficiaryController.text = draft.physicalBeneficiaryCount.toString();
          _discrepancyController.text = draft.rosterDiscrepancyCount.toString();
          _cleanlinessScore = (draft.cleanlinessScore ?? 8).toDouble();
          _nutritionScore = (draft.foodNutritionScore ?? 7).toDouble();
          _infraScore = (draft.infrastructureConditionScore ?? 8).toDouble();
          _summaryController.text = draft.inspectorSummary;
          _overallVerdict = draft.overallVerdict;
        });
      }
    });
  }

  @override
  void dispose() {
    _beneficiaryController.dispose();
    _discrepancyController.dispose();
    _summaryController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    final summary = _summaryController.text.trim();
    if (summary.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Inspector summary must be at least 10 characters long.')),
      );
      return;
    }

    final physicalCount = int.tryParse(_beneficiaryController.text.trim()) ?? 0;
    final discrepancyCount = int.tryParse(_discrepancyController.text.trim()) ?? 0;

    final prov = context.read<InspectionDetailProvider>();
    await prov.submitReportDraft(
      physicalCount: physicalCount,
      discrepancyCount: discrepancyCount,
      cleanlinessScore: _cleanlinessScore.toInt(),
      nutritionScore: _nutritionScore.toInt(),
      infraScore: _infraScore.toInt(),
      summary: summary,
      verdict: _overallVerdict,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Report saved to local database and queued for synchronization.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final detailProv = context.watch<InspectionDetailProvider>();
    final draft = detailProv.reportDraft;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Submission status banner if already submitted
          if (draft != null)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: draft.syncStatus == 'SYNCED'
                    ? AppColors.statusSuccessBg
                    : AppColors.statusWarningBg,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: draft.syncStatus == 'SYNCED'
                      ? AppColors.statusSuccess
                      : AppColors.statusWarning,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    draft.syncStatus == 'SYNCED' ? Icons.check_circle : Icons.schedule,
                    color: draft.syncStatus == 'SYNCED'
                        ? AppColors.statusSuccess
                        : AppColors.statusWarning,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      draft.syncStatus == 'SYNCED'
                          ? 'Final report verified and submitted to DRISHTI Central.'
                          : 'Report draft saved locally. Queued in outbox sync.',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: draft.syncStatus == 'SYNCED'
                            ? AppColors.statusSuccess
                            : AppColors.statusWarning,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Headcount Section
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
                  'Physical Headcount Verification',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _beneficiaryController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Physical Beneficiaries Present',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _discrepancyController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Roster Discrepancies',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Rating Scores (1-10)
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
                  'Facility Condition Scores (Scale: 1 to 10)',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 16),

                _buildScoreSlider(
                  label: 'Cleanliness & Sanitation',
                  value: _cleanlinessScore,
                  onChanged: (v) => setState(() => _cleanlinessScore = v),
                ),
                const SizedBox(height: 12),

                _buildScoreSlider(
                  label: 'Food Quality & Nutrition',
                  value: _nutritionScore,
                  onChanged: (v) => setState(() => _nutritionScore = v),
                ),
                const SizedBox(height: 12),

                _buildScoreSlider(
                  label: 'Infrastructure & Safety',
                  value: _infraScore,
                  onChanged: (v) => setState(() => _infraScore = v),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Overall Verdict Selection
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
                  'Inspector Determination / Verdict',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _overallVerdict,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'COMPLIANT',
                      child: Text('COMPLIANT (Meets standards)', style: TextStyle(color: AppColors.statusSuccess)),
                    ),
                    DropdownMenuItem(
                      value: 'MINOR_NON_COMPLIANCE',
                      child: Text('MINOR NON-COMPLIANCE (Advisory notice)', style: TextStyle(color: AppColors.statusWarning)),
                    ),
                    DropdownMenuItem(
                      value: 'CRITICAL_IRREGULARITIES',
                      child: Text('CRITICAL IRREGULARITIES (Immediate rectification)', style: TextStyle(color: AppColors.statusCritical)),
                    ),
                    DropdownMenuItem(
                      value: 'SHOW_CAUSE_RECOMMENDED',
                      child: Text('SHOW-CAUSE RECOMMENDED (Statutory hearing)', style: TextStyle(color: AppColors.statusCritical)),
                    ),
                  ],
                  onChanged: (v) {
                    if (v != null) setState(() => _overallVerdict = v);
                  },
                ),
                const SizedBox(height: 16),

                // Inspector Summary
                const Text(
                  'Consolidated Summary & Recommendations',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _summaryController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    hintText: 'Enter complete summary of physical findings, verified headcounts, and recommendations...',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Submit Actions
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: detailProv.isLoading ? null : _handleSubmit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryNavy,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              icon: const Icon(Icons.assignment_turned_in, size: 20),
              label: Text(
                draft != null ? 'UPDATE & RE-SUBMIT REPORT' : 'SUBMIT INSPECTION REPORT',
                style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildScoreSlider({
    required String label,
    required double value,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.primaryNavy,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '${value.toInt()} / 10',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          ],
        ),
        Slider(
          value: value,
          min: 1.0,
          max: 10.0,
          divisions: 9,
          activeColor: AppColors.primaryNavy,
          inactiveColor: AppColors.surfaceVariant,
          onChanged: onChanged,
        ),
      ],
    );
  }
}
