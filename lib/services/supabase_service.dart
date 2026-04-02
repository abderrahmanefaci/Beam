import 'package:supabase_flutter/supabase_flutter.dart';

/// Supabase Service - Handles all Supabase initialization and configuration
class SupabaseService {
  SupabaseService._();

  static SupabaseClient? _client;

  /// Initialize Supabase
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: const String.fromEnvironment('SUPABASE_URL'),
      anonKey: const String.fromEnvironment('SUPABASE_ANON_KEY'),
      debug: false,
    );
    
    _client = Supabase.instance.client;
  }

  /// Get Supabase client instance
  static SupabaseClient get client {
    if (_client == null) {
      throw Exception('Supabase not initialized. Call initialize() first.');
    }
    return _client!;
  }

  /// Check if user is authenticated
  static bool get isAuthenticated {
    return _client?.auth.currentUser != null;
  }

  /// Get current user
  static User? get currentUser {
    return _client?.auth.currentUser;
  }

  /// Get current session
  static AuthSession? get currentSession {
    return _client?.auth.currentSession;
  }

  /// Sign out
  static Future<void> signOut() async {
    await _client?.auth.signOut();
  }

  /// Stream auth state changes
  static Stream<AuthState> get onAuthStateChanges {
    return _client!.auth.onAuthStateChange;
  }
}
