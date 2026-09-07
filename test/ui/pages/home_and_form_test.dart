import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rehearsallab/app/app_strings.dart';
import 'package:rehearsallab/app/router/app_page.dart';
import 'package:rehearsallab/app/router/app_router.dart';
import 'package:rehearsallab/app/theme/app_spacing.dart';
import 'package:rehearsallab/app/theme/app_theme.dart';
import 'package:rehearsallab/core/enum/audience.dart';
import 'package:rehearsallab/core/enum/presentation_type.dart';
import 'package:rehearsallab/core/models/result.dart';
import 'package:rehearsallab/features/consent/consent_provider.dart';
import 'package:rehearsallab/features/presentation/presentation_provider.dart';
import 'package:rehearsallab/models/presentation.dart';
import 'package:rehearsallab/models/provider_config.dart';
import 'package:rehearsallab/services/local_store_service.dart';
import 'package:rehearsallab/services/mock/demo_data.dart';
import 'package:rehearsallab/ui/common/bottom_dock.dart';
import 'package:rehearsallab/ui/common/presentation_card.dart';
import 'package:rehearsallab/ui/common/primary_button.dart';
import 'package:rehearsallab/ui/common/stepper_field.dart';
import 'package:rehearsallab/ui/pages/home/home_page.dart';
import 'package:rehearsallab/ui/pages/presentation_detail/presentation_detail_page.dart';
import 'package:rehearsallab/ui/pages/presentation_form/presentation_form_page.dart';
import 'package:rehearsallab/ui/pages/report/report_page.dart';
import 'package:rehearsallab/ui/pages/settings/settings_page.dart';

/// 저장이 실패하는 저장소 (폼 오류 복구 확인)
class _FailingStore extends MemoryLocalStoreService {
  @override
  Future<Result<void>> savePresentation(Presentation presentation) async =>
      Failure(Exception('disk full'));
}

