import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rehearsallab/app/app_strings.dart';
import 'package:rehearsallab/app/router/app_page.dart';
import 'package:rehearsallab/services/local_store_service.dart';

import 'screenshot_helper.dart';

/// C1-3 화면 06 · 07 · 08 스크린샷 (320 · 390 · 430 + 큰 글자 · 오류 · 태블릿). 실행:
/// flutter test test_screenshots --update-goldens
void main() {
  setUpAll(loadKoreanFallbackFonts);

  for (final width in [320.0, 390.0, 430.0]) {
    final w = width.toInt();

    testWidgets('home_empty_$w', (tester) async {
      await pumpScreenshotApp(
        tester,
        initialLocation: AppPage.home.path,
        width: width,
        store: MemoryLocalStoreService(),
      );
      await capture(tester, 'home_empty_$w');
    });

    testWidgets('home_list_$w', (tester) async {
      await pumpScreenshotApp(
        tester,
        initialLocation: AppPage.home.path,
        width: width,
      );
      await capture(tester, 'home_list_$w');
    });

    testWidgets('presentation_form_$w', (tester) async {
      await pumpScreenshotApp(
        tester,
        initialLocation: AppPage.presentationForm.path,
        width: width,
      );
      await tester.enterText(find.byType(TextField), '○○학회 구두발표');
      await tester.pump();
      await capture(tester, 'presentation_form_$w');
    });
  }

  testWidgets('presentation_form_390_partial (21분 고지 + 오류)', (tester) async {
    await pumpScreenshotApp(
      tester,
      initialLocation: AppPage.presentationForm.path,
      width: 390,
    );
    final plus = find.byTooltip('${AppStrings.formTalkLabel} 1분 늘리기');
    for (var i = 0; i < 6; i++) {
      await tester.tap(plus);
      await tester.pump();
    }
    await tester.ensureVisible(find.text(AppStrings.formSubmit));
    await tester.tap(find.text(AppStrings.formSubmit));
    await tester.pumpAndSettle();
    await capture(tester, 'presentation_form_390_partial_error');
  });

  testWidgets('presentation_form_320_640_130 (큰 글자)', (tester) async {
    await pumpScreenshotApp(
      tester,
      initialLocation: AppPage.presentationForm.path,
      width: 320,
      height: 640,
      scale: 1.3,
    );
    await capture(tester, 'presentation_form_320_640_130');
  });

  testWidgets('home_list_1024', (tester) async {
    await pumpScreenshotApp(
      tester,
      initialLocation: AppPage.home.path,
      width: 1024,
      height: 844,
    );
    await capture(tester, 'home_list_1024');
  });
}
