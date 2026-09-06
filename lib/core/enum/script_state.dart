import 'package:rehearsallab/core/enum/badge_tone.dart';

/// 원고 탭 상태 (통합 문서 1장). 화면 10 · 11 · 11b · 12 · 13 · 38.
enum ScriptState { empty, saved, analyzing, analyzed, dirty, failed }

extension ScriptStateExtension on ScriptState {
  /// 발표 상세 헤더의 단계 배지 문구
  String get badgeLabel => switch (this) {
    ScriptState.empty => '원고 없음',
    ScriptState.saved => '원고 저장됨',
    ScriptState.analyzing => '분석 중',
    ScriptState.analyzed => '분석 완료',
    ScriptState.dirty => '재분석 필요',
    ScriptState.failed => '분석 실패',
  };

  BadgeTone get tone => switch (this) {
    ScriptState.empty || ScriptState.saved => BadgeTone.neutral,
    ScriptState.analyzing || ScriptState.analyzed => BadgeTone.info,
    ScriptState.dirty => BadgeTone.warning,
    ScriptState.failed => BadgeTone.danger,
  };

  static ScriptState fromName(String name) => ScriptState.values.firstWhere(
    (e) => e.name == name,
    orElse: () => ScriptState.empty,
  );
}
