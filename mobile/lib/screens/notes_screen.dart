import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_colors.dart';
import '../models/note_model.dart';
import '../providers/inspection_detail_provider.dart';

// =====================================================================
// DRISHTI Mobile App: Field Observations & Deficiencies Notes Screen
// Captures structured observations and follow-up items offline
// =====================================================================

class NotesScreen extends StatelessWidget {
  final String inspectionLocalId;

  const NotesScreen({Key? key, required this.inspectionLocalId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final detailProv = context.watch<InspectionDetailProvider>();
    final notes = detailProv.notes;

    return Column(
      children: [
        // Action toolbar
        Container(
          padding: const EdgeInsets.all(12),
          color: Colors.white,
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _showAddNoteDialog(context, detailProv),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryNavy,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(Icons.add_comment, size: 16),
                  label: const Text('ADD FIELD OBSERVATION / DEFICIENCY', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),

        // Notes list
        Expanded(
          child: notes.isEmpty
              ? _buildEmptyState(context, detailProv)
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: notes.length,
                  itemBuilder: (context, index) {
                    final note = notes[index];
                    return _buildNoteCard(note);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildNoteCard(NoteModel note) {
    Color tagColor;
    switch (note.category) {
      case 'DEFICIENCY':
        tagColor = AppColors.statusCritical;
        break;
      case 'FOLLOW_UP':
        tagColor = AppColors.statusWarning;
        break;
      case 'OBSERVATION':
      default:
        tagColor = AppColors.statusInfo;
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: tagColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    note.category,
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: tagColor),
                  ),
                ),
                const Spacer(),
                Text(
                  DateTime.tryParse(note.createdAt)?.toLocal().toString().split('.').first ?? note.createdAt,
                  style: const TextStyle(fontSize: 10.5, color: AppColors.textMuted),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              note.title,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 6),
            Text(
              note.content,
              style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, InspectionDetailProvider detailProv) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.note_alt_outlined, size: 56, color: AppColors.textMuted),
          const SizedBox(height: 16),
          const Text(
            'No Field Notes Recorded',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          const Text(
            'Record qualitative findings, maintenance issues, and required follow-ups.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => _showAddNoteDialog(context, detailProv),
            icon: const Icon(Icons.add, size: 16),
            label: const Text('CREATE FIRST NOTE'),
          ),
        ],
      ),
    );
  }

  void _showAddNoteDialog(BuildContext context, InspectionDetailProvider detailProv) {
    String selectedCategory = 'DEFICIENCY';
    final titleController = TextEditingController();
    final contentController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          title: const Text('Add Field Observation', style: TextStyle(fontSize: 15)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: selectedCategory,
                  decoration: const InputDecoration(
                    labelText: 'Classification',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'DEFICIENCY', child: Text('DEFICIENCY (Critical)')),
                    DropdownMenuItem(value: 'OBSERVATION', child: Text('OBSERVATION (General)')),
                    DropdownMenuItem(value: 'FOLLOW_UP', child: Text('FOLLOW-UP DIRECTIVE')),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setModalState(() => selectedCategory = val);
                    }
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Subject / Title',
                    hintText: 'e.g. Broken RO filtration unit in pantry',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: contentController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Detailed Notes',
                    hintText: 'Describe physical findings, staff responses, or corrective instructions...',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('CANCEL'),
            ),
            ElevatedButton(
              onPressed: () {
                if (titleController.text.trim().isEmpty || contentController.text.trim().isEmpty) {
                  return;
                }
                detailProv.addNote(
                  title: titleController.text.trim(),
                  content: contentController.text.trim(),
                  category: selectedCategory,
                );
                Navigator.of(ctx).pop();
              },
              child: const Text('SAVE TO LOCAL DB'),
            ),
          ],
        ),
      ),
    );
  }
}
