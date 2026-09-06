import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rehearsallab/app/router/app_page.dart';
import 'package:rehearsallab/app/app_strings.dart';

import 'screenshot_helper.dart';

/// C1-2 화면 04 · 05 스크린샷 (320 · 390 · 430 + 오류 상태 1장). 실행:
/// flutter test test_screenshots --update-goldens
void main() {
  setUpAll(loadKoreanFallbackFonts);

  for (final width in [320.0, 390.0, 430.0]) {
    final w = width.toInt();

    testWidgets('login_$w', (tester) async {
      await pumpScreenshotApp(
        tester,
        initialLocation: AppPage.login.path,
        width: width,
      );
      await tester.enterText(
        find.byType(TextField).first,
        'k.student@univ.ac.kr',
      );
      await tester.enterText(find.byType(TextField).last, 'rehearsal');
      await tester.pump();
      await capture(tester, 'login_$w');
    });

    testWidgets('signup_$w', (tester) async {
      await pumpScreenshotApp(
        tester,
        initialLocation: AppPage.signup.path,
        width: width,
      );
      await capture(tester, 'signup_$w');
    });
  }

  testWidgets('login_390_error', (tester) async {
    await pumpScreenshotApp(
      tester,
      initialLocation: AppPage.login.path,
      width: 390,
    );
    await tester.enterText(find.byType(TextField).first, 'k.student');
    await tester.tap(find.text(AppStrings.loginButton));
    await tester.pumpAndSettle();
    await capture(tester, 'login_390_error');
  });

  testWidgets('signup_320_640_130 (큰 글자)', (tester) async {
    await pumpScreenshotApp(
      tester,
      initialLocation: AppPage.signup.path,
      width: 320,
      height: 640,
      scale: 1.3,
    );
    await capture(tester, 'signup_320_640_130');
  });
}
