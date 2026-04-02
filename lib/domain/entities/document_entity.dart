import 'package:equatable/equatable.dart';

/// Document entity - domain layer representation
class DocumentEntity extends Equatable {
  final String id;
  final String userId;
  final String? folderId;
  final String title;
  final String fileType;
  final int fileSizeBytes;
  final String fileUrl;
  final String sourceType;
  final String? outputOf;
  final bool aiUnlocked;
  final String? ocrText;
  final bool favorite;
  final DateTime createdAt;
  final DateTime updatedAt;

  const DocumentEntity({
    required this.id,
    required this.userId,
    this.folderId,
    required this.title,
    required this.fileType,
    required this.fileSizeBytes,
    required this.fileUrl,
    required this.sourceType,
    this.outputOf,
    this.aiUnlocked = false,
    this.ocrText,
    this.favorite = false,
    required this.createdAt,
    required this.updatedAt,
  });

  double get fileSizeKB => fileSizeBytes / 1024;
  double get fileSizeMB => fileSizeBytes / (1024 * 1024);

  String get formattedFileSize {
    if (fileSizeBytes < 1024) return '$fileSizeBytes B';
    if (fileSizeBytes < 1024 * 1024) return '${fileSizeKB.toStringAsFixed(1)} KB';
    return '${fileSizeMB.toStringAsFixed(1)} MB';
  }

  String get fileIcon {
    switch (fileType.toLowerCase()) {
      case 'pdf': return 'picture_as_pdf';
      case 'doc':
      case 'docx': return 'description';
      case 'xls':
      case 'xlsx': return 'table_chart';
      case 'ppt':
      case 'pptx': return 'presentation';
      case 'jpg':
      case 'jpeg':
      case 'png': return 'image';
      case 'txt':
      case 'md': return 'text_snippet';
      default: return 'insert_drive_file';
    }
  }

  DocumentEntity copyWith({
    String? id,
    String? userId,
    String? folderId,
    String? title,
    String? fileType,
    int? fileSizeBytes,
    String? fileUrl,
    String? sourceType,
    String? outputOf,
    bool? aiUnlocked,
    String? ocrText,
    bool? favorite,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DocumentEntity(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      folderId: folderId ?? this.folderId,
      title: title ?? this.title,
      fileType: fileType ?? this.fileType,
      fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
      fileUrl: fileUrl ?? this.fileUrl,
      sourceType: sourceType ?? this.sourceType,
      outputOf: outputOf ?? this.outputOf,
      aiUnlocked: aiUnlocked ?? this.aiUnlocked,
      ocrText: ocrText ?? this.ocrText,
      favorite: favorite ?? this.favorite,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        folderId,
        title,
        fileType,
        fileSizeBytes,
        fileUrl,
        sourceType,
        outputOf,
        aiUnlocked,
        ocrText,
        favorite,
        createdAt,
        updatedAt,
      ];
}
