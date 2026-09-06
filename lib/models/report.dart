// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:rehearsallab/core/enum/match_rate_scope.dart';
import 'package:rehearsallab/core/enum/sentence_state.dart';
import 'package:rehearsallab/models/feedback.dart';

/// 속도 시계열 한 점 (구간 대표값).
class WpmPoint {
  final int timeSec;
  final int wpm;

  const WpmPoint({required this.timeSec, required this.wpm});

  Map<String, dynamic> toMap() => <String, dynamic>{
    'time_sec': timeSec,
    'wpm': wpm,
  };

  factory WpmPoint.fromMap(Map<String, dynamic> map) =>
      WpmPoint(timeSec: map['time_sec'] as int, wpm: map['wpm'] as int);
}

/// 필러(군말) 발생 지점.
class FillerEvent {
  final int timeSec;
  final String text;

  const FillerEvent({required this.timeSec, required this.text});

  Map<String, dynamic> toMap() => <String, dynamic>{
    'time_sec': timeSec,
    'text': text,
  };

  factory FillerEvent.fromMap(Map<String, dynamic> map) =>
      FillerEvent(timeSec: map['time_sec'] as int, text: map['text'] as String);
}

/// 침묵 구간.
class SilenceSpan {
  final int startSec;
  final int endSec;

  const SilenceSpan({required this.startSec, required this.endSec});

  int get durationSec => endSec - startSec;

  Map<String, dynamic> toMap() => <String, dynamic>{
    'start_sec': startSec,
    'end_sec': endSec,
  };

  factory SilenceSpan.fromMap(Map<String, dynamic> map) => SilenceSpan(
    startSec: map['start_sec'] as int,
    endSec: map['end_sec'] as int,
  );
}

/// 섹션별 실제 · 권장 시간.
class SectionTime {
  final String name;
  final int actualSec;
  final int recommendedSec;

  /// 섹션 시작 시각 (타임라인 경계)
  final int startSec;

  const SectionTime({
    required this.name,
    required this.actualSec,
    required this.recommendedSec,
    required this.startSec,
  });

  bool get isOver => actualSec > recommendedSec;

  Map<String, dynamic> toMap() => <String, dynamic>{
    'name': name,
    'actual_sec': actualSec,
    'recommended_sec': recommendedSec,
    'start_sec': startSec,
  };

  factory SectionTime.fromMap(Map<String, dynamic> map) => SectionTime(
    name: map['name'] as String,
    actualSec: map['actual_sec'] as int,
    recommendedSec: map['recommended_sec'] as int,
    startSec: map['start_sec'] as int,
  );
}

/// 코드가 계산한 지표 (AI 실패와 무관하게 항상 존재).
class ReportMetrics {
  final List<WpmPoint> wpmSeries;
  final List<FillerEvent> fillers;
  final List<SilenceSpan> silences;
  final List<SectionTime> sectionTimes;

  const ReportMetrics({
    required this.wpmSeries,
    required this.fillers,
    required this.silences,
    required this.sectionTimes,
  });

  int get averageWpm => wpmSeries.isEmpty
      ? 0
      : (wpmSeries.fold(0, (s, p) => s + p.wpm) / wpmSeries.length).round();

  int get totalSec => sectionTimes.fold(0, (s, t) => s + t.actualSec);

  Map<String, dynamic> toMap() => <String, dynamic>{
    'wpm_series': wpmSeries.map((e) => e.toMap()).toList(),
    'fillers': fillers.map((e) => e.toMap()).toList(),
    'silences': silences.map((e) => e.toMap()).toList(),
    'section_times': sectionTimes.map((e) => e.toMap()).toList(),
  };

  factory ReportMetrics.fromMap(Map<String, dynamic> map) => ReportMetrics(
    wpmSeries: (map['wpm_series'] as List)
        .map((e) => WpmPoint.fromMap(e as Map<String, dynamic>))
        .toList(),
    fillers: (map['fillers'] as List)
        .map((e) => FillerEvent.fromMap(e as Map<String, dynamic>))
        .toList(),
    silences: (map['silences'] as List)
        .map((e) => SilenceSpan.fromMap(e as Map<String, dynamic>))
        .toList(),
    sectionTimes: (map['section_times'] as List)
        .map((e) => SectionTime.fromMap(e as Map<String, dynamic>))
        .toList(),
  );
}

/// 원고 대조 문장. 전체 전사문을 복사하지 않고 원고 문장 참조 + 상태 + 시각만 저장한다.
/// 즉흥 추가(added)만 spokenText를 가진다.
class AlignedSentence {
  /// 원고 문장 인덱스 (added는 삽입 위치의 원고 문장 인덱스)
  final int scriptSentenceRef;
  final SentenceState state;

  /// 녹음 안 위치. missed · notReached는 null
  final int? timeSec;
  final String? spokenText;

  const AlignedSentence({
    required this.scriptSentenceRef,
    required this.state,
    this.timeSec,
    this.spokenText,
  });

  Map<String, dynamic> toMap() => <String, dynamic>{
    'script_sentence_ref': scriptSentenceRef,
    'state': state.name,
    'time_sec': timeSec,
    'spoken_text': spokenText,
  };

  factory AlignedSentence.fromMap(Map<String, dynamic> map) => AlignedSentence(
    scriptSentenceRef: map['script_sentence_ref'] as int,
    state: SentenceStateExtension.fromName(map['state'] as String),
    timeSec: map['time_sec'] as int?,
    spokenText: map['spoken_text'] as String?,
  );
}

