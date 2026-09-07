import 'package:flutter_test/flutter_test.dart';
import 'package:rehearsallab/services/auth_service.dart';

/// PBKDF2 비용 측정 (개발용, 기본 `flutter test`에는 포함되지 않음).
/// 실행: flutter test tool/kdf_bench_test.dart
/// 실기기는 `flutter run --release`로 설치한 뒤 로그인 1회 소요 시간(로그 "kdf")으로 확인한다.
void main() {
  test('PBKDF2-HMAC-SHA256 반복 횟수별 소요 시간', () {
    for (final n in [210000, 600000]) {
      final sw = Stopwatch()..start();
      PasswordHasher.derive('password1', 'salt-salt-salt-1', n);
      // ignore: avoid_print
      print('$n iterations: ${sw.elapsedMilliseconds} ms');
    }
  });
}
