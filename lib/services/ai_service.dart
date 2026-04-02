import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../services/supabase_service.dart';

/// AI Action Types
enum AiActionType {
  summarize('summarize'),
  translate('translate'),
  extractText('extract_text'),
  extractTables('extract_tables'),
  chat('chat'),
  custom('custom');

  final String value;
  const AiActionType(this.value);

  static AiActionType? fromString(String value) {
    for (final type in AiActionType.values) {
      if (type.value == value) return type;
    }
    return null;
  }
}

/// AI Service - Handles all AI interactions via Edge Function
class AiService {
  static final AiService _instance = AiService._internal();
  factory AiService() => _instance;
  AiService._internal();

  final String _edgeFunctionUrl = 
      const String.fromEnvironment('SUPABASE_EDGE_FUNCTION_URL');

  /// Check if user can unlock AI for a document
  Future<Map<String, dynamic>> checkAiUnlockStatus({
    required String documentId,
    required bool isAiUnlocked,
  }) async {
    final user = SupabaseService.currentUser;
    if (user == null) {
      return {'canUnlock': false, 'reason': 'not_authenticated'};
    }

    // Get user data
    final userData = await SupabaseService.client
        .from('users')
        .select('plan, ai_docs_used, credits_remaining')
        .eq('id', user.id)
        .single();

    final plan = userData['plan'] as String;
    final aiDocsUsed = userData['ai_docs_used'] as int;
    final creditsRemaining = userData['credits_remaining'] as int;

    // Already unlocked or premium user
    if (isAiUnlocked || plan == 'premium') {
      return {'canUnlock': true, 'reason': 'already_unlocked'};
    }

    // Free user with remaining unlocks
    if (aiDocsUsed < 3) {
      return {'canUnlock': true, 'reason': 'free_tier_available'};
    }

    // Free user at limit
    return {
      'canUnlock': false,
      'reason': 'free_tier_limit_reached',
      'aiDocsUsed': aiDocsUsed,
      'creditsRemaining': creditsRemaining,
    };
  }

