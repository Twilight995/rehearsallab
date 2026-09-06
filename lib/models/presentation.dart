// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:rehearsallab/core/enum/audience.dart';
import 'package:rehearsallab/core/enum/presentation_type.dart';

/// 발표 (통합 문서 5장). JSON 키는 snake_case.
class Presentation {
  final String id;
  final String title;
  final PresentationType type;

  /// 1~60 (AppConfig.talkMinutesMin/Max)
  final int talkMinutes;

  /// 0 이상. 0 = 질의응답 없음
  final int qaMinutes;
  final Audience audience;

  /// null = 날짜 미정 (홈에서 "날짜 미정" 표시, 날짜 있는 발표 뒤에 정렬)
  final DateTime? date;
  final DateTime createdAt;

  const Presentation({
    required this.id,
    required this.title,
    required this.type,
    required this.talkMinutes,
    required this.qaMinutes,
    required this.audience,
    this.date,
    required this.createdAt,
  });

  /// 발표 규격 문구: "15분 + Q&A 5분" / "15분" (Q&A 0)
  String get timeSpecLabel =>
      qaMinutes > 0 ? '$talkMinutes분 + Q&A $qaMinutes분' : '$talkMinutes분';

  /// 발표 규격이 프로토타입 녹음 상한(20분)을 넘는지
  bool exceedsRecordingCap(int capMinutes) => talkMinutes > capMinutes;

  Presentation copyWith({
    String? id,
    String? title,
    PresentationType? type,
    int? talkMinutes,
    int? qaMinutes,
    Audience? audience,
    DateTime? date,
    bool clearDate = false,
    DateTime? createdAt,
  }) {
    return Presentation(
      id: id ?? this.id,
      title: title ?? this.title,
      type: type ?? this.type,
      talkMinutes: talkMinutes ?? this.talkMinutes,
      qaMinutes: qaMinutes ?? this.qaMinutes,
      audience: audience ?? this.audience,
      date: clearDate ? null : (date ?? this.date),
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'title': title,
      'type': type.name,
      'talk_minutes': talkMinutes,
      'qa_minutes': qaMinutes,
      'audience': audience.name,
      'date': date?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Presentation.fromMap(Map<String, dynamic> map) {
    return Presentation(
      id: map['id'] as String,
      title: map['title'] as String,
      type: PresentationTypeExtension.fromName(map['type'] as String),
      talkMinutes: map['talk_minutes'] as int,
      qaMinutes: map['qa_minutes'] as int? ?? 0,
      audience: AudienceExtension.fromName(map['audience'] as String),
      date: map['date'] != null ? DateTime.parse(map['date'] as String) : null,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  String toJson() => json.encode(toMap());

  factory Presentation.fromJson(String source) =>
      Presentation.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'Presentation(id: $id, title: $title, type: $type, talkMinutes: $talkMinutes, qaMinutes: $qaMinutes, audience: $audience, date: $date, createdAt: $createdAt)';
  }

  @override
  bool operator ==(covariant Presentation other) {
    if (identical(this, other)) return true;

    return other.id == id &&
        other.title == title &&
        other.type == type &&
        other.talkMinutes == talkMinutes &&
        other.qaMinutes == qaMinutes &&
        other.audience == audience &&
        other.date == date &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        title.hashCode ^
        type.hashCode ^
        talkMinutes.hashCode ^
        qaMinutes.hashCode ^
        audience.hashCode ^
        date.hashCode ^
        createdAt.hashCode;
  }
}
