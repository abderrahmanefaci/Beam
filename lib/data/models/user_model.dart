import 'package:json_annotation/json_annotation.dart';

part 'user_model.g.dart';

/// User model representing the users table in Supabase
@JsonSerializable()
class UserModel {
  final String id;
  final String email;
  final String? displayName;
  final String? avatarUrl;
  final String plan; // 'free' or 'premium'
  final int aiDocsUsed;
  final int creditsRemaining;
  final int storageUsedBytes;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserModel({
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

  factory UserModel.fromJson(Map<String, dynamic> json) =>
      _$UserModelFromJson(json);

  Map<String, dynamic> toJson() => _$UserModelToJson(this);

  /// Check if user is on premium plan
  bool get isPremium => plan == 'premium';

  /// Check if user can unlock more AI documents (free tier limit: 3)
  bool get canUnlockAiDocument => isPremium || aiDocsUsed < 3;

  /// Get remaining AI document unlocks for free users
  int get remainingAiUnlocks => isPremium ? 999 : (3 - aiDocsUsed);

  /// Get storage used in MB
  double get storageUsedMB => storageUsedBytes / (1024 * 1024);

  /// Get storage used percentage (assuming 100MB free tier)
  double get storageUsedPercent => (storageUsedBytes / (100 * 1024 * 1024)) * 100;

  UserModel copyWith({
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
    return UserModel(
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
}
