// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

/// 프라이버시 동의 기록 (통합 문서 5장).
/// consentVersion = hash(sttId, llmId, region, dataTypes[], policyVersion). 계산은 ConsentService.
class ConsentRecord {
  final String userId;
  final String consentVersion;
  final DateTime acceptedAt;

  const ConsentRecord({
    required this.userId,
    required this.consentVersion,
    required this.acceptedAt,
  });

  ConsentRecord copyWith({
    String? userId,
    String? consentVersion,
    DateTime? acceptedAt,
  }) => ConsentRecord(
    userId: userId ?? this.userId,
    consentVersion: consentVersion ?? this.consentVersion,
    acceptedAt: acceptedAt ?? this.acceptedAt,
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    'user_id': userId,
    'consent_version': consentVersion,
    'accepted_at': acceptedAt.toIso8601String(),
  };

  factory ConsentRecord.fromMap(Map<String, dynamic> map) => ConsentRecord(
    userId: map['user_id'] as String,
    consentVersion: map['consent_version'] as String,
    acceptedAt: DateTime.parse(map['accepted_at'] as String),
  );

  String toJson() => json.encode(toMap());

  factory ConsentRecord.fromJson(String source) =>
      ConsentRecord.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() =>
      'ConsentRecord(userId: $userId, consentVersion: $consentVersion, acceptedAt: $acceptedAt)';

  @override
  bool operator ==(covariant ConsentRecord other) {
    if (identical(this, other)) return true;
    return other.userId == userId &&
        other.consentVersion == consentVersion &&
        other.acceptedAt == acceptedAt;
  }

  @override
  int get hashCode =>
      userId.hashCode ^ consentVersion.hashCode ^ acceptedAt.hashCode;
}
