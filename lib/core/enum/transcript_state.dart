/// 전사문 원본 상태 (통합 문서 5장 Rehearsal.transcript.state).
/// - stored: 녹음과 같은 보관 정책으로 보관 중
/// - tempRetained: 즉시 삭제 옵션에서 AI 실패 → 재시도용 임시 보관 (최초 실패 + 24h)
/// - deleted: 삭제됨 (새 AI 재분석 불가)
enum TranscriptState { stored, tempRetained, deleted }

extension TranscriptStateExtension on TranscriptState {
  String get title => switch (this) {
    TranscriptState.stored => '보관 중',
    TranscriptState.tempRetained => '재시도용 임시 보관',
    TranscriptState.deleted => '삭제됨',
  };

  bool get canRetryInterpret => this != TranscriptState.deleted;

  static TranscriptState fromName(String name) => TranscriptState.values
      .firstWhere((e) => e.name == name, orElse: () => TranscriptState.deleted);
}
