// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:rehearsallab/core/enum/stage_state.dart';
import 'package:rehearsallab/models/feedback.dart';

/// 리라이트 제안 (통합 문서 2장). 확정 1회 = 버전 +1.
class Rewrite {
  final String id;
  final String original;
  final String replacement;
  final String reason;

  /// 반영으로 만들어진 새 버전 id. null = 아직 반영 안 함
  final String? appliedVersionId;

  const Rewrite({
    required this.id,
    required this.original,
    required this.replacement,
    required this.reason,
    this.appliedVersionId,
  });

  bool get isApplied => appliedVersionId != null;

  Rewrite copyWith({
    String? id,
    String? original,
    String? replacement,
    String? reason,
    String? appliedVersionId,
  }) {
    return Rewrite(
      id: id ?? this.id,
      original: original ?? this.original,
      replacement: replacement ?? this.replacement,
      reason: reason ?? this.reason,
      appliedVersionId: appliedVersionId ?? this.appliedVersionId,
    );
  }

  Map<String, dynamic> toMap() => <String, dynamic>{
    'id': id,
    'original': original,
    'replacement': replacement,
    'reason': reason,
    'applied_version_id': appliedVersionId,
  };

  factory Rewrite.fromMap(Map<String, dynamic> map) => Rewrite(
    id: map['id'] as String,
    original: map['original'] as String,
    replacement: map['replacement'] as String,
    reason: map['reason'] as String,
    appliedVersionId: map['applied_version_id'] as String?,
  );

  @override
  bool operator ==(covariant Rewrite other) {
    if (identical(this, other)) return true;
    return other.id == id &&
        other.original == original &&
        other.replacement == replacement &&
        other.reason == reason &&
        other.appliedVersionId == appliedVersionId;
  }

  @override
  int get hashCode =>
      id.hashCode ^
      original.hashCode ^
      replacement.hashCode ^
      reason.hashCode ^
      appliedVersionId.hashCode;
}

/// 섹션별 예상 소요 시간 (코드 계산).
class SectionEstimate {
  final String name;
  final int seconds;

  const SectionEstimate({required this.name, required this.seconds});

  Map<String, dynamic> toMap() => <String, dynamic>{
    'name': name,
    'seconds': seconds,
  };

  factory SectionEstimate.fromMap(Map<String, dynamic> map) => SectionEstimate(
    name: map['name'] as String,
    seconds: map['seconds'] as int,
  );

  @override
  bool operator ==(covariant SectionEstimate other) {
    if (identical(this, other)) return true;
    return other.name == name && other.seconds == seconds;
  }

  @override
  int get hashCode => name.hashCode ^ seconds.hashCode;
}

/// 원고 분석 결과 (통합 문서 5장). scriptVersionId에 묶여 저장된다.
class ScriptAnalysis {
  final String id;
  final String scriptVersionId;
  final String summary;
  final List<TopAction> topActions;

  /// 원고 3차원: logic · clarity · audience
  final List<DimensionFeedback> dimensions;
  final List<Rewrite> rewrites;
  final List<SectionEstimate> sectionEstimates;

  /// succeeded | failed (StageState 재사용, pending/running은 저장하지 않음)
  final StageState status;
  final String? error;
  final DateTime createdAt;

  const ScriptAnalysis({
    required this.id,
    required this.scriptVersionId,
    required this.summary,
    required this.topActions,
    required this.dimensions,
    required this.rewrites,
    required this.sectionEstimates,
    required this.status,
    this.error,
    required this.createdAt,
  });

  int get appliedRewriteCount => rewrites.where((r) => r.isApplied).length;

  int get estimatedTotalSeconds =>
      sectionEstimates.fold(0, (sum, e) => sum + e.seconds);

  ScriptAnalysis copyWith({
    String? id,
    String? scriptVersionId,
    String? summary,
    List<TopAction>? topActions,
    List<DimensionFeedback>? dimensions,
    List<Rewrite>? rewrites,
    List<SectionEstimate>? sectionEstimates,
    StageState? status,
    String? error,
    DateTime? createdAt,
  }) {
    return ScriptAnalysis(
      id: id ?? this.id,
      scriptVersionId: scriptVersionId ?? this.scriptVersionId,
      summary: summary ?? this.summary,
      topActions: topActions ?? this.topActions,
      dimensions: dimensions ?? this.dimensions,
      rewrites: rewrites ?? this.rewrites,
      sectionEstimates: sectionEstimates ?? this.sectionEstimates,
      status: status ?? this.status,
      error: error ?? this.error,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'script_version_id': scriptVersionId,
      'summary': summary,
      'top_actions': topActions.map((e) => e.toMap()).toList(),
      'dimensions': dimensions.map((e) => e.toMap()).toList(),
      'rewrites': rewrites.map((e) => e.toMap()).toList(),
      'section_estimates': sectionEstimates.map((e) => e.toMap()).toList(),
      'status': status.name,
      'error': error,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory ScriptAnalysis.fromMap(Map<String, dynamic> map) {
    return ScriptAnalysis(
      id: map['id'] as String,
      scriptVersionId: map['script_version_id'] as String,
      summary: map['summary'] as String,
      topActions: (map['top_actions'] as List)
          .map((e) => TopAction.fromMap(e as Map<String, dynamic>))
          .toList(),
      dimensions: (map['dimensions'] as List)
          .map((e) => DimensionFeedback.fromMap(e as Map<String, dynamic>))
          .toList(),
      rewrites: (map['rewrites'] as List)
          .map((e) => Rewrite.fromMap(e as Map<String, dynamic>))
          .toList(),
      sectionEstimates: (map['section_estimates'] as List)
          .map((e) => SectionEstimate.fromMap(e as Map<String, dynamic>))
          .toList(),
      status: StageStateExtension.fromName(map['status'] as String),
      error: map['error'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  String toJson() => json.encode(toMap());

  factory ScriptAnalysis.fromJson(String source) =>
      ScriptAnalysis.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'ScriptAnalysis(id: $id, scriptVersionId: $scriptVersionId, status: $status, topActions: ${topActions.length}, dimensions: ${dimensions.length}, rewrites: ${rewrites.length})';
  }

  @override
  bool operator ==(covariant ScriptAnalysis other) {
    if (identical(this, other)) return true;
    return other.toJson() == toJson();
  }

  @override
  int get hashCode => toJson().hashCode;
}
