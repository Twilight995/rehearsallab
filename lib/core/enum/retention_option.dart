/// 녹음 · 전사문 보관 기간 옵션 (기획서 §6, 통합 문서 9장 합의).
/// 만료는 recordedAt 기준이며 재분석해도 연장되지 않는다.
enum RetentionOption { days7, days30, immediate }

extension RetentionOptionExtension on RetentionOption {
  String get title => switch (this) {
    RetentionOption.days7 => '7일',
    RetentionOption.days30 => '30일',
    RetentionOption.immediate => '처리 후 즉시 삭제',
  };

  /// null = 처리 완료 직후 삭제
  Duration? get duration => switch (this) {
    RetentionOption.days7 => const Duration(days: 7),
    RetentionOption.days30 => const Duration(days: 30),
    RetentionOption.immediate => null,
  };

  static RetentionOption fromName(String name) => RetentionOption.values
      .firstWhere((e) => e.name == name, orElse: () => RetentionOption.days7);
}
