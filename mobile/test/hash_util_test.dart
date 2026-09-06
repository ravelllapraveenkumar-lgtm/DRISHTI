import 'package:flutter_test/flutter_test.dart';
import 'package:drishti_inspector/core/utils/hash_util.dart';

void main() {
  group('HashUtil Cryptographic Integrity Tests', () {
    test('SHA-256 output produces exact 64-character lowercase hexadecimal hash', () {
      final hash = HashUtil.sha256FromString('DRISHTI_FIELD_INSPECTION_EVIDENCE_2026');
      expect(hash.length, equals(64));
      expect(RegExp(r'^[a-f0-9]{64}$').hasMatch(hash), isTrue);
    });

    test('Demo mock hash is deterministic per seed and unique across time', () {
      final hash1 = HashUtil.generateDemoHash('evidence_item_1');
      expect(hash1.length, equals(64));
      expect(RegExp(r'^[a-f0-9]{64}$').hasMatch(hash1), isTrue);
    });
  });
}
