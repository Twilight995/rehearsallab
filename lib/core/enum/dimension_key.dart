import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// 피드백 차원 (기획서 §5.1 원고 3차원, §5.2 리포트 6차원).
enum DimensionKey { logic, clarity, audience, timing, delivery, fidelity }

extension DimensionKeyExtension on DimensionKey {
  String get title => switch (this) {
    DimensionKey.logic => '논리 구조',
    DimensionKey.clarity => '명료성',
    DimensionKey.audience => '청중 적합성',
    DimensionKey.timing => '시간 배분',
    DimensionKey.delivery => '전달력',
    DimensionKey.fidelity => '원고 충실도',
  };

  /// 원고 분석(12번)에서 쓰는 긴 제목
  String get scriptTitle => switch (this) {
    DimensionKey.clarity => '명료성 · 용어',
    _ => title,
  };

  IconData get icon => switch (this) {
    DimensionKey.logic => LucideIcons.gitBranch,
    DimensionKey.clarity => LucideIcons.type,
    DimensionKey.audience => LucideIcons.users,
    DimensionKey.timing => LucideIcons.timer,
    DimensionKey.delivery => LucideIcons.audioLines,
    DimensionKey.fidelity => LucideIcons.fileCheck,
  };

  /// 원고 분석 단계에서 평가하는 3차원
  bool get isScriptDimension =>
      this == DimensionKey.logic ||
      this == DimensionKey.clarity ||
      this == DimensionKey.audience;

  static DimensionKey fromName(String name) => DimensionKey.values.firstWhere(
    (e) => e.name == name,
    orElse: () => DimensionKey.logic,
  );
}
