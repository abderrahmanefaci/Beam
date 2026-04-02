import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/user_repository.dart';
import '../../data/repositories/supabase_user_repository.dart';
import 'auth_providers.dart';

/// Provider for UserRepository
final userRepositoryProvider = Provider<UserRepository>((ref) {
  return SupabaseUserRepository();
});

/// Provider for current user data
final currentUserProvider = StreamProvider<UserEntity?>((ref) {
  final userRepository = ref.watch(userRepositoryProvider);
  final authState = ref.watch(authStateProvider);

  // Only subscribe to user stream when authenticated
  return authState.when(
    data: (isAuthenticated) {
      if (!isAuthenticated) return Stream.value(null);
      return userRepository.userStream;
    },
    loading: () => Stream.value(null),
    error: (_, __) => Stream.value(null),
  );
});

/// Provider for user's plan (free/premium)
final userPlanProvider = Provider<String?>((ref) {
  final userAsync = ref.watch(currentUserProvider);
  return userAsync.when(
    data: (user) => user?.plan,
    loading: () => null,
    error: (_, __) => null,
  );
});

/// Provider for AI docs used count
final aiDocsUsedProvider = Provider<int>((ref) {
  final userAsync = ref.watch(currentUserProvider);
  return userAsync.when(
    data: (user) => user?.aiDocsUsed ?? 0,
    loading: () => 0,
    error: (_, __) => 0,
  );
});

/// Provider for credits remaining
final creditsRemainingProvider = Provider<int>((ref) {
  final userAsync = ref.watch(currentUserProvider);
  return userAsync.when(
    data: (user) => user?.creditsRemaining ?? 0,
    loading: () => 0,
    error: (_, __) => 0,
  );
});

/// Provider for storage used in bytes
final storageUsedProvider = Provider<int>((ref) {
  final userAsync = ref.watch(currentUserProvider);
  return userAsync.when(
    data: (user) => user?.storageUsedBytes ?? 0,
    loading: () => 0,
    error: (_, __) => 0,
  );
});

/// Provider to check if user can unlock more AI documents
final canUnlockAiDocumentProvider = Provider<bool>((ref) {
  final userAsync = ref.watch(currentUserProvider);
  return userAsync.when(
    data: (user) => user?.canUnlockAiDocument ?? false,
    loading: () => false,
    error: (_, __) => false,
  );
});

/// Provider for remaining AI unlocks
final remainingAiUnlocksProvider = Provider<int>((ref) {
  final userAsync = ref.watch(currentUserProvider);
  return userAsync.when(
    data: (user) => user?.remainingAiUnlocks ?? 0,
    loading: () => 0,
    error: (_, __) => 0,
  );
});

/// Notifier for user actions
class UserNotifier extends AutoDisposeNotifier<UserEntity?> {
  @override
  UserEntity? build() {
    return null;
  }

  /// Refresh user data
  Future<void> refresh() async {
    final userRepository = ref.read(userRepositoryProvider);
    state = await userRepository.getCurrentUser();
  }

  /// Update user profile
  Future<void> updateProfile({
    String? displayName,
    String? avatarUrl,
  }) async {
    final userRepository = ref.read(userRepositoryProvider);
    state = await userRepository.updateProfile(
      displayName: displayName,
      avatarUrl: avatarUrl,
    );
  }

  /// Increment AI docs used
  Future<void> incrementAiDocsUsed() async {
    final userRepository = ref.read(userRepositoryProvider);
    final newCount = await userRepository.incrementAiDocsUsed();
    if (state != null) {
      state = state!.copyWith(aiDocsUsed: newCount);
    }
  }

  /// Deduct credits
  Future<void> deductCredits(int amount) async {
    final userRepository = ref.read(userRepositoryProvider);
    final newCredits = await userRepository.deductCredits(amount);
    if (state != null) {
      state = state!.copyWith(creditsRemaining: newCredits);
    }
  }

  /// Add credits
  Future<void> addCredits(int amount) async {
    final userRepository = ref.read(userRepositoryProvider);
    final newCredits = await userRepository.addCredits(amount);
    if (state != null) {
      state = state!.copyWith(creditsRemaining: newCredits);
    }
  }
}

/// Provider for UserNotifier
final userNotifierProvider = AutoDisposeNotifierProvider<UserNotifier, UserEntity?>(() {
  return UserNotifier();
});
