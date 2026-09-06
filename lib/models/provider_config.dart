// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

/// 제공사 한 곳의 공개 표시 정보 (assets/providers.json). 비밀키 금지.
class ProviderEntry {
  final String id;
  final String name;
  final String region;
  final String policyUrl;
  final String policyVersion;

  /// 데이터 종류별 보관 설명. 예: {"audio": "7일"} / {"text": "미확정"}
  final Map<String, String> retention;

  const ProviderEntry({
    required this.id,
    required this.name,
    required this.region,
    required this.policyUrl,
    required this.policyVersion,
    this.retention = const {},
  });

  /// 미확정 값은 0일로 표시하지 않고 "미확정"으로 둔다
  String retentionLabel(String dataType) => retention[dataType] ?? '미확정';

  Map<String, dynamic> toMap() => <String, dynamic>{
    'id': id,
    'name': name,
    'region': region,
    'policy_url': policyUrl,
    'policy_version': policyVersion,
    'retention': retention,
  };

  factory ProviderEntry.fromMap(Map<String, dynamic> map) => ProviderEntry(
    id: map['id'] as String,
    name: map['name'] as String,
    region: map['region'] as String,
    policyUrl: map['policy_url'] as String,
    policyVersion: map['policy_version'] as String,
    retention: (map['retention'] as Map<String, dynamic>? ?? {}).map(
      (k, v) => MapEntry(k, v as String),
    ),
  );

  @override
  bool operator ==(covariant ProviderEntry other) {
    if (identical(this, other)) return true;
    return other.id == id &&
        other.name == name &&
        other.region == region &&
        other.policyUrl == policyUrl &&
        other.policyVersion == policyVersion &&
        json.encode(other.retention) == json.encode(retention);
  }

  @override
  int get hashCode =>
      id.hashCode ^
      name.hashCode ^
      region.hashCode ^
      policyUrl.hashCode ^
      policyVersion.hashCode;
}

/// ProviderConfig (통합 문서 5장). stt/llm이 null이면 "개발용 목업 · 제공사 미지정".
class ProviderConfig {
  final ProviderEntry? stt;
  final ProviderEntry? llm;

  const ProviderConfig({this.stt, this.llm});

  static const ProviderConfig empty = ProviderConfig();

  /// live 모드 외부 전송 허용 조건
  bool get isConfigured => stt != null && llm != null;

  /// 화면 표기용 이름. 미지정이면 자리표시자 대신 안내 문구
  String get sttName => stt?.name ?? '음성인식 제공사 미지정';
  String get llmName => llm?.name ?? 'AI 제공사 미지정';

  Map<String, dynamic> toMap() => <String, dynamic>{
    'stt': stt?.toMap(),
    'llm': llm?.toMap(),
  };

  factory ProviderConfig.fromMap(Map<String, dynamic> map) => ProviderConfig(
    stt: map['stt'] != null
        ? ProviderEntry.fromMap(map['stt'] as Map<String, dynamic>)
        : null,
    llm: map['llm'] != null
        ? ProviderEntry.fromMap(map['llm'] as Map<String, dynamic>)
        : null,
  );

  String toJson() => json.encode(toMap());

  factory ProviderConfig.fromJson(String source) =>
      ProviderConfig.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() => 'ProviderConfig(stt: ${stt?.id}, llm: ${llm?.id})';

  @override
  bool operator ==(covariant ProviderConfig other) {
    if (identical(this, other)) return true;
    return other.stt == stt && other.llm == llm;
  }

  @override
  int get hashCode => stt.hashCode ^ llm.hashCode;
}
