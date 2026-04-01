import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:beam/core/services/supabase_service.dart';

class AIService {
  final SupabaseClient _client = SupabaseService.client;

  // Simulate AI router - in production this would be an Edge Function
  Future<Map<String, dynamic>> processAIRequest({
    required String task,
    required String content,
  }) async {
    // Check usage limits first
    final canProceed = await _checkUsageLimits(task);
    if (!canProceed) {
      throw Exception('PAYWALL: Usage limit exceeded. Please upgrade your plan.');
    }

    // Simulate AI processing with fallback logic
    Map<String, dynamic> result;
    try {
      // Try cheapest model first (simulate Gemini Flash)
      result = await _callAIProvider('gemini-flash', task, content);
    } catch (e) {
      // Fallback to GPT-4o Mini
      try {
        result = await _callAIProvider('gpt-4o-mini', task, content);
      } catch (fallbackError) {
        throw Exception('AI service temporarily unavailable');
      }
    }

    // Track usage
    await _trackUsage(task);

    return result;
  }

  Future<Map<String, dynamic>> _callAIProvider(String provider, String task, String content) async {
    // Simulate API calls - in production, use actual AI provider APIs
    await Future.delayed(const Duration(seconds: 2)); // Simulate network delay

    // Mock responses based on task
    String mockResult;
    int tokensUsed;

    switch (task) {
      case 'summarize':
        mockResult = 'This is a summary of the provided content: ${content.substring(0, 100)}...';
        tokensUsed = 150;
        break;
      case 'chat_doc':
        mockResult = 'Based on the document, I can help you with questions about: ${content.substring(0, 50)}...';
        tokensUsed = 200;
        break;
      case 'translate':
        mockResult = 'Translated content: [English] ${content}';
        tokensUsed = 100;
        break;
      case 'extract_text':
        mockResult = 'Extracted text: ${content.replaceAll(RegExp(r'[^\w\s]'), '')}';
        tokensUsed = 80;
        break;
      case 'solve_homework':
        mockResult = 'Homework solution: Based on the problem "${content.substring(0, 50)}...", the answer is...';
        tokensUsed = 300;
        break;
      default:
        throw Exception('Unsupported task: $task');
    }

    // Simulate occasional failures for fallback testing
    if (provider == 'gemini-flash' && DateTime.now().second % 3 == 0) {
      throw Exception('Gemini Flash temporarily unavailable');
    }

    return {
      'result': mockResult,
      'model_used': provider,
      'tokens_used': tokensUsed,
    };
  }

  Future<bool> _checkUsageLimits(String task) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return false;

    // Define limits (in production, fetch from user plan)
    final limits = {
      'summarize': 5,
      'chat_doc': 3,
      'translate': 2,
      'extract_text': 2,
      'solve_homework': 1,
    };

    final limit = limits[task] ?? 0;

    // Get current usage
    final usageResponse = await _client
        .from('usage')
        .select('count')
        .eq('user_id', userId)
        .eq('action_type', task)
        .single();

    final currentUsage = usageResponse['count'] as int? ?? 0;

    return currentUsage < limit;
  }

  Future<void> _trackUsage(String task) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    // Check if usage record exists
    final existing = await _client
        .from('usage')
        .select('id, count')
        .eq('user_id', userId)
        .eq('action_type', task)
        .maybeSingle();

    if (existing != null) {
      // Update existing
      await _client
          .from('usage')
          .update({'count': existing['count'] + 1, 'updated_at': DateTime.now().toIso8601String()})
          .eq('id', existing['id']);
    } else {
      // Create new
      await _client
          .from('usage')
          .insert({
            'user_id': userId,
            'action_type': task,
            'count': 1,
          });
    }
  }

  Future<Map<String, int>> getUsageStats() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return {};

    final response = await _client
        .from('usage')
        .select('action_type, count')
        .eq('user_id', userId);

    final stats = <String, int>{};
    for (final item in response) {
      stats[item['action_type'] as String] = item['count'] as int;
    }

    return stats;
  }
}