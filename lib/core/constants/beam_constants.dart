/// App-wide constants for Beam
class BeamConstants {
  BeamConstants._();

  // App Info
  static const String appName = 'Beam';
  static const String appVersion = '1.0.0';
  
  // Storage Keys
  static const String hasSeenOnboardingKey = 'has_seen_onboarding';
  static const String themeModeKey = 'theme_mode';
  
  // File Limits
  static const int maxFileSize = 50 * 1024 * 1024; // 50MB
  static const int maxVersionsFree = 10;
  static const int maxVersionsPremium = -1; // Unlimited
  
  // AI Limits
  static const int freeAiDocumentsLimit = 3;
  static const int premiumCreditsMonthly = 50;
  static const int customAgentCreditCost = 3;
  static const int standardSkillCreditCost = 1;
  
  // Cache Settings
  static const int signedUrlCacheMinutes = 50; // Refresh before 60min expiry
  static const int aiResponseCacheHours = 24;
  
  // Pagination
  static const int libraryPageSize = 20;
  
  // Autosave
  static const int autosaveDebounceSeconds = 30;
  
  // Supported File Types
  static const List<String> supportedImageFormats = ['jpg', 'jpeg', 'png'];
  static const List<String> supportedDocumentFormats = ['pdf', 'docx', 'doc', 'txt', 'md'];
  static const List<String> supportedSpreadsheetFormats = ['xlsx', 'xls', 'csv'];
  static const List<String> supportedPresentationFormats = ['pptx', 'ppt'];
  
  // Output Formats for Scanner
  static const List<String> scannerOutputFormats = ['pdf', 'docx', 'jpg', 'png'];
  
  // Filter Options for Scanner
  static const List<String> scannerFilters = ['Original', 'Black & White', 'Enhanced', 'Color'];
}

/// Database table names
class DatabaseTables {
  DatabaseTables._();
  
  static const String users = 'users';
  static const String documents = 'documents';
  static const String folders = 'folders';
  static const String documentVersions = 'document_versions';
  static const String aiActions = 'ai_actions';
  static const String signatures = 'signatures';
  static const String subscriptions = 'subscriptions';
}

/// Storage bucket names
class StorageBuckets {
  StorageBuckets._();
  
  static const String documents = 'documents';
  static const String signatures = 'signatures';
  static const String avatars = 'avatars';
  static const String temp = 'temp';
}
