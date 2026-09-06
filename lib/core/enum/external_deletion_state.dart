/// 외부 제공사(STT · LLM) 저장본 삭제 상태 (통합 문서 5장·9장).
/// 우리 서비스의 삭제 완료와 별개 상태이며, 요청 접수만으로 완료라고 표시하지 않는다.
enum ExternalDeletionState {
  notRequested,
  requested,
  done,
  failed,
  unsupported,
  unknown,
}

extension ExternalDeletionStateExtension on ExternalDeletionState {
  String get title => switch (this) {
    ExternalDeletionState.notRequested => '요청 전',
    ExternalDeletionState.requested => '요청 중',
    ExternalDeletionState.done => '완료',
    ExternalDeletionState.failed => '실패',
    ExternalDeletionState.unsupported => 'API 미지원',
    ExternalDeletionState.unknown => '응답 불명',
  };

  static ExternalDeletionState fromName(String name) =>
      ExternalDeletionState.values.firstWhere(
        (e) => e.name == name,
        orElse: () => ExternalDeletionState.notRequested,
      );
}
