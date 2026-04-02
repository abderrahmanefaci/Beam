import 'dart:io';
import 'dart:typed_data';
import 'package:uuid/uuid.dart';
import 'package:path/path.dart' as path;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:image/image.dart' as img;
import '../../core/constants/beam_constants.dart';
import '../../services/supabase_service.dart';

/// Scanner Filter Types
enum ScannerFilter {
  original('Original'),
  blackWhite('Black & White'),
  enhanced('Enhanced'),
  color('Color');

  final String displayName;
  const ScannerFilter(this.displayName);
}

/// Output format for scanned documents
enum ScanOutputFormat {
  pdf('PDF', 'application/pdf'),
  docx('DOCX', 'application/vnd.openxmlformats-officedocument.wordprocessingml.document'),
  jpg('JPG', 'image/jpeg'),
  png('PNG', 'image/png');

  final String label;
  final String mimeType;

  const ScanOutputFormat(this.label, this.mimeType);

  String get extension {
    switch (this) {
      case ScanOutputFormat.pdf:
        return 'pdf';
      case ScanOutputFormat.docx:
        return 'docx';
      case ScanOutputFormat.jpg:
        return 'jpg';
      case ScanOutputFormat.png:
        return 'png';
    }
  }
}

/// Scanned page data
class ScannedPage {
  final String id;
  final File imageFile;
  final ScannerFilter filter;
  Uint8List? processedImage;

  ScannedPage({
    required this.id,
    required this.imageFile,
    this.filter = ScannerFilter.original,
    this.processedImage,
  });
}

/// Scanner Service - Handles all scanning operations
class ScannerService {
  static final ScannerService _instance = ScannerService._internal();
  factory ScannerService() => _instance;
  ScannerService._internal();

  final _uuid = const Uuid();

  /// Apply filter to image and return processed bytes
  Future<Uint8List> applyFilter(File imageFile, ScannerFilter filter) async {
    final imageBytes = await imageFile.readAsBytes();
    final image = img.decodeImage(imageBytes);

    if (image == null) {
      return imageBytes;
    }

    img.Image processed;

    switch (filter) {
      case ScannerFilter.original:
        processed = image;
        break;
      case ScannerFilter.blackWhite:
        processed = img.grayscale(image);
        // Increase contrast for better B&W
        processed = img.adjustColor(processed, contrast: 1.5, brightness: 1.1);
        break;
      case ScannerFilter.enhanced:
        processed = img.adjustColor(
          image,
          contrast: 1.3,
          brightness: 1.1,
          saturation: 1.2,
        );
        processed = img.sharpen(processed);
        break;
      case ScannerFilter.color:
        processed = img.adjustColor(
          image,
          saturation: 1.3,
          brightness: 1.05,
        );
        break;
    }

    return Uint8List.fromList(img.encodeJpg(processed, quality: 90));
  }

  /// Render scanned pages to PDF
  Future<Uint8List> renderToPdf(List<ScannedPage> pages) async {
    final pdf = pw.Document();

    for (final page in pages) {
      final processedBytes = page.processedImage ?? await page.imageFile.readAsBytes();
      final image = pw.MemoryImage(processedBytes);

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.A4,
          build: (pw.Context context) {
            return pw.Center(
              child: pw.Image(
                image,
                fit: pw.BoxFit.contain,
              ),
            );
          },
        ),
      );
    }

    return pdf.save();
  }

  /// Convert images to DOCX via CloudConvert API
  Future<Uint8List> convertToDocx(List<File> imageFiles) async {
    final apiKey = const String.fromEnvironment('CLOUDCONVERT_API_KEY');
    if (apiKey.isEmpty) {
      throw Exception('CloudConvert API key not configured');
    }

    // Create conversion job
    final createResponse = await http.post(
      Uri.parse('https://api.cloudconvert.com/v2/jobs'),
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: '''{
        "tasks": {
          "import-my-images": {
            "operation": "import/upload"
          },
          "convert-to-docx": {
            "operation": "convert",
            "input": "import-my-images",
            "output_format": "docx"
          },
          "export-docx": {
            "operation": "export/upload",
            "input": "convert-to-docx"
          }
        }
      }''',
    );

    if (createResponse.statusCode != 200) {
      throw Exception('Failed to create CloudConvert job');
    }

    // TODO: Implement full CloudConvert flow (upload, wait, download)
    // For MVP, we'll return a placeholder
    throw Exception('DOCX conversion requires CloudConvert setup');
  }

  /// Upload file to Supabase Storage
  Future<String> uploadToStorage({
    required Uint8List fileData,
    required String fileName,
    required String fileType,
  }) async {
    final user = SupabaseService.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    final storagePath = '${user.id}/$fileName';

    try {
      await SupabaseService.client.storage
          .from(StorageBuckets.documents)
          .uploadBinary(
            storagePath,
            fileData,
          );

      // Get signed URL (valid for 60 minutes)
      final signedUrl = await SupabaseService.client.storage
          .from(StorageBuckets.documents)
          .createSignedUrl(storagePath, 60 * 60);

      return signedUrl;
    } catch (e) {
      throw Exception('Failed to upload to storage: ${e.toString()}');
    }
  }

  /// Save scan to database
  Future<Map<String, dynamic>> saveScanToDatabase({
    required String title,
    required String fileType,
    required int fileSize,
    required String fileUrl,
    String? folderId,
  }) async {
    final user = SupabaseService.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    final now = DateTime.now().toIso8601String();

    final response = await SupabaseService.client
        .from(DatabaseTables.documents)
        .insert({
          'user_id': user.id,
          'title': title,
          'file_type': fileType,
          'file_size_bytes': fileSize,
          'file_url': fileUrl,
          'source_type': 'scanner',
          'folder_id': folderId,
          'ai_unlocked': false,
          'favorite': false,
          'created_at': now,
          'updated_at': now,
        })
        .select()
        .single();

    return response as Map<String, dynamic>;
  }

  /// Generate scan title
  String generateScanTitle() {
    final now = DateTime.now();
    final dateStr = '${now.day}/${now.month}/${now.year}';
    final timeStr = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    return 'Scan $dateStr $timeStr';
  }

  /// Generate unique filename
  String generateFilename(String extension) {
    return '${_uuid.v4()}.$extension';
  }

  /// Get file size from bytes
  int getFileSize(Uint8List data) {
    return data.lengthInBytes;
  }

  /// Delete temporary files
  Future<void> cleanupTempFiles(List<File> files) async {
    for (final file in files) {
      if (await file.exists()) {
        await file.delete();
      }
    }
  }
}
