import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rehearsallab/app/router/app_page.dart';
import 'package:rehearsallab/app/theme/app_theme.dart';
import 'package:rehearsallab/ui/pages/splash/splash_page.dart';

import 'screenshot_helper.dart';

/// C1-1 화면 00 · 01 · 02 · 03 스크린샷 (320 · 390 · 430). 실행:
/// flutter test test_screenshots --update-goldens
void main() {
  setUpAll(loadKoreanFallbackFonts);

  for (final width in [320.0, 390.0, 430.0]) {
    final w = width.toInt();

    testWidgets('splash_$w', (tester) async {
      await pumpScreenshotApp(
        tester,
        initialLocation: '/',
        width: width,
        router: GoRouter(
          initialLocation: '/',
          routes: [
            GoRoute(
              path: '/',
              builder: (_, _) => const SplashPage(delay: Duration(days: 1)),
            ),
          ],
        ),
      );
      await capture(tester, 'splash_$w');
    });

    testWidgets('onboarding_intro_1_$w', (tester) async {
      await pumpScreenshotApp(
        tester,
        initialLocation: AppPage.onboardingIntro.path,
        width: width,
      );
      await capture(tester, 'onboarding_intro_1_$w');
    });

    testWidgets('onboarding_intro_2_$w', (tester) async {
      await pumpScreenshotApp(
        tester,
        initialLocation: AppPage.onboardingIntro.path,
        width: width,
      );
      await tester.tap(find.text('다음'));
      await tester.pumpAndSettle();
      await capture(tester, 'onboarding_intro_2_$w');
    });

    testWidgets('onboarding_privacy_$w', (tester) async {
      await pumpScreenshotApp(
        tester,
        initialLocation: AppPage.onboardingPrivacy.path,
        width: width,
      );
      await tester.ensureVisible(find.textContaining('이해했고 동의합니다'));
      await tester.tap(find.textContaining('이해했고 동의합니다'));
      await tester.pumpAndSettle();
      await capture(tester, 'onboarding_privacy_$w');
    });
  }

  testWidgets('onboarding_privacy_320_x1.3 (큰 글자)', (tester) async {
    await pumpScreenshotApp(
      tester,
      initialLocation: AppPage.onboardingPrivacy.path,
      width: 320,
      height: 640,
      scale: 1.3,
    );
    await capture(tester, 'onboarding_privacy_320_640_130');
  });

  testWidgets('theme sanity', (tester) async {
    expect(AppTheme.light.brightness, Brightness.light);
  });
}
