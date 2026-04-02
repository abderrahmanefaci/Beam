import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/entities.dart';

part 'document_model.g.dart';

/// Document model representing the documents table in Supabase
@JsonSerializable()
class DocumentModel {
  final String id;
  final String userId;
  final String? folderId;
  final String title;
  final String fileType;
  final int fileSizeBytes;
  final String fileUrl;
  final String sourceType; // 'scanner', 'tool', 'ai_action', 'upload'
  final String? outputOf;
  final bool aiUnlocked;
  final String? ocrText;
  final bool favorite;
  final DateTime createdAt;
  final DateTime updatedAt;

  DocumentModel({
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

  factory DocumentModel.fromJson(Map<String, dynamic> json) =>
      _$DocumentModelFromJson(json);

  Map<String, dynamic> toJson() => _$DocumentModelToJson(this);

  /// Get file size in KB
  double get fileSizeKB => fileSizeBytes / 1024;

  /// Get file size in MB
  double get fileSizeMB => fileSizeBytes / (1024 * 1024);

  /// Get formatted file size string
  String get formattedFileSize {
    if (fileSizeBytes < 1024) {
      return '$fileSizeBytes B';
    } else if (fileSizeBytes < 1024 * 1024) {
      return '${fileSizeKB.toStringAsFixed(1)} KB';
    } else {
      return '${fileSizeMB.toStringAsFixed(1)} MB';
    }
  }

  /// Get file icon based on type
  String get fileIcon {
    switch (fileType.toLowerCase()) {
      case 'pdf':
        return 'picture_as_pdf';
      case 'doc':
      case 'docx':
        return 'description';
      case 'xls':
      case 'xlsx':
        return 'table_chart';
      case 'ppt':
      case 'pptx':
        return 'presentation';
      case 'jpg':
      case 'jpeg':
      case 'png':
        return 'image';
      case 'txt':
      case 'md':
        return 'text_snippet';
      default:
        return 'insert_drive_file';
    }
  }

  DocumentModel copyWith({
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
    return DocumentModel(
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

  /// Convert model to domain entity
  DocumentEntity toEntity() {
    return DocumentEntity(
      id: id,
      userId: userId,
      folderId: folderId,
      title: title,
      fileType: fileType,
      fileSizeBytes: fileSizeBytes,
      fileUrl: fileUrl,
      sourceType: sourceType,
      outputOf: outputOf,
      aiUnlocked: aiUnlocked,
      ocrText: ocrText,
      favorite: favorite,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  /// Create model from domain entity
  factory DocumentModel.fromEntity(DocumentEntity entity) {
    return DocumentModel(
      id: entity.id,
      userId: entity.userId,
      folderId: entity.folderId,
      title: entity.title,
      fileType: entity.fileType,
      fileSizeBytes: entity.fileSizeBytes,
      fileUrl: entity.fileUrl,
      sourceType: entity.sourceType,
      outputOf: entity.outputOf,
      aiUnlocked: entity.aiUnlocked,
      ocrText: entity.ocrText,
      favorite: entity.favorite,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }
}
