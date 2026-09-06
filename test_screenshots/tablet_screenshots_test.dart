import 'package:flutter_test/flutter_test.dart';
import 'package:rehearsallab/app/router/app_page.dart';

import 'screenshot_helper.dart';

/// 태블릿(1024×844) · 가로(844×390) 본문 480 상한 확인용 스크린샷 (C1-REV-05). 실행:
/// flutter test test_screenshots --update-goldens
void main() {
  setUpAll(loadKoreanFallbackFonts);

  for (final (name, page) in [
    ('onboarding_privacy', AppPage.onboardingPrivacy),
    ('login', AppPage.login),
    ('signup', AppPage.signup),
  ]) {
    testWidgets('${name}_1024', (tester) async {
      await pumpScreenshotApp(
        tester,
        initialLocation: page.path,
        width: 1024,
        height: 844,
      );
      await capture(tester, '${name}_1024');
    });

    testWidgets('${name}_844x390 (가로)', (tester) async {
      await pumpScreenshotApp(
        tester,
        initialLocation: page.path,
        width: 844,
        height: 390,
      );
      await capture(tester, '${name}_844x390');
    });
  }
}
