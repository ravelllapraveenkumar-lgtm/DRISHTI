import 'package:uuid/uuid.dart';
import '../models/checklist_model.dart';
import '../models/sync_item_model.dart';
import '../data/local/sqlite_database_helper.dart';
import '../data/remote/remote_data_source.dart';

// =====================================================================
// DRISHTI Mobile App: Checklist Repository
// Supports offline draft saving, template preloading & sync queuing
// =====================================================================

class ChecklistRepository {
  final RemoteDataSource _remoteDataSource;
  final SqliteDatabaseHelper _dbHelper;
  final Uuid _uuid = const Uuid();

  ChecklistRepository({
    RemoteDataSource? remoteDataSource,
    SqliteDatabaseHelper? dbHelper,
  })  : _remoteDataSource = remoteDataSource ?? RemoteDataSource(),
        _dbHelper = dbHelper ?? SqliteDatabaseHelper.instance;

  Future<List<ChecklistItemModel>> getChecklistItems() async {
    // 1. Check local cache first
    var cachedItems = await _dbHelper.getAllCachedChecklistItems();
    if (cachedItems.isNotEmpty) {
      return cachedItems;
    }

    // 2. Try remote sync
    try {
      final remoteTemplates = await _remoteDataSource.getChecklistTemplates();
      if (remoteTemplates.isNotEmpty) {
        await _dbHelper.saveChecklistTemplates(remoteTemplates);
        cachedItems = await _dbHelper.getAllCachedChecklistItems();
        if (cachedItems.isNotEmpty) return cachedItems;
      }
    } catch (_) {
      // Offline fallback
    }

    // 3. Fallback default statutory MoSJE checklist items if DB is fresh
    final defaultItems = _getDefaultStatutoryItems();
    final defaultTemplate = ChecklistTemplateModel(
      id: 'tmpl-mosje-standard',
      name: 'MoSJE Standard Field Compliance Checklist',
      schemeCategory: 'ALL',
      version: 1,
      items: defaultItems,
    );
    await _dbHelper.saveChecklistTemplates([defaultTemplate]);
    return defaultItems;
  }

  Future<List<ChecklistResponseModel>> getResponses(String inspectionLocalId) async {
    return await _dbHelper.getResponsesForInspection(inspectionLocalId);
  }

  Future<void> saveDraftResponses(List<ChecklistResponseModel> responses) async {
    await _dbHelper.saveChecklistResponses(responses);
  }

  Future<void> submitChecklist({
    required String inspectionLocalId,
    String? inspectionServerId,
    required List<ChecklistResponseModel> responses,
  }) async {
    // 1. Persist locally with PENDING status
    await _dbHelper.saveChecklistResponses(responses);

    // 2. Enqueue in Outbox
    final syncItem = SyncItemModel(
      id: 'sync_chk_${_uuid.v4()}',
      entityType: 'CHECKLIST_SUBMISSION',
      entityLocalId: inspectionLocalId,
      parentServerId: inspectionServerId,
      endpoint: '/api/v1/inspection-checklists',
      httpMethod: 'POST',
      payloadJson: '',
      createdAt: DateTime.now().toIso8601String(),
    );
    await _dbHelper.enqueueSyncItem(syncItem);

    // 3. Opportunistic instant submission if server ID is resolved and network is active
    if (inspectionServerId != null && inspectionServerId.isNotEmpty) {
      try {
        final payloadList = responses.map((r) => r.toApiPayload(inspectionServerId)).toList();
        await _remoteDataSource.submitChecklistResponses(
          inspectionId: inspectionServerId,
          items: payloadList,
        );

        await _dbHelper.updateSyncItemStatus(id: syncItem.id, syncStatus: 'SYNCED');
        for (final r in responses) {
          final updated = r.copyWith(syncStatus: 'SYNCED');
          await _dbHelper.saveChecklistResponses([updated]);
        }
      } catch (_) {
        // Preserved in queue for background sync engine
      }
    }
  }

  List<ChecklistItemModel> _getDefaultStatutoryItems() {
    return [
      ChecklistItemModel(
        id: 'item-1',
        templateId: 'tmpl-mosje-standard',
        sectionName: 'Living Conditions & Hygiene',
        itemQuestion: 'Dormitories have adequate spacing (minimum 40 sq ft per resident) and natural ventilation?',
        fieldType: 'BOOLEAN',
        isMandatory: true,
        guidanceNotes: 'Inspect bed spacing and window openings.',
        orderIndex: 1,
      ),
      ChecklistItemModel(
        id: 'item-2',
        templateId: 'tmpl-mosje-standard',
        sectionName: 'Living Conditions & Hygiene',
        itemQuestion: 'Sanitary facilities are clean, functional, and gender-segregated?',
        fieldType: 'BOOLEAN',
        isMandatory: true,
        guidanceNotes: 'Check water supply, soap, and accessible toilets.',
        orderIndex: 2,
      ),
      ChecklistItemModel(
        id: 'item-3',
        templateId: 'tmpl-mosje-standard',
        sectionName: 'Nutrition & Food Quality',
        itemQuestion: 'Weekly meal menu is displayed and matches dietary norms mandated by MoSJE guidelines?',
        fieldType: 'BOOLEAN',
        isMandatory: true,
        guidanceNotes: 'Review pantry stock and daily cooked food registers.',
        orderIndex: 3,
      ),
      ChecklistItemModel(
        id: 'item-4',
        templateId: 'tmpl-mosje-standard',
        sectionName: 'Healthcare & Medical Attention',
        itemQuestion: 'First-aid box is fully stocked and regular doctor visits are logged in health register?',
        fieldType: 'BOOLEAN',
        isMandatory: true,
        guidanceNotes: 'Verify expiry dates of critical medications.',
        orderIndex: 4,
      ),
      ChecklistItemModel(
        id: 'item-5',
        templateId: 'tmpl-mosje-standard',
        sectionName: 'Infrastructure & Safety',
        itemQuestion: 'Fire safety extinguishers are within certified valid service dates and emergency exits are unobstructed?',
        fieldType: 'BOOLEAN',
        isMandatory: true,
        guidanceNotes: 'Check extinguisher gauge pressure and exit pathways.',
        orderIndex: 5,
      ),
      ChecklistItemModel(
        id: 'item-6',
        templateId: 'tmpl-mosje-standard',
        sectionName: 'Accessibility & Barrier-Free Access',
        itemQuestion: 'Wheelchair access ramps with handrails are present at main entryways and restrooms?',
        fieldType: 'BOOLEAN',
        isMandatory: true,
        guidanceNotes: 'Mandatory under Rights of Persons with Disabilities (RPwD) Act 2016.',
        orderIndex: 6,
      ),
      ChecklistItemModel(
        id: 'item-7',
        templateId: 'tmpl-mosje-standard',
        sectionName: 'Documentation & Governance',
        itemQuestion: 'Physical headcount matches biometric attendance logs and admission register?',
        fieldType: 'BOOLEAN',
        isMandatory: true,
        guidanceNotes: 'Count actual beneficiaries present on-site during surprise visit.',
        orderIndex: 7,
      ),
    ];
  }
}