/// AI 해석 결과. 실패 시 Report.ai == null.
class AiFeedback {
  final List<TopAction> topActions;

  /// 6차원
  final List<DimensionFeedback> dimensions;
  final DateTime? failedAt;

  const AiFeedback({
    required this.topActions,
    required this.dimensions,
    this.failedAt,
  });

  AiFeedback copyWith({
    List<TopAction>? topActions,
    List<DimensionFeedback>? dimensions,
    DateTime? failedAt,
  }) => AiFeedback(
    topActions: topActions ?? this.topActions,
    dimensions: dimensions ?? this.dimensions,
    failedAt: failedAt ?? this.failedAt,
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    'top_actions': topActions.map((e) => e.toMap()).toList(),
    'dimensions': dimensions.map((e) => e.toMap()).toList(),
    'failed_at': failedAt?.toIso8601String(),
  };

  factory AiFeedback.fromMap(Map<String, dynamic> map) => AiFeedback(
    topActions: (map['top_actions'] as List)
        .map((e) => TopAction.fromMap(e as Map<String, dynamic>))
        .toList(),
    dimensions: (map['dimensions'] as List)
        .map((e) => DimensionFeedback.fromMap(e as Map<String, dynamic>))
        .toList(),
    failedAt: map['failed_at'] != null
        ? DateTime.parse(map['failed_at'] as String)
        : null,
  );
}

/// 리허설 리포트 (통합 문서 5장). 녹음 1개 = 리포트 1개.
class Report {
  final String id;
  final String rehearsalId;
  final ReportMetrics metrics;
  final List<AlignedSentence> alignment;

  /// 0.0 ~ 1.0
  final double matchRate;
  final MatchRateScope matchRateScope;

  /// 전 회차 일치율. scope가 다르거나 첫 회차면 null (증감 미표시)
  final double? prevMatchRate;
  final AiFeedback? ai;
  final DateTime createdAt;

  const Report({
    required this.id,
    required this.rehearsalId,
    required this.metrics,
    required this.alignment,
    required this.matchRate,
    this.matchRateScope = MatchRateScope.full,
    this.prevMatchRate,
    this.ai,
    required this.createdAt,
  });

  bool get hasAi => ai != null;

  int get missedCount =>
      alignment.where((s) => s.state == SentenceState.missed).length;
  int get addedCount =>
      alignment.where((s) => s.state == SentenceState.added).length;
  int get reorderedCount =>
      alignment.where((s) => s.state == SentenceState.reordered).length;

  /// 퍼센트 포인트 증감. 비교 불가면 null
  double? get matchRateDeltaPp =>
      prevMatchRate == null ? null : (matchRate - prevMatchRate!) * 100;

  Report copyWith({
    String? id,
    String? rehearsalId,
    ReportMetrics? metrics,
    List<AlignedSentence>? alignment,
    double? matchRate,
    MatchRateScope? matchRateScope,
    double? prevMatchRate,
    bool clearPrevMatchRate = false,
    AiFeedback? ai,
    bool clearAi = false,
    DateTime? createdAt,
  }) {
    return Report(
      id: id ?? this.id,
      rehearsalId: rehearsalId ?? this.rehearsalId,
      metrics: metrics ?? this.metrics,
      alignment: alignment ?? this.alignment,
      matchRate: matchRate ?? this.matchRate,
      matchRateScope: matchRateScope ?? this.matchRateScope,
      prevMatchRate: clearPrevMatchRate
          ? null
          : (prevMatchRate ?? this.prevMatchRate),
      ai: clearAi ? null : (ai ?? this.ai),
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'rehearsal_id': rehearsalId,
      'metrics': metrics.toMap(),
      'alignment': alignment.map((e) => e.toMap()).toList(),
      'match_rate': matchRate,
      'match_rate_scope': matchRateScope.name,
      'prev_match_rate': prevMatchRate,
      'ai': ai?.toMap(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Report.fromMap(Map<String, dynamic> map) {
    return Report(
      id: map['id'] as String,
      rehearsalId: map['rehearsal_id'] as String,
      metrics: ReportMetrics.fromMap(map['metrics'] as Map<String, dynamic>),
      alignment: (map['alignment'] as List)
          .map((e) => AlignedSentence.fromMap(e as Map<String, dynamic>))
          .toList(),
      matchRate: (map['match_rate'] as num).toDouble(),
      matchRateScope: MatchRateScopeExtension.fromName(
        map['match_rate_scope'] as String? ?? MatchRateScope.full.name,
      ),
      prevMatchRate: (map['prev_match_rate'] as num?)?.toDouble(),
      ai: map['ai'] != null
          ? AiFeedback.fromMap(map['ai'] as Map<String, dynamic>)
          : null,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  String toJson() => json.encode(toMap());

  factory Report.fromJson(String source) =>
      Report.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'Report(id: $id, rehearsalId: $rehearsalId, matchRate: $matchRate, scope: $matchRateScope, hasAi: $hasAi, sentences: ${alignment.length})';
  }

  @override
  bool operator ==(covariant Report other) {
    if (identical(this, other)) return true;
    return other.toJson() == toJson();
  }

  @override
  int get hashCode => toJson().hashCode;
}
