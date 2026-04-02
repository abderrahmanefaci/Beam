import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants/beam_constants.dart';
import '../../domain/entities/entities.dart';
import '../../domain/repositories/user_repository.dart';
import '../../services/supabase_service.dart';
import '../models/user_model.dart';

/// Supabase implementation of UserRepository
class SupabaseUserRepository implements UserRepository {
  SupabaseClient get _client => SupabaseService.client;

  @override
  Future<UserEntity?> getCurrentUser() async {
    final userId = SupabaseService.currentUser?.id;
    if (userId == null) return null;

    try {
      final response = await _client
          .from(DatabaseTables.users)
          .select()
          .eq('id', userId)
          .single();

      if (response == null) return null;

      return _mapToEntity(UserModel.fromJson(response));
    } catch (e) {
      return null;
    }
  }

  @override
  Future<UserEntity?> getUserById(String userId) async {
    try {
      final response = await _client
          .from(DatabaseTables.users)
          .select()
          .eq('id', userId)
          .single();

      if (response == null) return null;

      return _mapToEntity(UserModel.fromJson(response));
    } catch (e) {
      return null;
    }
  }

  @override
  Future<UserEntity> updateProfile({
    String? displayName,
    String? avatarUrl,
  }) async {
    final userId = SupabaseService.currentUser?.id;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    final updateData = <String, dynamic>{};
    if (displayName != null) updateData['display_name'] = displayName;
    if (avatarUrl != null) updateData['avatar_url'] = avatarUrl;
    updateData['updated_at'] = DateTime.now().toIso8601String();

    final response = await _client
        .from(DatabaseTables.users)
        .update(updateData)
        .eq('id', userId)
        .select()
        .single();

    return _mapToEntity(UserModel.fromJson(response));
  }

  @override
  Future<UserEntity> updatePlan(String plan) async {
    final userId = SupabaseService.currentUser?.id;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    final response = await _client
        .from(DatabaseTables.users)
        .update({
          'plan': plan,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', userId)
        .select()
        .single();

    return _mapToEntity(UserModel.fromJson(response));
  }

  @override
  Future<int> incrementAiDocsUsed() async {
    final userId = SupabaseService.currentUser?.id;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    // Call the RPC function
    final result = await _client.rpc('increment_ai_docs_used').call();

    // Fetch updated user data
    final user = await getCurrentUser();
    if (user == null) {
      throw Exception('Failed to fetch updated user data');
    }

    return user.aiDocsUsed;
  }

  @override
  Future<int> deductCredits(int amount) async {
    final userId = SupabaseService.currentUser?.id;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    // Call the RPC function
    final result = await _client.rpc('deduct_credits', params: {'amount': amount}).call();

    // Fetch updated user data
    final user = await getCurrentUser();
    if (user == null) {
      throw Exception('Failed to fetch updated user data');
    }

    return user.creditsRemaining;
  }

  @override
  Future<int> addCredits(int amount) async {
    final userId = SupabaseService.currentUser?.id;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    // Call the RPC function
    final result = await _client.rpc('add_credits', params: {'amount': amount}).call();

    // Fetch updated user data
    final user = await getCurrentUser();
    if (user == null) {
      throw Exception('Failed to fetch updated user data');
    }

    return user.creditsRemaining;
  }

  @override
  Future<void> updateStorageUsed(int bytesUsed) async {
    final userId = SupabaseService.currentUser?.id;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    await _client
        .from(DatabaseTables.users)
        .update({
          'storage_used_bytes': bytesUsed,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', userId);
  }

  @override
  Future<void> deleteAccount() async {
    final userId = SupabaseService.currentUser?.id;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    // Delete user (cascade will handle all related data)
    await _client
        .from(DatabaseTables.users)
        .delete()
        .eq('id', userId);

    // Sign out
    await SupabaseService.signOut();
  }

  @override
  Stream<UserEntity?> get userStream {
    final userId = SupabaseService.currentUser?.id;
    if (userId == null) {
      return Stream.value(null);
    }

    return _client
        .from(DatabaseTables.users)
        .stream(primaryKey: ['id'])
        .eq('id', userId)
        .map((data) {
      if (data.isEmpty) return null;
      return _mapToEntity(UserModel.fromJson(data.first));
    });
  }

  /// Map UserModel to UserEntity
  UserEntity _mapToEntity(UserModel model) {
    return UserEntity(
      id: model.id,
      email: model.email,
      displayName: model.displayName,
      avatarUrl: model.avatarUrl,
      plan: model.plan,
      aiDocsUsed: model.aiDocsUsed,
      creditsRemaining: model.creditsRemaining,
      storageUsedBytes: model.storageUsedBytes,
      createdAt: model.createdAt,
      updatedAt: model.updatedAt,
    );
  }
}
