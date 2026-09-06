import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rehearsallab/core/enum/app_mode.dart';

/// 빌드 설정. 런타임에 바꾸지 않는다 (통합 문서 5장 앱 모드).
/// flutter run --dart-define=APP_MODE=live  (기본 mock)
class AppConfig {
  AppConfig._();

  static const String _appModeRaw = String.fromEnvironment(
    'APP_MODE',
    defaultValue: 'mock',
  );

  static AppMode get appMode => AppModeExtension.fromRaw(_appModeRaw);

  /// 프로토타입 녹음 상한 (누적 녹음 시간 기준, Q&A 미합산)
  static const int recordingCapMinutes = 20;

  /// 발표 시간 입력 범위
  static const int talkMinutesMin = 1;
  static const int talkMinutesMax = 60;
  static const int qaMinutesMin = 0;
  static const int qaMinutesMax = 60;

  /// 카운트다운 (녹음 길이에서 제외)
  static const int countdownSeconds = 3;

  /// 즉시 삭제 옵션에서 AI 실패 시 전사문 임시 보관 (최초 실패 시각 기준)
  static const Duration transcriptRetryWindow = Duration(hours: 24);

  /// 업로드 · 받아쓰기 실패 시 기기 녹음 보관 (최초 실패 시각 기준)
  static const Duration localAudioRetryWindow = Duration(days: 7);

  /// 평균 읽기 속도 (어절/분) — 원고 예상 시간 계산 가정
  static const int averageWordsPerMinute = 135;
}

final appModeProvider = Provider<AppMode>((ref) => AppConfig.appMode);
