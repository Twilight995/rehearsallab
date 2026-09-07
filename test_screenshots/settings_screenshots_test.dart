import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rehearsallab/app/app_strings.dart';
import 'package:rehearsallab/app/router/app_page.dart';
import 'package:rehearsallab/services/mock/demo_data.dart';

import 'screenshot_helper.dart';

/// C1-4 · C1-5 화면 09 · 31 · 32 · 23 · 24 스크린샷 (320 · 390 · 430 + 큰 글자 · 태블릿). 실행:
/// flutter test test_screenshots --update-goldens
void main() {
  setUpAll(loadKoreanFallbackFonts);

  final pages = <(String, String)>[
    ('settings', AppPage.settings.path),
    ('delete_step1', AppPage.deleteConfirm.location({RouteParam.step: '1'})),
    ('delete_step2', AppPage.deleteConfirm.location({RouteParam.step: '2'})),
    (
      'detail_qa',
      AppPage.presentationDetail.location({
        RouteParam.presentationId: DemoData.presentationId,
        RouteParam.tab: 'qa',
      }),
    ),
    (
      'detail_history',
      AppPage.presentationDetail.location({
        RouteParam.presentationId: DemoData.presentationId,
        RouteParam.tab: 'history',
      }),
    ),
  ];

  for (final (name, initial) in pages) {
    for (final width in [320.0, 390.0, 430.0]) {
      testWidgets('${name}_${width.toInt()}', (tester) async {
        await pumpScreenshotApp(tester, initialLocation: initial, width: width);
        if (name == 'delete_step2') {
          await tester.enterText(find.byType(TextField), '삭제');
          await tester.pump();
        }
        await capture(tester, '${name}_${width.toInt()}');
      });
    }
  }

  testWidgets('settings_320_640_130 (큰 글자)', (tester) async {
    await pumpScreenshotApp(
      tester,
      initialLocation: AppPage.settings.path,
      width: 320,
      height: 640,
      scale: 1.3,
    );
    await capture(tester, 'settings_320_640_130');
  });

  testWidgets('settings_retention_sheet_390', (tester) async {
    await pumpScreenshotApp(
      tester,
      initialLocation: AppPage.settings.path,
      width: 390,
    );
    await tester.tap(find.text(AppStrings.settingsRetention));
    await tester.pumpAndSettle();
    await capture(tester, 'settings_retention_sheet_390');
  });

  testWidgets('detail_qa_1024', (tester) async {
    await pumpScreenshotApp(
      tester,
      initialLocation: AppPage.presentationDetail.location({
        RouteParam.presentationId: DemoData.presentationId,
        RouteParam.tab: 'qa',
      }),
      width: 1024,
      height: 844,
    );
    await capture(tester, 'detail_qa_1024');
  });
}
