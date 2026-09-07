import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rehearsallab/app/app_strings.dart';
import 'package:rehearsallab/app/router/app_page.dart';
import 'package:rehearsallab/app/router/app_router.dart';
import 'package:rehearsallab/app/theme/app_spacing.dart';
import 'package:rehearsallab/app/theme/app_theme.dart';
import 'package:rehearsallab/core/enum/retention_option.dart';
import 'package:rehearsallab/core/models/result.dart';
import 'package:rehearsallab/features/auth/auth_provider.dart';
import 'package:rehearsallab/features/consent/consent_provider.dart';
import 'package:rehearsallab/features/presentation/presentation_provider.dart';
import 'package:rehearsallab/features/settings/settings_provider.dart';
import 'package:rehearsallab/models/provider_config.dart';
import 'package:rehearsallab/services/auth_service.dart';
import 'package:rehearsallab/services/local_store_service.dart';
import 'package:rehearsallab/services/mock/demo_data.dart';
import 'package:rehearsallab/services/settings_service.dart';
import 'package:rehearsallab/ui/common/bottom_dock.dart';
import 'package:rehearsallab/ui/common/detail_header.dart';
import 'package:rehearsallab/ui/common/primary_button.dart';
import 'package:rehearsallab/ui/common/secondary_button.dart';
import 'package:rehearsallab/ui/pages/delete_confirm/delete_confirm_page.dart';
import 'package:rehearsallab/ui/pages/home/home_page.dart';
import 'package:rehearsallab/ui/pages/login/login_page.dart';
import 'package:rehearsallab/ui/pages/onboarding_privacy/onboarding_privacy_page.dart';
import 'package:rehearsallab/ui/pages/presentation_form/presentation_form_page.dart';
import 'package:rehearsallab/ui/pages/settings/settings_page.dart';

class _FailingDeleteStore extends MemoryLocalStoreService {
  _FailingDeleteStore({super.presentations});

  @override
  Future<Result<void>> deleteAll() async => Failure(Exception('disk error'));
}

