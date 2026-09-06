// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:rehearsallab/core/enum/dimension_key.dart';

/// Top 3 개선 액션 (원고 분석 · 리허설 리포트 공통). 체크는 "반영함" 기록만 남긴다.
class TopAction {
  final String text;
  final DateTime? checkedAt;

  const TopAction({required this.text, this.checkedAt});

  bool get isChecked => checkedAt != null;

  TopAction copyWith({String? text, DateTime? checkedAt, bool clear = false}) {
    return TopAction(
      text: text ?? this.text,
      checkedAt: clear ? null : (checkedAt ?? this.checkedAt),
    );
  }

  Map<String, dynamic> toMap() => <String, dynamic>{
    'text': text,
    'checked_at': checkedAt?.toIso8601String(),
  };

  factory TopAction.fromMap(Map<String, dynamic> map) => TopAction(
    text: map['text'] as String,
    checkedAt: map['checked_at'] != null
        ? DateTime.parse(map['checked_at'] as String)
        : null,
  );

  @override
  bool operator ==(covariant TopAction other) {
    if (identical(this, other)) return true;
    return other.text == text && other.checkedAt == checkedAt;
  }

  @override
  int get hashCode => text.hashCode ^ checkedAt.hashCode;
}

/// 차원 피드백 카드 (근거 인용이 먼저, 점수는 작게).
class DimensionFeedback {
  final DimensionKey key;

  /// 1~5
  final int score;
  final String evidenceQuote;

  /// 예: "## 방법 · 3번째 문단", "4:58 구간"
  final String evidenceLocation;
  final String problem;
  final String suggestion;

  const DimensionFeedback({
    required this.key,
    required this.score,
    required this.evidenceQuote,
    required this.evidenceLocation,
    required this.problem,
    required this.suggestion,
  });

  DimensionFeedback copyWith({
    DimensionKey? key,
    int? score,
    String? evidenceQuote,
    String? evidenceLocation,
    String? problem,
    String? suggestion,
  }) {
    return DimensionFeedback(
      key: key ?? this.key,
      score: score ?? this.score,
      evidenceQuote: evidenceQuote ?? this.evidenceQuote,
      evidenceLocation: evidenceLocation ?? this.evidenceLocation,
      problem: problem ?? this.problem,
      suggestion: suggestion ?? this.suggestion,
    );
  }

  Map<String, dynamic> toMap() => <String, dynamic>{
    'key': key.name,
    'score': score,
    'evidence_quote': evidenceQuote,
    'evidence_location': evidenceLocation,
    'problem': problem,
    'suggestion': suggestion,
  };

  factory DimensionFeedback.fromMap(Map<String, dynamic> map) =>
      DimensionFeedback(
        key: DimensionKeyExtension.fromName(map['key'] as String),
        score: map['score'] as int,
        evidenceQuote: map['evidence_quote'] as String,
        evidenceLocation: map['evidence_location'] as String,
        problem: map['problem'] as String,
        suggestion: map['suggestion'] as String,
      );

  @override
  bool operator ==(covariant DimensionFeedback other) {
    if (identical(this, other)) return true;
    return other.key == key &&
        other.score == score &&
        other.evidenceQuote == evidenceQuote &&
        other.evidenceLocation == evidenceLocation &&
        other.problem == problem &&
        other.suggestion == suggestion;
  }

  @override
  int get hashCode =>
      key.hashCode ^
      score.hashCode ^
      evidenceQuote.hashCode ^
      evidenceLocation.hashCode ^
      problem.hashCode ^
      suggestion.hashCode;
}
