// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:rehearsallab/core/enum/script_version_origin.dart';

/// 원고 버전 (통합 문서 5장). text는 불변. 새 버전은 항상 version+1로 추가한다.
class ScriptVersion {
  final String id;
  final String presentationId;
  final int version;
  final String text;

  /// 이전 버전 id. v1이면 null
  final String? parentVersionId;
  final ScriptVersionOrigin createdBy;
  final DateTime createdAt;

  const ScriptVersion({
    required this.id,
    required this.presentationId,
    required this.version,
    required this.text,
    this.parentVersionId,
    required this.createdBy,
    required this.createdAt,
  });

  String get label => 'v$version';

  ScriptVersion copyWith({
    String? id,
    String? presentationId,
    int? version,
    String? text,
    String? parentVersionId,
    ScriptVersionOrigin? createdBy,
    DateTime? createdAt,
  }) {
    return ScriptVersion(
      id: id ?? this.id,
      presentationId: presentationId ?? this.presentationId,
      version: version ?? this.version,
      text: text ?? this.text,
      parentVersionId: parentVersionId ?? this.parentVersionId,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'presentation_id': presentationId,
      'version': version,
      'text': text,
      'parent_version_id': parentVersionId,
      'created_by': createdBy.name,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory ScriptVersion.fromMap(Map<String, dynamic> map) {
    return ScriptVersion(
      id: map['id'] as String,
      presentationId: map['presentation_id'] as String,
      version: map['version'] as int,
      text: map['text'] as String,
      parentVersionId: map['parent_version_id'] as String?,
      createdBy: ScriptVersionOriginExtension.fromName(
        map['created_by'] as String,
      ),
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  String toJson() => json.encode(toMap());

  factory ScriptVersion.fromJson(String source) =>
      ScriptVersion.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'ScriptVersion(id: $id, presentationId: $presentationId, version: $version, textLength: ${text.length}, parentVersionId: $parentVersionId, createdBy: $createdBy, createdAt: $createdAt)';
  }

  @override
  bool operator ==(covariant ScriptVersion other) {
    if (identical(this, other)) return true;

    return other.id == id &&
        other.presentationId == presentationId &&
        other.version == version &&
        other.text == text &&
        other.parentVersionId == parentVersionId &&
        other.createdBy == createdBy &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        presentationId.hashCode ^
        version.hashCode ^
        text.hashCode ^
        parentVersionId.hashCode ^
        createdBy.hashCode ^
        createdAt.hashCode;
  }
}
