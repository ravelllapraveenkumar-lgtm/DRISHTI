import 'package:flutter_test/flutter_test.dart';
import 'package:drishti_inspector/models/evidence_model.dart';
import 'package:drishti_inspector/models/inspection_model.dart';
import 'package:drishti_inspector/models/report_model.dart';

void main() {
  group('Data Model & SQLite Serialization Tests', () {
    test('InspectionModel preserves localId vs serverId separation', () {
      final inspection = InspectionModel(
        localId: 'local_insp_001',
        serverId: 'uuid-1234-5678',
        inspectionCode: 'INSP-2026-001',
        institutionId: 'inst_01',
        institutionName: 'Prerna Vridh Ashram',
        institutionDistrict: 'Lucknow',
        institutionState: 'Uttar Pradesh',
        targetLatitude: 26.8467,
        targetLongitude: 80.9462,
        priority: 'URGENT',
        status: 'IN_PROGRESS',
        mandatedDate: '2026-03-01',
        dueDate: '2026-03-10',
        inspectionReason: 'Audit',
        aiAttentionScore: 78.4,
        cachedAt: DateTime.now().toIso8601String(),
      );

      final sqliteMap = inspection.toSqlite();
      expect(sqliteMap['local_id'], equals('local_insp_001'));
      expect(sqliteMap['server_id'], equals('uuid-1234-5678'));

      final restored = InspectionModel.fromSqlite(sqliteMap);
      expect(restored.localId, equals(inspection.localId));
      expect(restored.serverId, equals(inspection.serverId));
      expect(restored.aiAttentionScore, equals(78.4));
    });

    test('EvidenceModel generates correct backend JSON with parent server UUID', () {
      final evidence = EvidenceModel(
        localId: 'local_ev_1',
        inspectionLocalId: 'local_insp_1',
        evidenceType: 'GEO_TAGGED_PHOTO',
        fileName: 'kitchen.jpg',
        localFilePath: '/storage/emulated/0/kitchen.jpg',
        sha256Checksum: 'a' * 64,
        description: 'Sanitation inspection photo',
        gpsLatitude: 26.8467,
        gpsLongitude: 80.9462,
        gpsAccuracyMeters: 4.5,
        timestampCaptured: DateTime.now().toIso8601String(),
      );

      const serverInspectionUuid = '9876-uuid-abcd';
      final backendJson = evidence.toBackendJson(parentServerUuid: serverInspectionUuid);

      expect(backendJson['inspection_id'], equals(serverInspectionUuid));
      expect(backendJson['sha256_checksum'], equals('a' * 64));
      expect(backendJson['local_sqlite_id'], equals('local_ev_1'));
    });

    test('ReportModel serialized correctly to backend JSON', () {
      final report = ReportModel(
        localId: 'local_rep_1',
        inspectionLocalId: 'local_insp_1',
        physicalBeneficiaryCount: 45,
        rosterDiscrepancyCount: 3,
        cleanlinessScore: 8,
        foodNutritionScore: 7,
        infrastructureConditionScore: 9,
        inspectorSummary: 'Beneficiary headcount verified on-site.',
        overallVerdict: 'COMPLIANT',
        submissionTimestamp: DateTime.now().toIso8601String(),
      );

      final backendJson = report.toBackendJson(parentServerUuid: 'parent-server-uuid');
      expect(backendJson['inspection_id'], equals('parent-server-uuid'));
      expect(backendJson['physical_beneficiary_count'], equals(45));
      expect(backendJson['overall_verdict'], equals('COMPLIANT'));
    });
  });
}