void main() {
  const widths = [320.0, 390.0, 430.0];
  const scales = [1.0, 1.3];

  Future<GoRouter> pumpApp(
    WidgetTester tester, {
    required String initial,
    LocalStoreService? store,
    Size size = const Size(390, 844),
    double scale = 1.0,
  }) async {
    final router = buildAppRouter(initialLocation: initial);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          providerConfigProvider.overrideWith(
            (ref) async => ProviderConfig.empty,
          ),
          if (store != null) localStoreProvider.overrideWithValue(store),
        ],
        child: MediaQuery(
          data: MediaQueryData(
            size: size,
            textScaler: TextScaler.linear(scale),
          ),
          child: MaterialApp.router(
            theme: AppTheme.light,
            routerConfig: router,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return router;
  }

  Future<void> tapText(WidgetTester tester, String text) async {
    await tester.ensureVisible(find.text(text));
    await tester.tap(find.text(text));
    await tester.pumpAndSettle();
  }

  group('06 빈 홈', () {
    testWidgets('발표 없음 → 인사 · 빈 상태 카드 · FAB 없음 · 0개', (tester) async {
      await pumpApp(
        tester,
        initial: AppPage.home.path,
        store: MemoryLocalStoreService(),
      );
      expect(find.text(AppStrings.homeEmptyBig), findsOneWidget);
      expect(find.text(AppStrings.homeEmptyTitle), findsOneWidget);
      expect(find.text(AppStrings.homeSectionCount(0)), findsOneWidget);
      expect(find.byType(PresentationCard), findsNothing);
      expect(
        tester.widget<BottomDock>(find.byType(BottomDock)).onFabTap,
        isNull,
        reason: '06에는 FAB가 없다',
      );
    });

    testWidgets('첫 발표 만들기 → 08', (tester) async {
      await pumpApp(
        tester,
        initial: AppPage.home.path,
        store: MemoryLocalStoreService(),
      );
      await tapText(tester, AppStrings.homeCreateFirst);
      expect(find.byType(PresentationFormPage), findsOneWidget);
      expect(find.text(AppStrings.formTitle), findsOneWidget);
    });

    testWidgets('샘플 리포트 둘러보기 → 22 (sampleMode=true)', (tester) async {
      final router = await pumpApp(
        tester,
        initial: AppPage.home.path,
        store: MemoryLocalStoreService(),
      );
      await tapText(tester, AppStrings.homeSample);
      expect(find.byType(ReportPage), findsOneWidget);
      final uri = router.state.uri;
      expect(uri.queryParameters[RouteParam.sampleMode], 'true');
      expect(
        uri.queryParameters[RouteParam.rehearsalId],
        DemoData.rehearsal3.id,
      );
    });
  });

  group('07 홈 목록 (데모 데이터 §8)', () {
    testWidgets('D-3 · 요약 문구 · 카드 3장 · 배지 · 날짜 미정', (tester) async {
      await pumpApp(tester, initial: AppPage.home.path);
      expect(find.text(AppStrings.homeNextLabel), findsOneWidget);
      expect(find.text('D-3'), findsNWidgets(2), reason: '헤더 + 첫 카드');
      expect(find.text('○○학회 구두발표 · 9월 12일 (토) · 리허설 3회'), findsOneWidget);
      expect(find.byType(PresentationCard), findsNWidgets(3));
      expect(find.text(AppStrings.homeSectionSort), findsOneWidget);
      expect(find.text('리허설 3회'), findsOneWidget);
      expect(find.text('원고 없음'), findsNWidgets(2));
      expect(find.text(AppStrings.commonDateTbd), findsOneWidget);
      expect(find.text('D-18'), findsOneWidget);
      expect(
        tester.widget<BottomDock>(find.byType(BottomDock)).onFabTap,
        isNotNull,
      );
    });

    testWidgets('카드 탭 → 발표 상세(presentationId) · FAB → 08 · 설정 탭 → 09', (
      tester,
    ) async {
      final router = await pumpApp(tester, initial: AppPage.home.path);
      await tester.tap(find.byType(PresentationCard).first);
      await tester.pumpAndSettle();
      expect(find.byType(PresentationDetailPage), findsOneWidget);
      expect(
        router.state.uri.queryParameters[RouteParam.presentationId],
        DemoData.presentationId,
      );
      router.pop();
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel(AppStrings.formTitle));
      await tester.pumpAndSettle();
      expect(find.byType(PresentationFormPage), findsOneWidget);
      router.pop();
      await tester.pumpAndSettle();
      await tester.tap(find.text(AppStrings.tabSettings));
      await tester.pumpAndSettle();
      expect(find.byType(SettingsPage), findsOneWidget);
    });
  });

  group('08 발표 생성', () {
    testWidgets('빈 제목으로 만들기 → 제목 오류, 채우면 저장 → 상세(원고 탭)', (tester) async {
      final store = MemoryLocalStoreService();
      final router = await pumpApp(
        tester,
        initial: AppPage.presentationForm.path,
        store: store,
      );
      await tapText(tester, AppStrings.formSubmit);
      expect(find.text(AppStrings.formTitleRequired), findsOneWidget);
      expect(find.byType(PresentationFormPage), findsOneWidget);

      await tester.enterText(find.byType(TextField), '새 발표');
      await tester.pump();
      expect(
        find.text(AppStrings.formTitleRequired),
        findsNothing,
        reason: '입력하면 오류 해제',
      );
      await tapText(tester, AppStrings.formSubmit);
      expect(find.byType(PresentationDetailPage), findsOneWidget);
      final params = router.state.uri.queryParameters;
      expect(params[RouteParam.tab], 'script');
      final saved =
          ((await store.loadPresentations()) as Success<List<Presentation>>)
              .value
              .single;
      expect(saved.title, '새 발표');
      expect(params[RouteParam.presentationId], saved.id);
      expect(saved.talkMinutes, 15);
      expect(saved.qaMinutes, 5);
    });

    testWidgets('스테퍼: 발표 1~60 · Q&A 0~60 경계에서 버튼 비활성, 21분부터 부분 리허설 고지', (
      tester,
    ) async {
      await pumpApp(
        tester,
        initial: AppPage.presentationForm.path,
        store: MemoryLocalStoreService(),
      );
      final qaMinus = find.byTooltip('${AppStrings.formQaLabel} 1분 줄이기');
      for (var i = 0; i < 5; i++) {
        await tester.tap(qaMinus);
        await tester.pump();
      }
      expect(find.text('0'), findsOneWidget);
      expect(
        tester
            .widget<IconButton>(
              find.ancestor(of: qaMinus, matching: find.byType(IconButton)),
            )
            .onPressed,
        isNull,
        reason: 'Q&A 0에서 더 못 줄임',
      );

      final talkPlus = find.byTooltip('${AppStrings.formTalkLabel} 1분 늘리기');
      expect(find.textContaining('발표 규격은'), findsNothing);
      for (var i = 15; i < 21; i++) {
        await tester.tap(talkPlus);
        await tester.pump();
      }
      expect(find.text('21'), findsOneWidget);
      expect(find.text(AppStrings.formPartialNotice(21)), findsOneWidget);
      for (var i = 21; i < 60; i++) {
        await tester.tap(talkPlus);
        await tester.pump();
      }
      expect(find.text('60'), findsOneWidget);
      expect(
        tester
            .widget<IconButton>(
              find.ancestor(of: talkPlus, matching: find.byType(IconButton)),
            )
            .onPressed,
        isNull,
        reason: '60 상한',
      );
      expect(find.byType(StepperField), findsNWidgets(2));
    });

    testWidgets('유형 · 청중 칩 선택 · 날짜 선택 · 지우기 → 저장값 반영', (tester) async {
      final store = MemoryLocalStoreService();
      await pumpApp(
        tester,
        initial: AppPage.presentationForm.path,
        store: store,
      );
      await tester.enterText(find.byType(TextField), '디펜스');
      await tapText(tester, '논문 심사(디펜스)');
      await tapText(tester, '비전공 일반');
      expect(find.text(AppStrings.formDatePlaceholder), findsOneWidget);

      await tapText(tester, AppStrings.formDatePlaceholder);
      expect(find.byType(DatePickerDialog), findsOneWidget);
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      expect(find.text(AppStrings.formDatePlaceholder), findsNothing);
      expect(find.byTooltip(AppStrings.formDateClear), findsOneWidget);
      await tester.ensureVisible(find.byTooltip(AppStrings.formDateClear));
      await tester.tap(find.byTooltip(AppStrings.formDateClear));
      await tester.pumpAndSettle();
      expect(find.text(AppStrings.formDatePlaceholder), findsOneWidget);

      await tapText(tester, AppStrings.formSubmit);
      final saved =
          ((await store.loadPresentations()) as Success<List<Presentation>>)
              .value
              .single;
      expect(saved.type.title, '논문 심사(디펜스)');
      expect(saved.audience.title, '비전공 일반');
      expect(saved.date, isNull, reason: '지우면 날짜 미정');
    });

    testWidgets('저장 실패 → 문구 · 버튼 복구 · 화면 유지', (tester) async {
      await pumpApp(
        tester,
        initial: AppPage.presentationForm.path,
        store: _FailingStore(),
      );
      await tester.enterText(find.byType(TextField), '실패');
      await tapText(tester, AppStrings.formSubmit);
      expect(find.text(AppStrings.formSaveFailed), findsOneWidget);
      expect(find.byType(PresentationFormPage), findsOneWidget);
      expect(
        tester.widget<PrimaryButton>(find.byType(PrimaryButton)).onPressed,
        isNotNull,
      );
    });

    testWidgets('편집: 기존 값 채움 · 제목 "발표 편집" · 저장 시 id 유지', (tester) async {
      await pumpApp(
        tester,
        initial: AppPage.presentationForm.location({
          RouteParam.presentationId: DemoData.presentationId,
        }),
      );
      expect(find.text(AppStrings.formEditTitle), findsOneWidget);
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        '○○학회 구두발표',
      );
      expect(find.text('2026년 9월 12일 (토)'), findsOneWidget);
      expect(find.text(AppStrings.commonSave), findsOneWidget);
    });

    testWidgets('뒤로가기 (스택 없음) → 홈', (tester) async {
      await pumpApp(tester, initial: AppPage.presentationForm.path);
      await tester.tap(find.byTooltip(AppStrings.commonBack));
      await tester.pumpAndSettle();
      expect(find.byType(HomePage), findsOneWidget);
    });
  });

  group('반응형 · 접근성', () {
    for (final (name, initial, store) in [
      ('home_empty', AppPage.home.path, MemoryLocalStoreService()),
      ('home_list', AppPage.home.path, null),
      ('form', AppPage.presentationForm.path, null),
    ]) {
      for (final w in widths) {
        for (final s in scales) {
          testWidgets('$name @ ${w.toInt()}×640 ×$s 넘침 없음', (tester) async {
            tester.view.physicalSize = Size(w, 640);
            tester.view.devicePixelRatio = 1.0;
            addTearDown(tester.view.reset);
            await pumpApp(
              tester,
              initial: initial,
              store: store,
              size: Size(w, 640),
              scale: s,
            );
            expect(tester.takeException(), isNull);
            expect(
              find.byType(BottomDock).evaluate().isNotEmpty ||
                  find.byType(PrimaryButton).evaluate().isNotEmpty,
              isTrue,
            );
          });
        }
      }

      for (final size in const [Size(1024, 844), Size(844, 390)]) {
        testWidgets(
          '$name @ ${size.width.toInt()}×${size.height.toInt()} 본문 480 상한',
          (tester) async {
            tester.view.physicalSize = size;
            tester.view.devicePixelRatio = 1.0;
            addTearDown(tester.view.reset);
            await pumpApp(tester, initial: initial, store: store, size: size);
            expect(tester.takeException(), isNull);
            final probe = name == 'home_list'
                ? find.byType(PresentationCard).first
                : find.byType(PrimaryButton).first;
            final rect = tester.getRect(probe);
            expect(rect.width, lessThanOrEqualTo(AppSpacing.contentMaxWidth));
          },
        );
      }
    }

    testWidgets('스테퍼 버튼 · 칩 · 카드 히트 영역 ≥ 48', (tester) async {
      await pumpApp(tester, initial: AppPage.presentationForm.path);
      for (final tooltip in [
        '${AppStrings.formTalkLabel} 1분 늘리기',
        '${AppStrings.formQaLabel} 1분 줄이기',
      ]) {
        final size = tester.getSize(find.byTooltip(tooltip));
        expect(size.width, greaterThanOrEqualTo(48), reason: tooltip);
        expect(size.height, greaterThanOrEqualTo(48), reason: tooltip);
      }
      expect(tester.getSize(find.text('랩 세미나').first).height, lessThan(48));
      expect(
        tester
            .getSize(
              find
                  .ancestor(
                    of: find.text('랩 세미나'),
                    matching: find.byType(Material),
                  )
                  .first,
            )
            .height,
        greaterThanOrEqualTo(48),
      );
    });
  });
}
