import 'package:rehearsallab/core/enum/audio_state.dart';

/// 리포트 표시 모드. **표시용 파생값**이며 저장하지 않는다 (통합 문서 5장).
/// 진실의 원천은 stages.interpret + audio.state + transcript.state.
enum ReportMode { complete, partial, audioUnavailable }

extension ReportModeExtension on ReportMode {
  /// AI 결과 유무와 오디오 상태로부터 표시 모드 목록을 만든다.
  /// "AI 실패 + 녹음 삭제"처럼 두 모드가 동시에 해당할 수 있으므로 Set을 반환한다.
  static Set<ReportMode> derive({
    required bool hasAi,
    required AudioState audioState,
  }) {
    final modes = <ReportMode>{};
    if (!hasAi) modes.add(ReportMode.partial);
    if (audioState == AudioState.expired || audioState == AudioState.deleted) {
      modes.add(ReportMode.audioUnavailable);
    }
    if (modes.isEmpty) modes.add(ReportMode.complete);
    return modes;
  }

  String get badgeLabel => switch (this) {
    ReportMode.complete => '전체 리포트',
    ReportMode.partial => '부분 결과',
    ReportMode.audioUnavailable => '녹음 보관 만료',
  };
}
