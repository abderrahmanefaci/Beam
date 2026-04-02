import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants/beam_constants.dart';
import '../../domain/entities/entities.dart';
import '../../domain/repositories/document_repository.dart';
import '../../services/supabase_service.dart';
import '../models/document_model.dart';

/// Supabase implementation of DocumentRepository
class SupabaseDocumentRepository implements DocumentRepository {
  SupabaseClient get _client => SupabaseService.client;

  @override
  Future<List<DocumentEntity>> getDocuments({
    String? folderId,
    int limit = 20,
    int offset = 0,
    String? sortBy,
    bool ascending = false,
  }) async {
    final userId = SupabaseService.currentUser?.id;
    if (userId == null) return [];

    var query = _client
        .from(DatabaseTables.documents)
        .select()
        .eq('user_id', userId)
        .limit(limit)
        .range(offset, offset + limit - 1);

    // Filter by folder if provided
    if (folderId != null) {
      query = query.eq('folder_id', folderId);
    } else {
      // If no folder specified, show root level documents (folder_id is null)
      query = query.is_('folder_id', null);
    }

    // Sort
    final sortColumn = sortBy ?? 'updated_at';
    query = query.order(sortColumn, ascending: ascending);

    final response = await query;
    return (response as List)
        .map((doc) => _mapToEntity(DocumentModel.fromJson(doc)))
        .toList();
  }

  @override
  Future<DocumentEntity?> getDocumentById(String id) async {
    try {
      final response = await _client
          .from(DatabaseTables.documents)
          .select()
          .eq('id', id)
          .single();

      if (response == null) return null;
      return _mapToEntity(DocumentModel.fromJson(response));
    } catch (e) {
      return null;
    }
  }

  @override
  Future<List<DocumentEntity>> getRecentDocuments({int limit = 10}) async {
    final userId = SupabaseService.currentUser?.id;
    if (userId == null) return [];

    final response = await _client
        .from(DatabaseTables.documents)
        .select()
        .eq('user_id', userId)
        .order('updated_at', ascending: false)
        .limit(limit);

    return (response as List)
        .map((doc) => _mapToEntity(DocumentModel.fromJson(doc)))
        .toList();
  }

  @override
  Future<List<DocumentEntity>> getFavoriteDocuments() async {
    final userId = SupabaseService.currentUser?.id;
    if (userId == null) return [];

    final response = await _client
        .from(DatabaseTables.documents)
        .select()
        .eq('user_id', userId)
        .eq('favorite', true)
        .order('updated_at', ascending: false);

    return (response as List)
        .map((doc) => _mapToEntity(DocumentModel.fromJson(doc)))
        .toList();
  }

  @override
  Future<List<DocumentEntity>> searchDocuments(String query) async {
    final userId = SupabaseService.currentUser?.id;
    if (userId == null) return [];

    // Use Supabase full-text search
    final response = await _client
        .from(DatabaseTables.documents)
        .select()
        .eq('user_id', userId)
        .textSearch('title', query, config: 'english');

    return (response as List)
        .map((doc) => _mapToEntity(DocumentModel.fromJson(doc)))
        .toList();
  }

  @override
  Future<DocumentEntity> createDocument({
    required String title,
    required String fileType,
    required int fileSizeBytes,
    required String fileUrl,
    required String sourceType,
    String? folderId,
    String? outputOf,
    String? ocrText,
  }) async {
    final userId = SupabaseService.currentUser?.id;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    final now = DateTime.now().toIso8601String();
    final response = await _client
        .from(DatabaseTables.documents)
        .insert({
          'user_id': userId,
          'title': title,
          'file_type': fileType,
          'file_size_bytes': fileSizeBytes,
          'file_url': fileUrl,
          'source_type': sourceType,
          'folder_id': folderId,
          'output_of': outputOf,
          'ocr_text': ocrText,
          'ai_unlocked': false,
          'favorite': false,
          'created_at': now,
          'updated_at': now,
        })
        .select()
        .single();

    return _mapToEntity(DocumentModel.fromJson(response));
  }

  @override
  Future<DocumentEntity> updateDocument(
    String id, {
    String? title,
    String? folderId,
    bool? favorite,
    String? ocrText,
    bool? aiUnlocked,
  }) async {
    final updateData = <String, dynamic>{
      'updated_at': DateTime.now().toIso8601String(),
    };

    if (title != null) updateData['title'] = title;
    if (folderId != null) updateData['folder_id'] = folderId;
    if (favorite != null) updateData['favorite'] = favorite;
    if (ocrText != null) updateData['ocr_text'] = ocrText;
    if (aiUnlocked != null) updateData['ai_unlocked'] = aiUnlocked;

    final response = await _client
        .from(DatabaseTables.documents)
        .update(updateData)
        .eq('id', id)
        .select()
        .single();

    return _mapToEntity(DocumentModel.fromJson(response));
  }

  @override
  Future<void> deleteDocument(String id) async {
    await _client.from(DatabaseTables.documents).delete().eq('id', id);
  }

  @override
  Future<DocumentEntity> duplicateDocument(String id) async {
    final original = await getDocumentById(id);
    if (original == null) {
      throw Exception('Document not found');
    }

    return createDocument(
      title: '${original.title} (Copy)',
      fileType: original.fileType,
      fileSizeBytes: original.fileSizeBytes,
      fileUrl: original.fileUrl,
      sourceType: 'tool',
      folderId: original.folderId,
    );
  }

  @override
  Future<void> moveDocument(String id, String? folderId) async {
    await _client
        .from(DatabaseTables.documents)
        .update({
          'folder_id': folderId,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', id);
  }

  @override
  Stream<List<DocumentEntity>> watchDocuments({String? folderId}) {
    final userId = SupabaseService.currentUser?.id;
    if (userId == null) return Stream.value([]);

    var stream = _client
        .from(DatabaseTables.documents)
        .stream(primaryKey: ['id'])
        .eq('user_id', userId);

    if (folderId != null) {
      stream = stream.eq('folder_id', folderId);
    } else {
      stream = stream.is_('folder_id', null);
    }

    return stream.map((data) {
      return (data as List)
          .map((doc) => _mapToEntity(DocumentModel.fromJson(doc)))
          .toList();
    });
  }

  @override
  Future<int> getDocumentsCount() async {
    final userId = SupabaseService.currentUser?.id;
    if (userId == null) return 0;

    final response = await _client
        .from(DatabaseTables.documents)
        .select('*', count: 'exact')
        .eq('user_id', userId);

    return response.count ?? 0;
  }

  /// Map DocumentModel to DocumentEntity
  DocumentEntity _mapToEntity(DocumentModel model) {
    return DocumentEntity(
      id: model.id,
      userId: model.userId,
      folderId: model.folderId,
      title: model.title,
      fileType: model.fileType,
      fileSizeBytes: model.fileSizeBytes,
      fileUrl: model.fileUrl,
      sourceType: model.sourceType,
      outputOf: model.outputOf,
      aiUnlocked: model.aiUnlocked,
      ocrText: model.ocrText,
      favorite: model.favorite,
      createdAt: model.createdAt,
      updatedAt: model.updatedAt,
    );
  }
}
