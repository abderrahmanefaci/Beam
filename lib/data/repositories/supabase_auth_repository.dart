import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../services/supabase_service.dart';

/// Supabase implementation of AuthRepository
class SupabaseAuthRepository implements AuthRepository {
  SupabaseClient get _client => SupabaseService.client;

  @override
  User? get currentUser => _client.auth.currentUser;

  @override
  AuthSession? get currentSession => _client.auth.currentSession;

  @override
  bool get isAuthenticated => currentUser != null;

  @override
  Stream<AuthState> get onAuthStateChanges => _client.auth.onAuthStateChange;

  @override
  bool get isEmailVerified => currentUser?.emailConfirmedAt != null;

  @override
  Future<AuthResponse> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    return await _client.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
  }

  @override
  Future<AuthResponse> signUpWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    return await _client.auth.signUp(
      email: email.trim(),
      password: password,
    );
  }

  @override
  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    await _client.auth.resetPasswordForEmail(
      email.trim(),
      redirectTo: 'beam://reset-password',
    );
  }

  @override
  Future<void> updatePassword(String newPassword) async {
    await _client.auth.updateUser(
      UserAttributes(password: newPassword),
    );
  }

  @override
  Future<void> updateEmail(String newEmail) async {
    await _client.auth.updateUser(
      UserAttributes(email: newEmail.trim()),
    );
  }

  @override
  Future<void> sendEmailVerification() async {
    await currentUser?.reauthenticate();
    await currentUser?.updateEmail(currentUser!.email!);
  }
}
