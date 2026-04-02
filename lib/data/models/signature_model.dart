import 'package:json_annotation/json_annotation.dart';

part 'signature_model.g.dart';

/// E-Signature model
@JsonSerializable()
class SignatureModel {
  final String id;
  final String userId;
  final String? label;
  final String fileUrl;
  final DateTime createdAt;

  SignatureModel({
    required this.id,
    required this.userId,
    this.label,
    required this.fileUrl,
    required this.createdAt,
  });

  factory SignatureModel.fromJson(Map<String, dynamic> json) =>
      _$SignatureModelFromJson(json);

  Map<String, dynamic> toJson() => _$SignatureModelToJson(this);

  String get displayLabel => label ?? 'Signature';
}
