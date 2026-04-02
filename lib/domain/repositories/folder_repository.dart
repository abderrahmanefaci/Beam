import '../entities/entities.dart';

/// Abstract repository interface for folder operations
abstract class FolderRepository {
  /// Get all folders for current user
  Future<List<FolderEntity>> getFolders({String? parentFolderId});

  /// Get folder by ID
  Future<FolderEntity?> getFolderById(String id);

  /// Create folder
  Future<FolderEntity> createFolder({
    required String name,
    String? parentFolderId,
  });

  /// Update folder
  Future<FolderEntity> updateFolder(String id, {required String name});

  /// Delete folder (and optionally its contents)
  Future<void> deleteFolder(String id, {bool deleteContents = false});

  /// Get folder path (breadcrumbs)
  Future<List<FolderEntity>> getFolderPath(String folderId);

  /// Stream folders for a parent folder
  Stream<List<FolderEntity>> watchFolders({String? parentFolderId});
}
