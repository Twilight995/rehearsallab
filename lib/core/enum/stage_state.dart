/// 처리 파이프라인 단계별 상태 (통합 문서 1장). 화면 17 · 18 · 19.
enum StageState { pending, running, succeeded, failed }

extension StageStateExtension on StageState {
  String get title => switch (this) {
    StageState.pending => '대기',
    StageState.running => '처리 중',
    StageState.succeeded => '완료',
    StageState.failed => '실패',
  };

  static StageState fromName(String name) => StageState.values.firstWhere(
    (e) => e.name == name,
    orElse: () => StageState.pending,
  );
}
