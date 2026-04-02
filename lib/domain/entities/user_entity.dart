import 'package:equatable/equatable.dart';

/// User entity - domain layer representation
class UserEntity extends Equatable {
  final String id;
  final String email;
  final String? displayName;
  final String? avatarUrl;
  final String plan;
  final int aiDocsUsed;
  final int creditsRemaining;
  final int storageUsedBytes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserEntity({
    required this.id,
    required this.email,
    this.displayName,
    this.avatarUrl,
    this.plan = 'free',
    this.aiDocsUsed = 0,
    this.creditsRemaining = 0,
    this.storageUsedBytes = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isPremium => plan == 'premium';
  bool get canUnlockAiDocument => isPremium || aiDocsUsed < 3;
  int get remainingAiUnlocks => isPremium ? 999 : (3 - aiDocsUsed);
  double get storageUsedMB => storageUsedBytes / (1024 * 1024);
  double get storageUsedPercent => (storageUsedBytes / (100 * 1024 * 1024)) * 100;

  UserEntity copyWith({
    String? id,
    String? email,
    String? displayName,
    String? avatarUrl,
    String? plan,
    int? aiDocsUsed,
    int? creditsRemaining,
    int? storageUsedBytes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserEntity(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      plan: plan ?? this.plan,
      aiDocsUsed: aiDocsUsed ?? this.aiDocsUsed,
      creditsRemaining: creditsRemaining ?? this.creditsRemaining,
      storageUsedBytes: storageUsedBytes ?? this.storageUsedBytes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        email,
        displayName,
        avatarUrl,
        plan,
        aiDocsUsed,
        creditsRemaining,
        storageUsedBytes,
        createdAt,
        updatedAt,
      ];
}
