import 'package:equatable/equatable.dart';

/// Folder entity - domain layer representation
class FolderEntity extends Equatable {
  final String id;
  final String userId;
  final String? parentFolderId;
  final String name;
  final DateTime createdAt;
  final DateTime updatedAt;

  const FolderEntity({
    required this.id,
    required this.userId,
    this.parentFolderId,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
  });

  FolderEntity copyWith({
    String? id,
    String? userId,
    String? parentFolderId,
    String? name,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return FolderEntity(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      parentFolderId: parentFolderId ?? this.parentFolderId,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        parentFolderId,
        name,
        createdAt,
        updatedAt,
      ];
}
