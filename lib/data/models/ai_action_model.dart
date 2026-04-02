import 'package:json_annotation/json_annotation.dart';

part 'ai_action_model.g.dart';

/// AI Action model for tracking AI usage and billing
@JsonSerializable()
class AiActionModel {
  final String id;
  final String userId;
  final String? documentId;
  final String actionType; // 'summarize', 'translate', 'extract', 'chat', 'custom'
  final String? modelUsed;
  final int? tokensIn;
  final int? tokensOut;
  final int creditsCharged;
  final String? result;
  final DateTime createdAt;

  AiActionModel({
    required this.id,
    required this.userId,
    this.documentId,
    required this.actionType,
    this.modelUsed,
    this.tokensIn,
    this.tokensOut,
    this.creditsCharged = 1,
    this.result,
    required this.createdAt,
  });

  factory AiActionModel.fromJson(Map<String, dynamic> json) =>
      _$AiActionModelFromJson(json);

  Map<String, dynamic> toJson() => _$AiActionModelToJson(this);

  /// Get action type display name
  String get actionTypeDisplay {
    return actionType.split('_').map((word) {
      return word[0].toUpperCase() + word.substring(1);
    }).join(' ');
  }
}
