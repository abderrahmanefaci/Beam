import '../entities/entities.dart';

/// Abstract repository interface for user operations
abstract class UserRepository {
  /// Get current user data
  Future<UserEntity?> getCurrentUser();

  /// Get user by ID
  Future<UserEntity?> getUserById(String userId);

  /// Update user profile
  Future<UserEntity> updateProfile({
    String? displayName,
    String? avatarUrl,
  });

  /// Update user plan
  Future<UserEntity> updatePlan(String plan);

  /// Increment AI docs used counter
  Future<int> incrementAiDocsUsed();

  /// Deduct credits
  Future<int> deductCredits(int amount);

  /// Add credits
  Future<int> addCredits(int amount);

  /// Update storage used
  Future<void> updateStorageUsed(int bytesUsed);

  /// Delete user account (and all associated data)
  Future<void> deleteAccount();

  /// Stream user data changes
  Stream<UserEntity?> get userStream;
}
