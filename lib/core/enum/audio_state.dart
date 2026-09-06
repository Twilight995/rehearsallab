/// 녹음 원본 상태 (통합 문서 5장 Rehearsal.audio.state).
/// - localOnly: 기기에만 있음 (외부 전송 전, 업로드 실패 재시도 대기)
/// - stored: 보관 중 (구간 재생 가능)
/// - expired: 보관 기간 만료로 삭제됨
/// - deleted: 즉시 삭제 옵션 또는 사용자 삭제
enum AudioState { localOnly, stored, expired, deleted }

extension AudioStateExtension on AudioState {
  String get title => switch (this) {
    AudioState.localOnly => '기기에만 저장됨',
    AudioState.stored => '보관 중',
    AudioState.expired => '보관 기간 만료',
    AudioState.deleted => '삭제됨',
  };

  bool get isPlayable => this == AudioState.stored;

  static AudioState fromName(String name) => AudioState.values.firstWhere(
    (e) => e.name == name,
    orElse: () => AudioState.deleted,
  );
}