void main() {
  const widths = [320.0, 390.0, 430.0];
  const scales = [1.0, 1.3];

  Future<GoRouter> pumpApp(
    WidgetTester tester, {
    required String initial,
    LocalStoreService? store,
    SettingsService? settings,
    MockAuthService? auth,
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
          if (settings != null)
            settingsServiceProvider.overrideWithValue(settings),
          if (auth != null) authServiceProvider.overrideWithValue(auth),
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

  Future<MockAuthService> signedInAuth() async {
    final auth = MockAuthService();
    await auth.signIn(MockAuthService.demoEmail, MockAuthService.demoPassword);
    return auth;
  }

  Future<void> tapText(WidgetTester tester, String text) async {
    await tester.ensureVisible(find.text(text));
    await tester.tap(find.text(text));
    await tester.pumpAndSettle();
  }

  group('09 설정', () {
    testWidgets('이메일 · 보관 기간 7일 · 제공사 미지정 · 외부 상태 · 버전 표시', (tester) async {
      await pumpApp(
        tester,
        initial: AppPage.settings.path,
        auth: await signedInAuth(),
      );
      expect(find.text(MockAuthService.demoEmail), findsOneWidget);
      expect(
        find.text(AppStrings.settingsRetentionValue('7일')),
        findsOneWidget,
      );
      expect(
        find.text(
          AppStrings.settingsProvidersValue(
            ProviderConfig.empty.llmName,
            ProviderConfig.empty.sttName,
          ),
        ),
        findsOneWidget,
      );
      expect(
        find.text(AppStrings.settingsExternalValue('미확정', '미확정', '요청 전')),
        findsOneWidget,
      );
      expect(find.text(AppStrings.settingsVersionValue), findsOneWidget);
      expect(find.text(AppStrings.settingsRetentionNote), findsOneWidget);
      expect(
        tester.widget<BottomDock>(find.byType(BottomDock)).current,
        DockTab.settings,
      );
    });

    testWidgets('보관 기간 → 바텀시트에서 "처리 후 즉시 삭제" 선택 → 값 갱신 · 저장', (tester) async {
      final settings = MockSettingsService();
      await pumpApp(tester, initial: AppPage.settings.path, settings: settings);
      await tapText(tester, AppStrings.settingsRetention);
      expect(find.text(RetentionOption.immediate.title), findsOneWidget);
      await tapText(tester, RetentionOption.immediate.title);
      expect(
        find.text(AppStrings.settingsRetentionValue('처리 후 즉시 삭제')),
        findsOneWidget,
      );
      expect(
        ((await settings.loadRetention()) as Success<RetentionOption>).value,
        RetentionOption.immediate,
      );
    });

    testWidgets('로그아웃 → 04 · 세션 없음', (tester) async {
      final auth = await signedInAuth();
      await pumpApp(tester, initial: AppPage.settings.path, auth: auth);
      await tapText(tester, AppStrings.settingsLogout);
      expect(find.byType(LoginPage), findsOneWidget);
      expect(((await auth.currentUser()) as Success).value, isNull);
    });

    testWidgets('프라이버시 고지 다시 보기 → 03 · 모든 데이터 삭제 → 31', (tester) async {
      final router = await pumpApp(tester, initial: AppPage.settings.path);
      await tapText(tester, AppStrings.settingsPrivacyAgain);
      expect(find.byType(OnboardingPrivacyPage), findsOneWidget);
      router.pop();
      await tester.pumpAndSettle();
      await tapText(tester, AppStrings.settingsDeleteAll);
      expect(find.byType(DeleteConfirmPage), findsOneWidget);
      expect(find.text(AppStrings.deleteStep(1)), findsOneWidget);
    });

    testWidgets('홈 탭 → 06/07', (tester) async {
      await pumpApp(tester, initial: AppPage.settings.path);
      await tester.tap(find.text(AppStrings.tabHome));
      await tester.pumpAndSettle();
      expect(find.byType(HomePage), findsOneWidget);
    });
  });

  group('31 · 32 모든 데이터 삭제', () {
    testWidgets('집계 표시 · 다음 확인 → 2단계 · "삭제" 입력 전 비활성 · 입력 후 삭제 → 빈 홈', (
      tester,
    ) async {
      final store = MemoryLocalStoreService(
        presentations: DemoData.presentations,
        versions: [DemoData.scriptV1, DemoData.scriptV2],
        rehearsals: [DemoData.rehearsal1, DemoData.rehearsal2],
        reports: [DemoData.report1],
      );
      await pumpApp(
        tester,
        initial: AppPage.deleteConfirm.location({RouteParam.step: '1'}),
        store: store,
      );
      expect(
        find.text(AppStrings.deleteScopePresentations(3, 2)),
        findsOneWidget,
      );
      expect(find.text(AppStrings.deleteScopeRehearsals(2, 2)), findsOneWidget);
      await tapText(tester, AppStrings.delete1Next);
      expect(find.text(AppStrings.deleteStep(2)), findsOneWidget);

      SecondaryButton confirm() =>
          tester.widget<SecondaryButton>(find.byType(SecondaryButton));
      expect(confirm().onPressed, isNull, reason: '입력 전 비활성');
      await tester.enterText(find.byType(TextField), '삭');
      await tester.pump();
      expect(confirm().onPressed, isNull);
      await tester.enterText(find.byType(TextField), '삭제');
      await tester.pump();
      expect(confirm().onPressed, isNotNull);
      await tapText(tester, AppStrings.delete2Confirm);
      expect(find.byType(HomePage), findsOneWidget);
      expect(find.text(AppStrings.homeEmptyTitle), findsOneWidget);
      expect(find.text(AppStrings.deleteDone), findsOneWidget);
      expect(((await store.loadPresentations()) as Success).value, isEmpty);
    });

    testWidgets('삭제 실패 → 문구 · 화면 유지 · 데이터 유지', (tester) async {
      await pumpApp(
        tester,
        initial: AppPage.deleteConfirm.location({RouteParam.step: '2'}),
        store: _FailingDeleteStore(presentations: DemoData.presentations),
      );
      await tester.enterText(find.byType(TextField), '삭제');
      await tester.pump();
      await tapText(tester, AppStrings.delete2Confirm);
      expect(find.text(AppStrings.deleteFailed), findsOneWidget);
      expect(find.byType(DeleteConfirmPage), findsOneWidget);
      expect(
        tester.widget<SecondaryButton>(find.byType(SecondaryButton)).onPressed,
        isNotNull,
        reason: '재시도 가능',
      );
    });

    testWidgets('취소하고 돌아가기 → 09', (tester) async {
      await pumpApp(
        tester,
        initial: AppPage.deleteConfirm.location({RouteParam.step: '1'}),
      );
      await tapText(tester, AppStrings.deleteCancel);
      expect(find.byType(SettingsPage), findsOneWidget);
    });
  });

  group('발표 상세 탭 컨테이너 · 23 · 24 준비 중', () {
    testWidgets('헤더(제목 · 배지 · D-3 · 규격) · 기본 원고 탭 · 탭 전환 · 준비 중 화면', (
      tester,
    ) async {
      await pumpApp(
        tester,
        initial: AppPage.presentationDetail.location({
          RouteParam.presentationId: DemoData.presentationId,
        }),
      );
      expect(find.text('○○학회 구두발표'), findsOneWidget);
      expect(find.text('리허설 3회'), findsOneWidget);
      expect(find.text('D-3'), findsOneWidget);
      expect(find.text('15분 + Q&A 5분'), findsOneWidget);
      expect(
        find.text(AppStrings.placeholderBody(AppStrings.detailScriptPending)),
        findsOneWidget,
      );

      await tapText(tester, AppStrings.detailTabQa);
      expect(find.text(AppStrings.qaTitle), findsOneWidget);
      expect(find.text(AppStrings.commonPrepared), findsOneWidget);
      expect(find.text(AppStrings.qaPlanned1), findsOneWidget);
      await tapText(tester, AppStrings.qaBack);
      expect(
        find.text(
          AppStrings.placeholderBody(AppStrings.detailRehearsalPending),
        ),
        findsOneWidget,
        reason: 'Q&A 하단 버튼 → 리허설 탭',
      );

      await tapText(tester, AppStrings.detailTabHistory);
      expect(find.text(AppStrings.historyTitle), findsOneWidget);
      expect(find.text(AppStrings.historyPlanned3), findsOneWidget);
      await tapText(tester, AppStrings.historyBack);
      expect(
        find.text(
          AppStrings.placeholderBody(AppStrings.detailRehearsalPending),
        ),
        findsOneWidget,
      );
    });

    testWidgets('딥링크 ?tab=history · 마지막에 보던 탭 복원', (tester) async {
      final settings = MockSettingsService();
      await pumpApp(
        tester,
        initial: AppPage.presentationDetail.location({
          RouteParam.presentationId: DemoData.presentationId,
          RouteParam.tab: 'history',
        }),
        settings: settings,
      );
      expect(find.text(AppStrings.historyTitle), findsOneWidget);
      await tapText(tester, AppStrings.detailTabQa);
      expect(
        ((await settings.loadLastTab(DemoData.presentationId))
                as Success<String?>)
            .value,
        'qa',
      );

      // 다시 열면(딥링크 없음) 마지막 탭 Q&A
      await pumpApp(
        tester,
        initial: AppPage.presentationDetail.location({
          RouteParam.presentationId: DemoData.presentationId,
        }),
        settings: settings,
      );
      expect(find.text(AppStrings.qaTitle), findsOneWidget);
    });

    testWidgets('⋯ 메뉴: 편집 → 08 편집 · 발표 삭제 → 확인 → 홈에서 사라짐', (tester) async {
      final store = MemoryLocalStoreService(
        presentations: DemoData.presentations,
      );
      final router = await pumpApp(
        tester,
        initial: AppPage.presentationDetail.location({
          RouteParam.presentationId: DemoData.presentationId,
        }),
        store: store,
      );
      await tester.tap(find.byTooltip(AppStrings.detailMenu));
      await tester.pumpAndSettle();
      await tapText(tester, AppStrings.commonEdit);
      expect(find.byType(PresentationFormPage), findsOneWidget);
      expect(find.text(AppStrings.formEditTitle), findsOneWidget);
      router.pop();
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip(AppStrings.detailMenu));
      await tester.pumpAndSettle();
      await tapText(tester, AppStrings.detailDeleteMenu);
      expect(find.text(AppStrings.detailDeleteConfirm), findsOneWidget);
      await tapText(tester, AppStrings.detailDeleteConfirm);
      expect(find.byType(HomePage), findsOneWidget);
      expect(find.text('○○학회 구두발표'), findsNothing);
      expect(
        ((await store.loadPresentations()) as Success).value,
        hasLength(2),
      );
    });

    testWidgets('없는 발표 id → 안내 + 홈 버튼', (tester) async {
      await pumpApp(
        tester,
        initial: AppPage.presentationDetail.location({
          RouteParam.presentationId: 'nope',
        }),
      );
      expect(find.text(AppStrings.detailMissing), findsOneWidget);
      await tapText(tester, AppStrings.tabHome);
      expect(find.byType(HomePage), findsOneWidget);
    });
  });

  group('반응형 · 접근성', () {
    final pages = <(String, String)>[
      ('settings', AppPage.settings.path),
      ('delete1', AppPage.deleteConfirm.location({RouteParam.step: '1'})),
      ('delete2', AppPage.deleteConfirm.location({RouteParam.step: '2'})),
      (
        'detail_qa',
        AppPage.presentationDetail.location({
          RouteParam.presentationId: DemoData.presentationId,
          RouteParam.tab: 'qa',
        }),
      ),
    ];
    for (final (name, initial) in pages) {
      for (final w in widths) {
        for (final s in scales) {
          testWidgets('$name @ ${w.toInt()}×640 ×$s 넘침 없음', (tester) async {
            tester.view.physicalSize = Size(w, 640);
            tester.view.devicePixelRatio = 1.0;
            addTearDown(tester.view.reset);
            await pumpApp(
              tester,
              initial: initial,
              size: Size(w, 640),
              scale: s,
            );
            expect(tester.takeException(), isNull);
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
            await pumpApp(tester, initial: initial, size: size);
            expect(tester.takeException(), isNull);
            final probe = name == 'settings'
                ? find.text(AppStrings.settingsRetentionNote)
                : find.byType(PrimaryButton).first;
            expect(
              tester.getRect(probe).width,
              lessThanOrEqualTo(AppSpacing.contentMaxWidth),
            );
          },
        );
      }
    }

    testWidgets('설정 행 · 탭 항목 히트 영역 ≥ 48', (tester) async {
      await pumpApp(tester, initial: AppPage.settings.path);
      expect(
        tester
            .getSize(
              find.ancestor(
                of: find.text(AppStrings.settingsLogout),
                matching: find.byType(InkWell),
              ),
            )
            .height,
        greaterThanOrEqualTo(48),
      );
      await pumpApp(
        tester,
        initial: AppPage.presentationDetail.location({
          RouteParam.presentationId: DemoData.presentationId,
        }),
      );
      expect(find.byType(DetailHeader), findsOneWidget);
      expect(
        tester
            .getSize(
              find.ancestor(
                of: find.text(AppStrings.detailTabQa),
                matching: find.byType(InkWell),
              ),
            )
            .height,
        greaterThanOrEqualTo(48),
      );
    });
  });
}
