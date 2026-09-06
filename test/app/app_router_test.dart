import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rehearsallab/app/router/app_page.dart';
import 'package:rehearsallab/app/router/app_router.dart';
import 'package:rehearsallab/ui/pages/home/home_page.dart';
import 'package:rehearsallab/ui/pages/recording/recording_page.dart';
import 'package:rehearsallab/ui/pages/report/report_page.dart';

void main() {
  Future<GoRouter> pumpApp(WidgetTester tester) async {
    final router = buildAppRouter(initialLocation: AppPage.home.path);
    await tester.pumpWidget(
      ProviderScope(child: MaterialApp.router(routerConfig: router)),
    );
    await tester.pumpAndSettle();
    return router;
  }

  group('라우터 인자 계약 (P0-REV-02)', () {
    test('location()은 query parameter로 인자를 붙인다', () {
      expect(
        AppPage.recording.location({
          RouteParam.presentationId: 'p1',
          RouteParam.scriptVersionId: 'v3',
        }),
        '/recording?presentationId=p1&scriptVersionId=v3',
      );
      expect(AppPage.home.location(), '/home');
    });

    test('필수 인자 목록', () {
      expect(AppPage.recording.requiredParams, [
        RouteParam.presentationId,
        RouteParam.scriptVersionId,
      ]);
      expect(AppPage.report.requiredParams, [RouteParam.rehearsalId]);
      expect(AppPage.home.requiredParams, isEmpty);
    });

    test('guardRequiredParams: 비어 있으면 홈으로, 있으면 null', () {
      expect(
        guardRequiredParams(AppPage.recording, {
          RouteParam.presentationId: 'p1',
        }),
        AppPage.home.path,
      );
      expect(
        guardRequiredParams(AppPage.recording, {
          RouteParam.presentationId: 'p1',
          RouteParam.scriptVersionId: '  ',
        }),
        AppPage.home.path,
      );
      expect(
        guardRequiredParams(AppPage.recording, {
          RouteParam.presentationId: 'p1',
          RouteParam.scriptVersionId: 'v3',
        }),
        isNull,
      );
    });

    testWidgets('query로 전달한 원고 버전이 녹음 페이지에 도착한다', (tester) async {
      final router = await pumpApp(tester);
      router.go(
        AppPage.recording.location({
          RouteParam.presentationId: 'p1',
          RouteParam.scriptVersionId: 'v3',
        }),
      );
      await tester.pumpAndSettle();
      final page = tester.widget<RecordingPage>(find.byType(RecordingPage));
      expect(page.presentationId, 'p1');
      expect(page.scriptVersionId, 'v3');
    });

    testWidgets('extra Map으로 전달해도 같은 키로 병합된다', (tester) async {
      final router = await pumpApp(tester);
      router.go(
        AppPage.recording.path,
        extra: {
          RouteParam.presentationId: 'p1',
          RouteParam.scriptVersionId: 'v3',
        },
      );
      await tester.pumpAndSettle();
      final page = tester.widget<RecordingPage>(find.byType(RecordingPage));
      expect(page.scriptVersionId, 'v3');
    });

    testWidgets('필수 인자 누락 → 홈으로 redirect (빈 버전으로 녹음 페이지에 도착하지 않음)', (
      tester,
    ) async {
      final router = await pumpApp(tester);
      router.go(AppPage.recording.path);
      await tester.pumpAndSettle();
      expect(find.byType(RecordingPage), findsNothing);
      expect(find.byType(HomePage), findsOneWidget);
    });

    testWidgets('문자열 하나만 extra로 넘기면 무시되어 홈으로 redirect', (tester) async {
      final router = await pumpApp(tester);
      router.go(AppPage.report.path, extra: 'r-1');
      await tester.pumpAndSettle();
      expect(find.byType(ReportPage), findsNothing);
      expect(find.byType(HomePage), findsOneWidget);
    });

    testWidgets('query가 extra보다 우선한다', (tester) async {
      final router = await pumpApp(tester);
      router.go(
        AppPage.report.location({RouteParam.rehearsalId: 'from-query'}),
        extra: {RouteParam.rehearsalId: 'from-extra'},
      );
      await tester.pumpAndSettle();
      expect(
        tester.widget<ReportPage>(find.byType(ReportPage)).rehearsalId,
        'from-query',
      );
    });
  });
}
