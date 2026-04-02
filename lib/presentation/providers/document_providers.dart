import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/entities.dart';
import '../../domain/repositories/repositories.dart';
import '../../data/repositories/repositories.dart';

/// Provider for DocumentRepository
final documentRepositoryProvider = Provider<DocumentRepository>((ref) {
  return SupabaseDocumentRepository();
});

/// Provider for FolderRepository
final folderRepositoryProvider = Provider<FolderRepository>((ref) {
  return SupabaseFolderRepository();
});

/// Provider for recent documents list
final recentDocumentsProvider = FutureProvider<List<DocumentEntity>>((ref) async {
  final repository = ref.watch(documentRepositoryProvider);
  return repository.getRecentDocuments(limit: 10);
});

/// Provider for favorite documents
final favoriteDocumentsProvider = FutureProvider<List<DocumentEntity>>((ref) async {
  final repository = ref.watch(documentRepositoryProvider);
  return repository.getFavoriteDocuments();
});

/// Provider for all documents (paginated)
class DocumentsNotifier extends AutoDisposeNotifier<List<DocumentEntity>> {
  @override
  List<DocumentEntity> build() {
    return [];
  }

  /// Load documents
  Future<void> loadDocuments({String? folderId}) async {
    final repository = ref.read(documentRepositoryProvider);
    state = await repository.getDocuments(folderId: folderId);
  }

  /// Refresh documents
  Future<void> refresh({String? folderId}) async {
    final repository = ref.read(documentRepositoryProvider);
    state = await repository.getDocuments(folderId: folderId);
  }

  /// Delete document
  Future<void> deleteDocument(String id) async {
    final repository = ref.read(documentRepositoryProvider);
    await repository.deleteDocument(id);
    state = state.where((doc) => doc.id != id).toList();
  }

  /// Toggle favorite
  Future<void> toggleFavorite(String id, bool favorite) async {
    final repository = ref.read(documentRepositoryProvider);
    final updated = await repository.updateDocument(id, favorite: favorite);
    state = state.map((doc) => doc.id == id ? updated : doc).toList();
  }

  /// Rename document
  Future<void> renameDocument(String id, String newTitle) async {
    final repository = ref.read(documentRepositoryProvider);
    final updated = await repository.updateDocument(id, title: newTitle);
    state = state.map((doc) => doc.id == id ? updated : doc).toList();
  }
}

/// Provider for DocumentsNotifier
final documentsNotifierProvider = AutoDisposeNotifierProvider<DocumentsNotifier, List<DocumentEntity>>(() {
  return DocumentsNotifier();
});

/// Provider for folders in current directory
class FoldersNotifier extends AutoDisposeNotifier<List<FolderEntity>> {
  @override
  List<FolderEntity> build() {
    return [];
  }

  /// Load folders
  Future<void> loadFolders({String? parentFolderId}) async {
    final repository = ref.read(folderRepositoryProvider);
    state = await repository.getFolders(parentFolderId: parentFolderId);
  }

  /// Create folder
  Future<FolderEntity> createFolder(String name, {String? parentFolderId}) async {
    final repository = ref.read(folderRepositoryProvider);
    final folder = await repository.createFolder(name: name, parentFolderId: parentFolderId);
    state = [...state, folder];
    return folder;
  }

  /// Delete folder
  Future<void> deleteFolder(String id) async {
    final repository = ref.read(folderRepositoryProvider);
    await repository.deleteFolder(id);
    state = state.where((folder) => folder.id != id).toList();
  }

  /// Rename folder
  Future<void> renameFolder(String id, String newName) async {
    final repository = ref.read(folderRepositoryProvider);
    final updated = await repository.updateFolder(id, name: newName);
    state = state.map((folder) => folder.id == id ? updated : folder).toList();
  }
}

/// Provider for FoldersNotifier
final foldersNotifierProvider = AutoDisposeNotifierProvider<FoldersNotifier, List<FolderEntity>>(() {
  return FoldersNotifier();
});

/// Provider for current folder path (breadcrumbs)
final currentFolderPathProvider = FutureProvider<List<FolderEntity>>((ref, String folderId) async {
  final repository = ref.watch(folderRepositoryProvider);
  return repository.getFolderPath(folderId);
});
