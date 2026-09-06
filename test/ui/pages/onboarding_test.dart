import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rehearsallab/app/app_strings.dart';
import 'package:rehearsallab/app/router/app_page.dart';
import 'package:rehearsallab/app/router/app_router.dart';
import 'package:rehearsallab/app/theme/app_theme.dart';
import 'package:rehearsallab/core/models/result.dart';
import 'package:rehearsallab/features/consent/consent_provider.dart';
import 'package:rehearsallab/models/consent_record.dart';
import 'package:rehearsallab/models/provider_config.dart';
import 'package:rehearsallab/services/consent_service.dart';
import 'package:rehearsallab/ui/common/primary_button.dart';
import 'package:rehearsallab/ui/pages/login/login_page.dart';
import 'package:rehearsallab/ui/pages/onboarding_intro/onboarding_intro_page.dart';
import 'package:rehearsallab/ui/pages/onboarding_privacy/onboarding_privacy_page.dart';
import 'package:rehearsallab/ui/pages/splash/splash_page.dart';

void main() {
  const widths = [320.0, 390.0, 430.0];
  const scales = [1.0, 1.3];

  Future<GoRouter> pumpApp(
    WidgetTester tester, {
    required String initial,
    ConsentService? service,
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
          if (service != null)
            consentServiceProvider.overrideWithValue(service),
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

  group('00 스플래시 분기', () {
    testWidgets('배경 그라데이션이 화면 전체 폭을 채운다', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            providerConfigProvider.overrideWith(
              (ref) async => ProviderConfig.empty,
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            home: const SplashPage(delay: Duration(days: 1)),
          ),
        ),
      );
      await tester.pump();
      expect(
        tester.getSize(find.byType(DecoratedBox).first).width,
        tester.getSize(find.byType(Scaffold)).width,
        reason: 'Column이 stretch가 아니면 배경이 텍스트 폭으로 줄어든다',
      );
    });

    testWidgets('동의 없음 → 01 소개', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            providerConfigProvider.overrideWith(
              (ref) async => ProviderConfig.empty,
            ),
          ],
          child: MaterialApp.router(
            theme: AppTheme.light,
            routerConfig: GoRouter(
              initialLocation: '/',
              routes: [
                GoRoute(
                  path: '/',
                  builder: (_, _) => const SplashPage(delay: Duration.zero),
                ),
                GoRoute(
                  path: AppPage.onboardingIntro.path,
                  builder: (_, _) => const OnboardingIntroPage(),
                ),
                GoRoute(
                  path: AppPage.login.path,
                  builder: (_, _) => const LoginPage(),
                ),
              ],
            ),
          ),
        ),
      );
      expect(find.text(AppStrings.appName), findsOneWidget);
      await tester.pumpAndSettle();
      expect(find.byType(OnboardingIntroPage), findsOneWidget);
    });

    testWidgets('현재 버전 동의 있음 → 04 로그인', (tester) async {
      final service = MockConsentService();
      final version = service.computeConsentVersion(ProviderConfig.empty);
      await service.saveConsent(
        ConsentRecord(
          userId: ConsentService.unboundUserId,
          consentVersion: version,
          acceptedAt: DateTime(2026),
        ),
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            providerConfigProvider.overrideWith(
              (ref) async => ProviderConfig.empty,
            ),
            consentServiceProvider.overrideWithValue(service),
          ],
          child: MaterialApp.router(
            theme: AppTheme.light,
            routerConfig: GoRouter(
              initialLocation: '/',
              routes: [
                GoRoute(
                  path: '/',
                  builder: (_, _) => const SplashPage(delay: Duration.zero),
                ),
                GoRoute(
                  path: AppPage.onboardingIntro.path,
                  builder: (_, _) => const OnboardingIntroPage(),
                ),
                GoRoute(
                  path: AppPage.login.path,
                  builder: (_, _) => const LoginPage(),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(LoginPage), findsOneWidget);
    });
  });

  group('01 · 02 소개 → 03 동의 (4장 전환)', () {
    testWidgets('다음 → 2쪽, 다음 → 03 동의', (tester) async {
      await pumpApp(tester, initial: AppPage.onboardingIntro.path);
      expect(find.text(AppStrings.intro1Headline), findsOneWidget);
      await tester.tap(find.text(AppStrings.commonNext));
      await tester.pumpAndSettle();
      expect(find.text(AppStrings.intro2Headline), findsOneWidget);
      expect(find.text('142'), findsOneWidget);
      await tester.tap(find.text(AppStrings.commonNext));
      await tester.pumpAndSettle();
      expect(find.byType(OnboardingPrivacyPage), findsOneWidget);
    });

    testWidgets('건너뛰기 → 03 동의 (동의는 건너뛸 수 없음)', (tester) async {
      await pumpApp(tester, initial: AppPage.onboardingIntro.path);
      await tester.tap(find.text(AppStrings.commonSkip));
      await tester.pumpAndSettle();
      expect(find.byType(OnboardingPrivacyPage), findsOneWidget);
      expect(find.text(AppStrings.commonSkip), findsNothing);
    });
  });

  group('03 동의 게이트', () {
    testWidgets('체크 전 버튼 비활성, 체크 후 활성 → 저장 후 04 로그인', (tester) async {
      final service = MockConsentService();
      await pumpApp(
        tester,
        initial: AppPage.onboardingPrivacy.path,
        service: service,
      );
      final button = tester.widget<PrimaryButton>(find.byType(PrimaryButton));
      expect(button.onPressed, isNull);
      expect(
        find.textContaining('제공사 미지정'),
        findsWidgets,
        reason: 'providers.json 비어 있음 → 미지정 표시',
      );
      await tester.ensureVisible(find.textContaining('이해했고 동의합니다'));
      await tester.tap(find.textContaining('이해했고 동의합니다'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<PrimaryButton>(find.byType(PrimaryButton)).onPressed,
        isNotNull,
      );
      await tester.tap(find.text(AppStrings.privacyAgreeButton));
      await tester.pumpAndSettle();
      expect(find.byType(LoginPage), findsOneWidget);
      final saved =
          ((await service.loadConsents()) as Success<List<ConsentRecord>>)
              .value;
      expect(saved.single.userId, ConsentService.unboundUserId);
      expect(saved.single.consentVersion, startsWith('mock-'));
    });
  });

  group('반응형 (7장): 320/390/430 × 1.0/1.3 · 높이 640', () {
    for (final page in [AppPage.onboardingIntro, AppPage.onboardingPrivacy]) {
      for (final w in widths) {
        for (final s in scales) {
          testWidgets('${page.name} @ ${w.toInt()}×640 ×$s 넘침 없음', (
            tester,
          ) async {
            tester.view.physicalSize = Size(w, 640);
            tester.view.devicePixelRatio = 1.0;
            addTearDown(tester.view.reset);
            await pumpApp(
              tester,
              initial: page.path,
              size: Size(w, 640),
              scale: s,
            );
            expect(tester.takeException(), isNull);
            expect(
              find.byType(PrimaryButton),
              findsOneWidget,
              reason: '하단 CTA는 항상 보인다',
            );
          });
        }
      }
    }
  });
}
