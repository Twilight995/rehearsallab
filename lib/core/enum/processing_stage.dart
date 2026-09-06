/// 리허설 처리 5단계 (기획서 §5.2 처리 중 화면). 순서 = 실행 순서.
enum ProcessingStage { upload, transcribe, metrics, align, interpret }

extension ProcessingStageExtension on ProcessingStage {
  String get title => switch (this) {
    ProcessingStage.upload => '업로드',
    ProcessingStage.transcribe => '받아쓰기',
    ProcessingStage.metrics => '지표 계산',
    ProcessingStage.align => '원고 대조',
    ProcessingStage.interpret => 'AI 해석',
  };

  /// 단계가 실행되는 위치 (통합 문서 9장 질문 B 합의: 단계별 표기).
  /// 제공사명은 ProviderConfig에서 주입하므로 여기서는 종류만 구분한다.
  ProcessingLocation get location => switch (this) {
    ProcessingStage.upload ||
    ProcessingStage.metrics ||
    ProcessingStage.align => ProcessingLocation.appServer,
    ProcessingStage.transcribe => ProcessingLocation.stt,
    ProcessingStage.interpret => ProcessingLocation.llm,
  };

  static ProcessingStage fromName(String name) => ProcessingStage.values
      .firstWhere((e) => e.name == name, orElse: () => ProcessingStage.upload);
}

enum ProcessingLocation { appServer, stt, llm }

extension ProcessingLocationExtension on ProcessingLocation {
  /// 제공사명이 없을 때의 기본 표기
  String get fallbackLabel => switch (this) {
    ProcessingLocation.appServer => '앱 서버',
    ProcessingLocation.stt => '음성인식 제공사',
    ProcessingLocation.llm => 'AI 제공사',
  };
}
