/// 녹음 상태 (통합 문서 1장). 화면 20 · 25 · 26 · 14 · 15 · 16 · 27 · 28 · 29.
enum RecordingState {
  ready,
  permissionDenied,
  countingDown,
  recording,
  paused,
  confirmingStop,
  confirmingDiscard,
  autoStopped,
}

extension RecordingStateExtension on RecordingState {
  /// 녹음 화면 상단 상태 필 문구
  String get pillLabel => switch (this) {
    RecordingState.ready => '대기',
    RecordingState.permissionDenied => '권한 없음',
    RecordingState.countingDown => '대기',
    RecordingState.recording => '녹음 중',
    RecordingState.paused ||
    RecordingState.confirmingStop ||
    RecordingState.confirmingDiscard => '일시정지됨',
    RecordingState.autoStopped => '자동 종료',
  };

  /// 누적 녹음 시간이 흐르는 상태인지
  bool get isCapturing => this == RecordingState.recording;
}
