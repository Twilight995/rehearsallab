import 'package:flutter/material.dart';

/// Pen 디자인 토큰 `color/*` (rehearsallab.pen) → Dart.
/// 위젯 안에서 Color(0xFF...)를 직접 쓰지 않고 항상 여기서 가져온다.
class AppColors {
  AppColors._();

  static const Color navy900 = Color(0xFF070B1F);
  static const Color navy700 = Color(0xFF131C4D);
  static const Color blue500 = Color(0xFF1F6FE5);
  static const Color blue100 = Color(0xFFE3EEFF);
  static const Color ice300 = Color(0xFFBFE9F4);
  static const Color ice100 = Color(0xFFEAF7FB);

  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceMuted = Color(0xFFF4F6FA);
  static const Color bg = Color(0xFFFFFFFF);

  static const Color textPrimary = Color(0xFF0B0F1F);
  static const Color textSecondary = Color(0xFF5F6779);
  static const Color textTertiary = Color(0xFF9AA3B2);
  static const Color border = Color(0xFFE6E9F0);

  static const Color success = Color(0xFF1FA36A);
  static const Color successBg = Color(0xFFE4F6ED);
  static const Color warning = Color(0xFFE58A0C);
  static const Color warningBg = Color(0xFFFDF1DE);
  static const Color danger = Color(0xFFE2454B);
  static const Color dangerBg = Color(0xFFFDE8E9);

  static const Color onDark = Color(0xFFFFFFFF);
  static const Color onDarkMuted = Color(0xA6FFFFFF);
  static const Color onDarkSurface = Color(0x1FFFFFFF);

  /// 온보딩 히어로 그라데이션 (통합 문서 6장)
  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [ice300, Color(0xFF8FC9E6), Color(0xFF2C4C9C), navy900],
    stops: [0, 0.35, 0.7, 1],
  );

  /// 홈 헤더 · 리포트 헤더 · 총평 카드 그라데이션
  static const LinearGradient darkHeaderGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [navy900, Color(0xFF1B2B6B)],
  );

  /// 녹음 화면 배경
  static const LinearGradient recordingGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF0B1230), navy900],
  );
}
