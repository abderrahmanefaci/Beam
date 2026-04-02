import 'package:json_annotation/json_annotation.dart';

part 'folder_model.g.dart';

/// Folder model for organizing documents
@JsonSerializable()
class FolderModel {
  final String id;
  final String userId;
  final String? parentFolderId;
  final String name;
  final DateTime createdAt;
  final DateTime updatedAt;

  FolderModel({
    required this.id,
    required this.userId,
    this.parentFolderId,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
  });

  factory FolderModel.fromJson(Map<String, dynamic> json) =>
      _$FolderModelFromJson(json);

  Map<String, dynamic> toJson() => _$FolderModelToJson(this);

  FolderModel copyWith({
    String? id,
    String? userId,
    String? parentFolderId,
    String? name,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return FolderModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      parentFolderId: parentFolderId ?? this.parentFolderId,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
