import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants/beam_constants.dart';
import '../../domain/entities/entities.dart';
import '../../domain/repositories/folder_repository.dart';
import '../../services/supabase_service.dart';
import '../models/folder_model.dart';

/// Supabase implementation of FolderRepository
class SupabaseFolderRepository implements FolderRepository {
  SupabaseClient get _client => SupabaseService.client;

  @override
  Future<List<FolderEntity>> getFolders({String? parentFolderId}) async {
    final userId = SupabaseService.currentUser?.id;
    if (userId == null) return [];

    var query = _client
        .from(DatabaseTables.folders)
        .select()
        .eq('user_id', userId)
        .order('name', ascending: true);

    if (parentFolderId != null) {
      query = query.eq('parent_folder_id', parentFolderId);
    } else {
      // Root folders have null parent
      query = query.is_('parent_folder_id', null);
    }

    final response = await query;
    return (response as List)
        .map((folder) => _mapToEntity(FolderModel.fromJson(folder)))
        .toList();
  }

  @override
  Future<FolderEntity?> getFolderById(String id) async {
    try {
      final response = await _client
          .from(DatabaseTables.folders)
          .select()
          .eq('id', id)
          .single();

      if (response == null) return null;
      return _mapToEntity(FolderModel.fromJson(response));
    } catch (e) {
      return null;
    }
  }

  @override
  Future<FolderEntity> createFolder({
    required String name,
    String? parentFolderId,
  }) async {
    final userId = SupabaseService.currentUser?.id;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    final now = DateTime.now().toIso8601String();
    final response = await _client
        .from(DatabaseTables.folders)
        .insert({
          'user_id': userId,
          'name': name,
          'parent_folder_id': parentFolderId,
          'created_at': now,
          'updated_at': now,
        })
        .select()
        .single();

    return _mapToEntity(FolderModel.fromJson(response));
  }

  @override
  Future<FolderEntity> updateFolder(String id, {required String name}) async {
    final now = DateTime.now().toIso8601String();
    final response = await _client
        .from(DatabaseTables.folders)
        .update({
          'name': name,
          'updated_at': now,
        })
        .eq('id', id)
        .select()
        .single();

    return _mapToEntity(FolderModel.fromJson(response));
  }

  @override
  Future<void> deleteFolder(String id, {bool deleteContents = false}) async {
    if (deleteContents) {
      // First delete all documents in this folder
      await _client
          .from(DatabaseTables.documents)
          .delete()
          .eq('folder_id', id);

      // Then delete all subfolders (recursive)
      await _client
          .from(DatabaseTables.folders)
          .delete()
          .eq('parent_folder_id', id);
    }

    // Delete the folder itself
    await _client.from(DatabaseTables.folders).delete().eq('id', id);
  }

  @override
  Future<List<FolderEntity>> getFolderPath(String folderId) async {
    final path = <FolderEntity>[];
    String? currentId = folderId;

    while (currentId != null) {
      final folder = await getFolderById(currentId);
      if (folder == null) break;
      path.insert(0, folder);
      currentId = folder.parentFolderId;
    }

    return path;
  }

  @override
  Stream<List<FolderEntity>> watchFolders({String? parentFolderId}) {
    final userId = SupabaseService.currentUser?.id;
    if (userId == null) return Stream.value([]);

    var stream = _client
        .from(DatabaseTables.folders)
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('name', ascending: true);

    if (parentFolderId != null) {
      stream = stream.eq('parent_folder_id', parentFolderId);
    } else {
      stream = stream.is_('parent_folder_id', null);
    }

    return stream.map((data) {
      return (data as List)
          .map((folder) => _mapToEntity(FolderModel.fromJson(folder)))
          .toList();
    });
  }

  /// Map FolderModel to FolderEntity
  FolderEntity _mapToEntity(FolderModel model) {
    return FolderEntity(
      id: model.id,
      userId: model.userId,
      parentFolderId: model.parentFolderId,
      name: model.name,
      createdAt: model.createdAt,
      updatedAt: model.updatedAt,
    );
  }
}
