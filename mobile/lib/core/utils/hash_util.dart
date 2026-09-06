import 'dart:convert';
import 'package:crypto/crypto.dart';

// =====================================================================
// DRISHTI Mobile App: Tamper-Evident SHA-256 Hashing Utility
// Generates standard 64-character hexadecimal checksums for evidence
// =====================================================================

class HashUtil {
  /// Computes SHA-256 hash from raw bytes (e.g. captured photo/video bytes).
  static String sha256FromBytes(List<int> bytes) {
    final digest = sha256.convert(bytes);
    return digest.toString(); // 64 hex characters
  }

  /// Computes SHA-256 hash from a string (useful for offline payload verification).
  static String sha256FromString(String text) {
    final bytes = utf8.encode(text);
    return sha256.convert(bytes).toString();
  }

  /// Generates synthetic/deterministic mock hash for demo tests if file bytes are simulated.
  static String generateDemoHash(String seed) {
    final bytes = utf8.encode('DRISHTI_FIELD_DEMO_${seed}_${DateTime.now().millisecondsSinceEpoch}');
    return sha256.convert(bytes).toString();
  }
}
