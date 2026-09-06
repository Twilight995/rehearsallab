import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rehearsallab/app/router/app_router.dart';
import 'package:rehearsallab/app/theme/app_theme.dart';
import 'package:rehearsallab/features/consent/consent_provider.dart';
import 'package:rehearsallab/models/provider_config.dart';
import 'package:rehearsallab/services/consent_service.dart';

/// 리뷰 첨부용 스크린샷 생성기 (계약서 6.4). `flutter test` 기본 실행에는 포함되지 않으며
/// `flutter test test_screenshots --update-goldens`로 실행해 `docs/screenshots/<page>_<width>.png`를 만든다.
/// 헤드리스 환경이라 google_fonts는 내려받지 않고 Windows의 맑은 고딕을 대체 글꼴로 등록한다.
/// 실기기 렌더와 글꼴 · 상태바 · SafeArea가 다를 수 있으므로 "레이아웃 확인용"으로만 쓴다.
Future<void> loadKoreanFallbackFonts() async {
  GoogleFonts.config.allowRuntimeFetching = false;
  final candidates = [
    r'C:\Windows\Fonts\malgun.ttf',
    '/System/Library/Fonts/AppleSDGothicNeo.ttc',
    '/usr/share/fonts/truetype/nanum/NanumGothic.ttf',
  ];
  for (final path in candidates) {
    final file = File(path);
    if (!file.existsSync()) continue;
    final bytes = ByteData.sublistView(await file.readAsBytes());
    // google_fonts는 '<family>_<weight>' 형식(예: NotoSansKR_regular · Manrope_700)으로 등록한다.
    const families = ['NotoSansKR', 'Manrope', 'Roboto'];
    const variants = ['regular', '500', '600', '700', '800'];
    for (final family in [
      ...families,
      for (final f in families)
        for (final v in variants) '${f}_$v',
    ]) {
      final loader = FontLoader(family)..addFont(Future.value(bytes));
      await loader.load();
    }
    return;
  }
}

Future<void> pumpScreenshotApp(
  WidgetTester tester, {
  required String initialLocation,
  required double width,
  double height = 844,
  double scale = 1.0,
  ConsentService? consentService,
  GoRouter? router,
}) async {
  tester.view.physicalSize = Size(width, height);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        providerConfigProvider.overrideWith(
          (ref) async => ProviderConfig.empty,
        ),
        if (consentService != null)
          consentServiceProvider.overrideWithValue(consentService),
      ],
      child: MediaQuery(
        data: MediaQueryData(
          size: Size(width, height),
          textScaler: TextScaler.linear(scale),
        ),
        child: MaterialApp.router(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          routerConfig:
              router ?? buildAppRouter(initialLocation: initialLocation),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> capture(WidgetTester tester, String name) async {
  await expectLater(
    find.byType(MaterialApp),
    matchesGoldenFile('../docs/screenshots/$name.png'),
  );
}
