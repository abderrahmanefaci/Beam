import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:beam/core/services/supabase_service.dart';

class DocumentService {
  final SupabaseClient _client = SupabaseService.client;

  // Fetch user's documents
  Future<List<Map<String, dynamic>>> fetchUserDocuments() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    final response = await _client
        .from('documents')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  // Upload document to storage and save metadata
  Future<Map<String, dynamic>> uploadDocument({
    required String title,
    required File pdfFile,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    // Upload to storage
    final fileName = '${DateTime.now().millisecondsSinceEpoch}_${title.replaceAll(' ', '_')}.pdf';
    final storageResponse = await _client.storage
        .from('documents')
        .upload(fileName, pdfFile);

    if (storageResponse.hasError) {
      throw Exception('Upload failed: ${storageResponse.error}');
    }

    // Get public URL
    final fileUrl = _client.storage
        .from('documents')
        .getPublicUrl(fileName);

    // Save to database
    final dbResponse = await _client
        .from('documents')
        .insert({
          'user_id': userId,
          'title': title,
          'file_url': fileUrl,
        })
        .select()
        .single();

    return dbResponse;
  }

  // Delete document
  Future<void> deleteDocument(String documentId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    // Get document to find file URL for deletion
    final docResponse = await _client
        .from('documents')
        .select('file_url')
        .eq('id', documentId)
        .eq('user_id', userId)
        .single();

    // Delete from storage
    final fileUrl = docResponse['file_url'] as String;
    final fileName = fileUrl.split('/').last;
    await _client.storage.from('documents').remove([fileName]);

    // Delete from database
    await _client
        .from('documents')
        .delete()
        .eq('id', documentId)
        .eq('user_id', userId);
  }
}