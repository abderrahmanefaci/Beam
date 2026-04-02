import 'dart:typed_data';
import 'package:uuid/uuid.dart';
import '../../services/supabase_service.dart';

/// Signature Service - Handles signature storage and management
class SignatureService {
  static final SignatureService _instance = SignatureService._internal();
  factory SignatureService() => _instance;
  SignatureService._internal();

  final _uuid = const Uuid();

  /// Save signature to Supabase Storage
  Future<String> saveSignature(Uint8List pngData) async {
    final user = SupabaseService.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    final fileName = '${_uuid.v4()}.png';
    final storagePath = '${user.id}/$fileName';

    // Upload to storage
    await SupabaseService.client.storage
        .from('signatures')
        .uploadBinary(storagePath, pngData);

    // Get signed URL
    final fileUrl = await SupabaseService.client.storage
        .from('signatures')
        .createSignedUrl(storagePath, 60 * 60 * 24 * 30); // 30 days

    // Get next signature number
    final existingSignatures = await getSignatures();
    final signatureNumber = existingSignatures.length + 1;

    // Insert into signatures table
    await SupabaseService.client
        .from('signatures')
        .insert({
          'user_id': user.id,
          'label': 'Signature $signatureNumber',
          'file_url': fileUrl,
          'created_at': DateTime.now().toIso8601String(),
        });

    return fileUrl;
  }

  /// Get all user signatures
  Future<List<Map<String, dynamic>>> getSignatures() async {
    final user = SupabaseService.currentUser;
    if (user == null) return [];

    final response = await SupabaseService.client
        .from('signatures')
        .select()
        .eq('user_id', user.id)
        .order('created_at', ascending: false);

    return (response as List).cast<Map<String, dynamic>>();
  }

  /// Delete signature
  Future<void> deleteSignature(String signatureId) async {
    await SupabaseService.client
        .from('signatures')
        .delete()
        .eq('id', signatureId);
  }

  /// Update signature label
  Future<void> updateSignatureLabel(String signatureId, String label) async {
    await SupabaseService.client
        .from('signatures')
        .update({'label': label})
        .eq('id', signatureId);
  }
}
