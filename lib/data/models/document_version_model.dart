import 'package:json_annotation/json_annotation.dart';

part 'document_version_model.g.dart';

/// Document version model for version history
@JsonSerializable()
class DocumentVersionModel {
  final String id;
  final String documentId;
  final int versionNumber;
  final String fileUrl;
  final int fileSizeBytes;
  final bool isAutosave;
  final String? label;
  final DateTime savedAt;

  DocumentVersionModel({
    required this.id,
    required this.documentId,
    required this.versionNumber,
    required this.fileUrl,
    required this.fileSizeBytes,
    this.isAutosave = false,
    this.label,
    required this.savedAt,
  });

  factory DocumentVersionModel.fromJson(Map<String, dynamic> json) =>
      _$DocumentVersionModelFromJson(json);

  Map<String, dynamic> toJson() => _$DocumentVersionModelToJson(this);

  String get formattedFileSize {
    if (fileSizeBytes < 1024) {
      return '$fileSizeBytes B';
    } else if (fileSizeBytes < 1024 * 1024) {
      return '${(fileSizeBytes / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(fileSizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }

  String get displayLabel => label ?? 'Version $versionNumber';
}
