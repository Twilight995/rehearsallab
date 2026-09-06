/// Pen 디자인 토큰 `space/*` → Dart.
class AppSpacing {
  AppSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;

  /// 화면 가로 패딩 (모든 화면 공통)
  static const double page = 20;

  /// 디자인 기준 폭 (390 logical px). 강제하지 않고 참고용.
  static const double designWidth = 390;

  /// 태블릿·가로 모드에서 본문 최대 폭 (통합 문서 7장)
  static const double contentMaxWidth = 480;

  /// 최소 터치 영역 (통합 문서 7장)
  static const double touchTarget = 48;
}

/// Pen 디자인 토큰 `radius/*` → Dart.
class AppRadius {
  AppRadius._();

  static const double sm = 8;
  static const double md = 14;
  static const double lg = 20;
  static const double sheet = 24;
  static const double pill = 999;
}