  /// Unlock AI for a document (increment ai_docs_used)
  Future<bool> unlockDocument(String documentId) async {
    try {
      final result = await SupabaseService.client.rpc('increment_ai_docs_used').call();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Call AI Edge Function
  Future<AiResponse> callAi({
    required AiActionType actionType,
    required String documentId,
    String? prompt,
    String? fileUrl,
    String? fileContent,
    String? language,
  }) async {
    final user = SupabaseService.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    final token = SupabaseService.currentSession?.accessToken;
    if (token == null) {
      throw Exception('No access token available');
    }

    final body = <String, dynamic>{
      'action_type': actionType.value,
      'doc_id': documentId,
      'user_id': user.id,
      if (prompt != null) 'prompt': prompt,
      if (fileUrl != null) 'file_url': fileUrl,
      if (fileContent != null) 'file_content': fileContent,
      if (language != null) 'language': language,
    };

    try {
      final response = await http.post(
        Uri.parse(_edgeFunctionUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return AiResponse.fromJson(data);
      } else if (response.statusCode == 403) {
        final error = jsonDecode(response.body) as Map<String, dynamic>;
        throw AiException(
          code: 'insufficient_credits',
          message: error['error'] as String? ?? 'Insufficient credits',
          upgradeRequired: error['upgrade_required'] as bool? ?? false,
        );
      } else {
        final error = jsonDecode(response.body) as Map<String, dynamic>;
        throw AiException(
          code: 'api_error',
          message: error['error'] as String? ?? 'AI service unavailable',
        );
      }
    } catch (e) {
      if (e is AiException) rethrow;
      throw AiException(
        code: 'network_error',
        message: 'Failed to connect to AI service. Check your connection.',
      );
    }
  }

  /// Summarize document
  Future<AiResponse> summarize({
    required String documentId,
    required String fileContent,
  }) async {
    return callAi(
      actionType: AiActionType.summarize,
      documentId: documentId,
      fileContent: fileContent,
      prompt: 'Summarize this document with: 1 paragraph overview, 5 key points, 3 key terms defined.',
    );
  }

  /// Translate document
  Future<AiResponse> translate({
    required String documentId,
    required String fileContent,
    required String language,
  }) async {
    return callAi(
      actionType: AiActionType.translate,
      documentId: documentId,
      fileContent: fileContent,
      language: language,
      prompt: 'Translate to $language. Preserve formatting.',
    );
  }

  /// Extract text from document
  Future<AiResponse> extractText({
    required String documentId,
    required String fileContent,
  }) async {
    return callAi(
      actionType: AiActionType.extractText,
      documentId: documentId,
      fileContent: fileContent,
    );
  }

  /// Extract tables from document
  Future<AiResponse> extractTables({
    required String documentId,
    required String fileContent,
  }) async {
    return callAi(
      actionType: AiActionType.extractTables,
      documentId: documentId,
      fileContent: fileContent,
    );
  }

  /// Chat about document
  Future<AiResponse> chat({
    required String documentId,
    required String message,
    required String fileContent,
  }) async {
    return callAi(
      actionType: AiActionType.chat,
      documentId: documentId,
      fileContent: fileContent,
      prompt: message,
    );
  }

  /// Custom AI request
  Future<AiResponse> customRequest({
    required String documentId,
    required String request,
    required String fileContent,
  }) async {
    return callAi(
      actionType: AiActionType.custom,
      documentId: documentId,
      fileContent: fileContent,
      prompt: request,
    );
  }
}

/// AI Response Model
class AiResponse {
  final String result;
  final int creditsRemaining;
  final String modelUsed;
  final int? tokensIn;
  final int? tokensOut;
  final bool? declined;
  final String? reason;

  AiResponse({
    required this.result,
    required this.creditsRemaining,
    required this.modelUsed,
    this.tokensIn,
    this.tokensOut,
    this.declined,
    this.reason,
  });

  factory AiResponse.fromJson(Map<String, dynamic> json) {
    return AiResponse(
      result: json['result'] as String? ?? '',
      creditsRemaining: json['credits_remaining'] as int? ?? 0,
      modelUsed: json['model_used'] as String? ?? 'unknown',
      tokensIn: json['tokens_in'] as int?,
      tokensOut: json['tokens_out'] as int?,
      declined: json['declined'] as bool?,
      reason: json['reason'] as String?,
    );
  }
}

/// AI Exception
class AiException implements Exception {
  final String code;
  final String message;
  final bool upgradeRequired;

  AiException({
    required this.code,
    required this.message,
    this.upgradeRequired = false,
  });

  @override
  String toString() => 'AiException($code): $message';
}

/// Supported languages for translation
class SupportedLanguage {
  final String code;
  final String name;
  final String nativeName;

  const SupportedLanguage({
    required this.code,
    required this.name,
    required this.nativeName,
  });

  static const List<SupportedLanguage> languages = [
    SupportedLanguage(code: 'es', name: 'Spanish', nativeName: 'Español'),
    SupportedLanguage(code: 'fr', name: 'French', nativeName: 'Français'),
    SupportedLanguage(code: 'de', name: 'German', nativeName: 'Deutsch'),
    SupportedLanguage(code: 'it', name: 'Italian', nativeName: 'Italiano'),
    SupportedLanguage(code: 'pt', name: 'Portuguese', nativeName: 'Português'),
    SupportedLanguage(code: 'ru', name: 'Russian', nativeName: 'Русский'),
    SupportedLanguage(code: 'ja', name: 'Japanese', nativeName: '日本語'),
    SupportedLanguage(code: 'ko', name: 'Korean', nativeName: '한국어'),
    SupportedLanguage(code: 'zh', name: 'Chinese (Simplified)', nativeName: '简体中文'),
    SupportedLanguage(code: 'zh-TW', name: 'Chinese (Traditional)', nativeName: '繁體中文'),
    SupportedLanguage(code: 'ar', name: 'Arabic', nativeName: 'العربية'),
    SupportedLanguage(code: 'hi', name: 'Hindi', nativeName: 'हिन्दी'),
    SupportedLanguage(code: 'nl', name: 'Dutch', nativeName: 'Nederlands'),
    SupportedLanguage(code: 'pl', name: 'Polish', nativeName: 'Polski'),
    SupportedLanguage(code: 'tr', name: 'Turkish', nativeName: 'Türkçe'),
    SupportedLanguage(code: 'sv', name: 'Swedish', nativeName: 'Svenska'),
    SupportedLanguage(code: 'da', name: 'Danish', nativeName: 'Dansk'),
    SupportedLanguage(code: 'fi', name: 'Finnish', nativeName: 'Suomi'),
    SupportedLanguage(code: 'no', name: 'Norwegian', nativeName: 'Norsk'),
    SupportedLanguage(code: 'cs', name: 'Czech', nativeName: 'Čeština'),
  ];

  String get displayName => '$name ($nativeName)';
}
