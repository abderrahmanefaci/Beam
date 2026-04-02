import 'package:supabase_flutter/supabase_flutter.dart';

/// Abstract repository interface for authentication operations
abstract class AuthRepository {
  /// Get current authenticated user
  User? get currentUser;

  /// Get current session
  AuthSession? get currentSession;

  /// Stream of auth state changes
  Stream<AuthState> get onAuthStateChanges;

  /// Check if user is authenticated
  bool get isAuthenticated;

  /// Sign in with email and password
  Future<AuthResponse> signInWithEmailAndPassword({
    required String email,
    required String password,
  });

  /// Sign up with email and password
  Future<AuthResponse> signUpWithEmailAndPassword({
    required String email,
    required String password,
  });

  /// Sign out
  Future<void> signOut();

  /// Send password reset email
  Future<void> sendPasswordResetEmail(String email);

  /// Update password
  Future<void> updatePassword(String newPassword);

  /// Update email
  Future<void> updateEmail(String newEmail);

  /// Send email verification
  Future<void> sendEmailVerification();

  /// Check if email is verified
  bool get isEmailVerified;
}
