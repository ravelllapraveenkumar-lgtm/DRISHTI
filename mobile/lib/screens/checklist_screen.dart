import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_colors.dart';
import '../models/checklist_model.dart';
import '../providers/inspection_detail_provider.dart';

// =====================================================================
// DRISHTI Mobile App: Field Inspection Checklist Screen
// Offline-first responsive checklist grouped by administrative sections
// =====================================================================

class ChecklistScreen extends StatefulWidget {
  final String inspectionLocalId;

  const ChecklistScreen({Key? key, required this.inspectionLocalId}) : super(key: key);

  @override
  State<ChecklistScreen> createState() => _ChecklistScreenState();
}

class _ChecklistScreenState extends State<ChecklistScreen> {
  // Built-in fallback questions if templates have not yet cached from server
  final List<ChecklistItemModel> _defaultQuestions = [
    ChecklistItemModel(
      id: 'chk_default_01',
      templateId: 'tpl_general',
      sectionName: 'Sanitation & Hygiene',
      itemQuestion: 'Are premises, washrooms, and common areas clean and sanitary?',
      fieldType: 'BOOLEAN',
      guidanceNotes: 'Inspect toilets, kitchen disposal, and drinking water source.',
      orderIndex: 1,
    ),
    ChecklistItemModel(
      id: 'chk_default_02',
      templateId: 'tpl_general',
      sectionName: 'Sanitation & Hygiene',
      itemQuestion: 'Is potable drinking water with water testing certificate available?',
      fieldType: 'BOOLEAN',
      guidanceNotes: 'Check RO filter or municipal water supply records.',
      orderIndex: 2,
    ),
    ChecklistItemModel(
      id: 'chk_default_03',
      templateId: 'tpl_general',
      sectionName: 'Safety & Infrastructure',
      itemQuestion: 'Are functional fire extinguishers and emergency exits unblocked?',
      fieldType: 'BOOLEAN',
      guidanceNotes: 'Verify expiry date tags on fire safety cylinders.',
      orderIndex: 3,
    ),
    ChecklistItemModel(
      id: 'chk_default_04',
      templateId: 'tpl_general',
      sectionName: 'Safety & Infrastructure',
      itemQuestion: 'Is CCTV surveillance operating with mandated 30-day backup recording?',
      fieldType: 'BOOLEAN',
      guidanceNotes: 'Inspect DVR/NVR storage status on-site.',
      orderIndex: 4,
    ),
    ChecklistItemModel(
      id: 'chk_default_05',
      templateId: 'tpl_general',
      sectionName: 'Nutritional Standards',
      itemQuestion: 'Does the daily food menu strictly adhere to MoSJE nutritional guidelines?',
      fieldType: 'BOOLEAN',
      guidanceNotes: 'Check weekly meal chart and kitchen pantry inventory.',
      orderIndex: 5,
    ),
    ChecklistItemModel(
      id: 'chk_default_06',
      templateId: 'tpl_general',
      sectionName: 'Roster & Staffing',
      itemQuestion: 'Does the physical headcount of beneficiaries match the biometric register?',
      fieldType: 'BOOLEAN',
      guidanceNotes: 'Flag discrepancies in discrepancy count field.',
      orderIndex: 6,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final detailProv = context.watch<InspectionDetailProvider>();
    final items = detailProv.checklistItems.isNotEmpty
        ? detailProv.checklistItems
        : _defaultQuestions;

    // Group items by sectionName
    final Map<String, List<ChecklistItemModel>> grouped = {};
    for (final item in items) {
      grouped.putIfAbsent(item.sectionName, () => []).add(item);
    }

    return Column(
      children: [
        // Offline Autosave banner
        Container(
          width: double.infinity,
          color: AppColors.surfaceVariant,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              const Icon(Icons.offline_pin, size: 16, color: AppColors.statusSuccess),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Offline Mode: Each response is immediately saved to local SQLite.',
                  style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                ),
              ),
              Text(
                '${detailProv.responses.length}/${items.length} Answered',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primaryNavy),
              ),
            ],
          ),
        ),

        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: grouped.keys.length,
            itemBuilder: (context, sectionIndex) {
              final sectionName = grouped.keys.elementAt(sectionIndex);
              final sectionQuestions = grouped[sectionName]!;

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Section Header
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: const BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.folder_special, size: 16, color: AppColors.primaryNavy),
                          const SizedBox(width: 8),
                          Text(
                            sectionName,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryNavy,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Questions in section
                    ...sectionQuestions.map((q) => _buildQuestionTile(q, detailProv)).toList(),
                  ],
                ),
              );
            },
          ),
        ),

        // Bottom action bar
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: AppColors.border)),
          ),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () async {
                await detailProv.queueChecklistBatchForSync();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Checklist batch queued for synchronization.')),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryNavy,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              icon: const Icon(Icons.cloud_upload_outlined, size: 18),
              label: const Text('QUEUE CHECKLIST BATCH FOR SYNC'),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuestionTile(ChecklistItemModel question, InspectionDetailProvider prov) {
    final response = prov.responses[question.id];
    final bool? isCompliant = response?.responseBoolean;

    return Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question.itemQuestion,
            style: const TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          if (question.guidanceNotes != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'Guidance: ${question.guidanceNotes!}',
                style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
              ),
            ),
          const SizedBox(height: 10),

          // Compliance Selector Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    prov.recordChecklistResponse(item: question, compliant: true);
                  },
                  style: OutlinedButton.styleFrom(
                    backgroundColor: isCompliant == true ? AppColors.statusSuccessBg : Colors.white,
                    side: BorderSide(
                      color: isCompliant == true ? AppColors.statusSuccess : AppColors.border,
                      width: isCompliant == true ? 1.5 : 1.0,
                    ),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: Icon(
                    Icons.check_circle,
                    size: 16,
                    color: isCompliant == true ? AppColors.statusSuccess : AppColors.textMuted,
                  ),
                  label: Text(
                    'Compliant',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isCompliant == true ? FontWeight.bold : FontWeight.normal,
                      color: isCompliant == true ? AppColors.statusSuccess : AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    prov.recordChecklistResponse(item: question, compliant: false);
                  },
                  style: OutlinedButton.styleFrom(
                    backgroundColor: isCompliant == false ? AppColors.statusCriticalBg : Colors.white,
                    side: BorderSide(
                      color: isCompliant == false ? AppColors.statusCritical : AppColors.border,
                      width: isCompliant == false ? 1.5 : 1.0,
                    ),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: Icon(
                    Icons.cancel,
                    size: 16,
                    color: isCompliant == false ? AppColors.statusCritical : AppColors.textMuted,
                  ),
                  label: Text(
                    'Non-Compliant',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isCompliant == false ? FontWeight.bold : FontWeight.normal,
                      color: isCompliant == false ? AppColors.statusCritical : AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Optional inspector observation / comment note field
          const SizedBox(height: 8),
          InkWell(
            onTap: () => _showObservationDialog(context, question, response?.inspectorComment),
            child: Row(
              children: [
                const Icon(Icons.edit_note, size: 16, color: AppColors.primaryNavy),
                const SizedBox(width: 4),
                Text(
                  response?.inspectorComment != null && response!.inspectorComment!.isNotEmpty
                      ? 'Remark: "${response.inspectorComment}"'
                      : 'Add deficiency remark / comment',
                  style: TextStyle(
                    fontSize: 11,
                    color: response?.inspectorComment != null ? AppColors.textPrimary : AppColors.primaryNavy,
                    fontStyle: response?.inspectorComment != null ? FontStyle.italic : FontStyle.normal,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 16),
        ],
      ),
    );
  }

  void _showObservationDialog(
    BuildContext context,
    ChecklistItemModel question,
    String? currentComment,
  ) {
    final controller = TextEditingController(text: currentComment);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Inspector Remark', style: TextStyle(fontSize: 15)),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Enter observation, discrepancy, or deficiency details...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () {
              final prov = context.read<InspectionDetailProvider>();
              prov.recordChecklistResponse(
                item: question,
                comment: controller.text.trim(),
              );
              Navigator.of(ctx).pop();
            },
            child: const Text('SAVE REMARK'),
          ),
        ],
      ),
    );
  }
}
