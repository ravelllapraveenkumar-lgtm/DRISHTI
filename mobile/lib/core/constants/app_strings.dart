// =====================================================================
// DRISHTI Mobile App: Standardized Application Strings
// Adheres strictly to Responsible AI phrasing & clear sync feedback
// =====================================================================

class AppStrings {
  static const String appName = 'DRISHTI Field Inspector';
  static const String appTagline =
      'Ministry of Social Justice and Empowerment (MoSJE)';
  static const String govtOfIndia = 'Government of India';

  // Responsible AI Phrasing (Mandatory compliance)
  static const String aiPotentialAnomaly = 'Potential anomaly detected';
  static const String aiAttentionScore = 'Attention score';
  static const String aiVerificationRecommended = 'Verification recommended';
  static const String aiDisclaimer =
      'AI insights provide advisory context for field inspection. They do not constitute final determinations or legal findings.';

  // Offline & Synchronization Banners
  static const String offlineNotice = 'Offline — changes saved locally.';
  static const String syncPending = 'Sync pending.';
  static const String syncCompleted = 'Sync completed.';
  static const String syncFailed = 'Sync failed — tap to retry.';
  static const String syncInProgress = 'Synchronizing with DRISHTI Central...';

  // Prototype / Demo Disclaimers
  static const String demoNotice =
      'PROTOTYPE DEMO MODE: Media metadata registered locally with SHA-256 hash. Cloud file upload is stubbed for evaluation.';
  static const String liveBackendLabel = 'LIVE FASTAPI BACKEND';
  static const String offlineCacheLabel = 'OFFLINE SQLITE CACHE';
}
