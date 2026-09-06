/// 앱 모드 (통합 문서 5장). 빌드 설정으로 결정, 런타임 변경 없음.
/// - mock: 외부 요청 0건. Mock 서비스로 전체 루프 실행. 화면에 "개발용 목업" 배지.
/// - live: Http 서비스. 제공사 설정 + 최신 동의 대조를 통과해야 실행.
enum AppMode { mock, live }

extension AppModeExtension on AppMode {
  static AppMode fromRaw(String raw) => switch (raw) {
    'live' => AppMode.live,
    _ => AppMode.mock,
  };

  bool get isMock => this == AppMode.mock;

  String get badgeLabel => switch (this) {
    AppMode.mock => '개발용 목업',
    AppMode.live => '실서비스',
  };
}
