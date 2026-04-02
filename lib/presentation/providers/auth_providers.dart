import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../data/repositories/supabase_auth_repository.dart';

/// Provider for AuthRepository
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return SupabaseAuthRepository();
});

/// Provider for authentication state (boolean)
final authStateProvider = StreamProvider<bool>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  return authRepository.onAuthStateChanges.map((state) {
    return authRepository.isAuthenticated;
  });
});

/// Provider for current user ID
final currentUserIdProvider = Provider<String?>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  return authRepository.currentUser?.id;
});

/// Provider for email verification status
final emailVerifiedProvider = Provider<bool>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  return authRepository.isEmailVerified;
});
