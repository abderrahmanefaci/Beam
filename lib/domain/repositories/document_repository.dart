import '../entities/entities.dart';

/// Abstract repository interface for document operations
abstract class DocumentRepository {
  /// Get all documents for current user
  Future<List<DocumentEntity>> getDocuments({
    String? folderId,
    int limit = 20,
    int offset = 0,
    String? sortBy,
    bool ascending = false,
  });

  /// Get document by ID
  Future<DocumentEntity?> getDocumentById(String id);

  /// Get recent documents
  Future<List<DocumentEntity>> getRecentDocuments({int limit = 10});

  /// Get favorite documents
  Future<List<DocumentEntity>> getFavoriteDocuments();

  /// Search documents
  Future<List<DocumentEntity>> searchDocuments(String query);

  /// Create document
  Future<DocumentEntity> createDocument({
    required String title,
    required String fileType,
    required int fileSizeBytes,
    required String fileUrl,
    required String sourceType,
    String? folderId,
    String? outputOf,
    String? ocrText,
  });

  /// Update document
  Future<DocumentEntity> updateDocument(
    String id, {
    String? title,
    String? folderId,
    bool? favorite,
    String? ocrText,
    bool? aiUnlocked,
  });

  /// Delete document
  Future<void> deleteDocument(String id);

  /// Duplicate document
  Future<DocumentEntity> duplicateDocument(String id);

  /// Move document to folder
  Future<void> moveDocument(String id, String? folderId);

  /// Stream documents for a folder
  Stream<List<DocumentEntity>> watchDocuments({String? folderId});

  /// Get documents count
  Future<int> getDocumentsCount();
}
