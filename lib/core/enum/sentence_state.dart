import 'package:flutter/material.dart';
import 'package:rehearsallab/app/theme/app_colors.dart';

/// 원고 대조 문장 상태 (기획서 §5.2 원고 대조 뷰 + 부분 리허설 notReached).
enum SentenceState { read, missed, added, reordered, notReached }

extension SentenceStateExtension on SentenceState {
  /// 대조 뷰 태그 문구. 색과 함께 항상 표시한다 (접근성 규칙).
  String get tag => switch (this) {
    SentenceState.read => '읽음',
    SentenceState.missed => '빠뜨림',
    SentenceState.added => '즉흥 추가',
    SentenceState.reordered => '순서 바뀜',
    SentenceState.notReached => '미도달',
  };

  Color get color => switch (this) {
    SentenceState.read => AppColors.textPrimary,
    SentenceState.missed => AppColors.danger,
    SentenceState.added => AppColors.warning,
    SentenceState.reordered => AppColors.blue500,
    SentenceState.notReached => AppColors.textTertiary,
  };

  Color get markerColor => switch (this) {
    SentenceState.read => AppColors.border,
    SentenceState.notReached => AppColors.border,
    _ => color,
  };

  /// 녹음에 존재하는 문장인지 (재생 탭 가능 여부)
  bool get hasAudio =>
      this == SentenceState.read ||
      this == SentenceState.added ||
      this == SentenceState.reordered;

  static SentenceState fromName(String name) => SentenceState.values.firstWhere(
    (e) => e.name == name,
    orElse: () => SentenceState.read,
  );
}
