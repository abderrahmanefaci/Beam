import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../../core/constants/beam_constants.dart';
import '../../services/supabase_service.dart';

/// Editor Service - Handles file operations for the editor
class EditorService {
  static final EditorService _instance = EditorService._internal();
  factory EditorService() => _instance;
  EditorService._internal();

  /// Load file data from URL
  Future<Uint8List> loadFileData(String fileUrl) async {
    try {
      final response = await http.get(Uri.parse(fileUrl));
      if (response.statusCode == 200) {
        return response.bodyBytes;
      } else {
        throw Exception('Failed to load file: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load file: $e');
    }
  }

  /// Save a new version of the document
  Future<Map<String, dynamic>> saveVersion({
    required String documentId,
    required Uint8List fileData,
    required bool isAutosave,
    String? label,
  }) async {
    final user = SupabaseService.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    final client = SupabaseService.client;

    // Get current version number
    final versionsResponse = await client
        .from(DatabaseTables.documentVersions)
        .select('version_number')
        .eq('document_id', documentId)
        .order('version_number', ascending: false)
        .limit(1)
        .maybeSingle();

    int versionNumber = 1;
    if (versionsResponse != null) {
      versionNumber = (versionsResponse['version_number'] as int) + 1;
    }

    // Generate filename
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final fileName = '$timestamp.pdf'; // Extension will vary by file type
    final storagePath = '${user.id}/versions/$documentId/$fileName';

    // Upload to storage
    await client.storage
        .from(StorageBuckets.documents)
        .uploadBinary(storagePath, fileData);

    // Get signed URL
    final fileUrl = await client.storage
        .from(StorageBuckets.documents)
        .createSignedUrl(storagePath, 60 * 60);

    // Insert version record
    final versionResponse = await client
        .from(DatabaseTables.documentVersions)
        .insert({
          'document_id': documentId,
          'version_number': versionNumber,
          'file_url': fileUrl,
          'file_size_bytes': fileData.length,
          'is_autosave': isAutosave,
          'label': label,
          'saved_at': DateTime.now().toIso8601String(),
        })
        .select()
        .single() as Map<String, dynamic>;

    // Update document's updated_at and file_url
    await client
        .from(DatabaseTables.documents)
        .update({
          'updated_at': DateTime.now().toIso8601String(),
          'file_url': fileUrl,
        })
        .eq('id', documentId);

    // Cap versions for free tier (max 10)
    if (!await _isPremium(user.id)) {
      await _capVersions(documentId);
    }

    return versionResponse;
  }

  /// Get all versions for a document
  Future<List<Map<String, dynamic>>> getVersions(String documentId) async {
    final client = SupabaseService.client;

    final response = await client
        .from(DatabaseTables.documentVersions)
        .select()
        .eq('document_id', documentId)
        .order('version_number', ascending: false);

    return (response as List).cast<Map<String, dynamic>>();
  }

  /// Revert to a specific version
  Future<void> revertToVersion({
    required String documentId,
    required int versionNumber,
  }) async {
    final client = SupabaseService.client;

    // Get the version to revert to
    final versionResponse = await client
        .from(DatabaseTables.documentVersions)
        .select()
        .eq('document_id', documentId)
        .eq('version_number', versionNumber)
        .single() as Map<String, dynamic>;

    // Download the version file
    final fileData = await loadFileData(versionResponse['file_url']);

    // Save as new version with revert label
    await saveVersion(
      documentId: documentId,
      fileData: fileData,
      isAutosave: false,
      label: 'Reverted to v$versionNumber',
    );
  }

  /// Check if user is premium
  Future<bool> _isPremium(String userId) async {
    final client = SupabaseService.client;
    final userResponse = await client
        .from(DatabaseTables.users)
        .select('plan')
        .eq('id', userId)
        .single();

    return userResponse['plan'] == 'premium';
  }

  /// Cap versions to max for free tier
  Future<void> _capVersions(String documentId) async {
    final client = SupabaseService.client;

    // Get all versions
    final versions = await client
        .from(DatabaseTables.documentVersions)
        .select('id, version_number')
        .eq('document_id', documentId)
        .order('version_number', ascending: true);

    final versionsList = (versions as List).cast<Map<String, dynamic>>();

    // Delete oldest versions if over limit
    if (versionsList.length > BeamConstants.maxVersionsFree) {
      final toDelete = versionsList.length - BeamConstants.maxVersionsFree;
      for (int i = 0; i < toDelete; i++) {
        final version = versionsList[i];
        // Delete from storage first (optional - could keep for recovery)
        // Then delete from database
        await client
            .from(DatabaseTables.documentVersions)
            .delete()
            .eq('id', version['id']);
      }
    }
  }

  /// Get version history stats
  Future<Map<String, int>> getVersionStats(String documentId) async {
    final versions = await getVersions(documentId);
    final autosaveCount = versions.where((v) => v['is_autosave'] == true).length;
    final manualCount = versions.length - autosaveCount;

    return {
      'total': versions.length,
      'autosave': autosaveCount,
      'manual': manualCount,
    };
  }
}
