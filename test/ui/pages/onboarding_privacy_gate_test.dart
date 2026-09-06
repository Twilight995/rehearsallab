import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rehearsallab/app/app_strings.dart';
import 'package:rehearsallab/app/router/app_page.dart';
import 'package:rehearsallab/app/theme/app_spacing.dart';
import 'package:rehearsallab/app/theme/app_theme.dart';
import 'package:rehearsallab/core/models/result.dart';
import 'package:rehearsallab/features/consent/consent_provider.dart';
import 'package:rehearsallab/models/consent_record.dart';
import 'package:rehearsallab/models/provider_config.dart';
import 'package:rehearsallab/services/consent_service.dart';
import 'package:rehearsallab/ui/common/primary_button.dart';
import 'package:rehearsallab/ui/pages/onboarding_intro/onboarding_intro_page.dart';
import 'package:rehearsallab/ui/pages/onboarding_privacy/onboarding_privacy_page.dart';
import 'package:rehearsallab/ui/pages/splash/splash_page.dart';

/// 03 동의 게이트 보강 (C1-REV-02) · 스플래시 복구 (C1-REV-03) · 태블릿 상한 (C1-REV-05)
void main() {
  const consentText = '이해했고 동의합니다';

  Future<void> pumpPrivacy(
    WidgetTester tester, {
    required FutureOr<ProviderConfig> Function(Ref ref) config,
    ConsentService? consent,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          providerConfigProvider.overrideWith(config),
          if (consent != null)
            consentServiceProvider.overrideWithValue(consent),
        ],
        child: MaterialApp.router(
          theme: AppTheme.light,
          routerConfig: GoRouter(
            initialLocation: AppPage.onboardingPrivacy.path,
            routes: [
              GoRoute(
                path: AppPage.onboardingPrivacy.path,
                builder: (_, _) => const OnboardingPrivacyPage(),
              ),
              GoRoute(
                path: AppPage.login.path,
                builder: (_, _) => const Scaffold(body: Text('login')),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pump();
  }

  PrimaryButton cta(WidgetTester tester) =>
      tester.widget<PrimaryButton>(find.byType(PrimaryButton));

  Future<void> tapConsent(WidgetTester tester) async {
    await tester.ensureVisible(find.textContaining(consentText));
    await tester.tap(find.textContaining(consentText));
    await tester.pump();
  }

  group('03 고지 로딩 게이트 (C1-REV-02)', () {
    testWidgets('고지 로딩 중에는 체크해도 CTA 비활성 · "불러오는 중" 표시', (tester) async {
      final pending = Completer<ProviderConfig>();
      await pumpPrivacy(tester, config: (_) => pending.future);
      expect(find.text(AppStrings.privacyLoading), findsOneWidget);
      expect(
        find.text(
          AppStrings.privacyConsentText(AppStrings.privacyVersionPending),
        ),
        findsOneWidget,
      );
      await tapConsent(tester);
      expect(cta(tester).onPressed, isNull, reason: '제공사 · 버전 미확정');
      expect(find.textContaining('제공사 미지정'), findsNothing);
    });

    testWidgets('로딩 완료 후 체크 → 활성 → 저장 버전 = 표시 버전', (tester) async {
      final consent = MockConsentService();
      final pending = Completer<ProviderConfig>();
      await pumpPrivacy(
        tester,
        config: (_) => pending.future,
        consent: consent,
      );
      await tapConsent(tester);
      pending.complete(ProviderConfig.empty);
      await tester.pumpAndSettle();
      expect(cta(tester).onPressed, isNull, reason: '로딩 중 체크는 무시됨');
      await tapConsent(tester);
      expect(cta(tester).onPressed, isNotNull);
      final shown = consent.computeConsentVersion(ProviderConfig.empty);
      expect(find.textContaining(shown), findsOneWidget);
      await tester.tap(find.text(AppStrings.privacyAgreeButton));
      await tester.pumpAndSettle();
      final saved =
          ((await consent.loadConsents()) as Success<List<ConsentRecord>>)
              .value;
      expect(saved.single.consentVersion, shown);
      expect(find.text('login'), findsOneWidget);
    });

    testWidgets('로딩 실패 → 실패 카드 + 재시도, 체크 불가 · 재시도 성공 후 활성', (tester) async {
      var attempts = 0;
      await pumpPrivacy(
        tester,
        config: (_) async {
          attempts++;
          if (attempts == 1) throw Exception('asset missing');
          return ProviderConfig.empty;
        },
      );
      await tester.pumpAndSettle();
      expect(find.text(AppStrings.privacyLoadFailed), findsOneWidget);
      expect(find.text(AppStrings.privacyLoading), findsNothing);
      await tapConsent(tester);
      expect(cta(tester).onPressed, isNull);

      await tester.tap(find.text(AppStrings.commonRetry));
      await tester.pumpAndSettle();
      expect(find.text(AppStrings.privacyLoadFailed), findsNothing);
      expect(find.textContaining('제공사 미지정'), findsWidgets);
      await tapConsent(tester);
      expect(cta(tester).onPressed, isNotNull);
    });

    testWidgets('설정이 바뀌어 버전이 달라지면 체크가 풀린다', (tester) async {
      var config = ProviderConfig.empty;
      await pumpPrivacy(tester, config: (_) async => config);
      await tester.pumpAndSettle();
      await tapConsent(tester);
      expect(cta(tester).onPressed, isNotNull);

      config = const ProviderConfig(
        stt: ProviderEntry(
          id: 'stt-a',
          name: 'STT A',
          region: 'KR',
          policyUrl: 'https://a',
          policyVersion: '1',
        ),
        llm: ProviderEntry(
          id: 'llm-b',
          name: 'LLM B',
          region: 'US',
          policyUrl: 'https://b',
          policyVersion: '1',
        ),
      );
      final element = tester.element(find.byType(OnboardingPrivacyPage));
      ProviderScope.containerOf(element).invalidate(providerConfigProvider);
      await tester.pumpAndSettle();
      expect(find.textContaining('STT A'), findsOneWidget);
      expect(cta(tester).onPressed, isNull, reason: '새 버전에 다시 동의해야 함');
    });
  });

  group('00 스플래시 로드 실패 복구 (C1-REV-03)', () {
    testWidgets('설정 로드 실패 → 오류 + 재시도, 재시도 성공 → 01 소개', (tester) async {
      var attempts = 0;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            providerConfigProvider.overrideWith((_) async {
              attempts++;
              if (attempts == 1) throw Exception('asset missing');
              return ProviderConfig.empty;
            }),
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
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text(AppStrings.splashLoadFailed), findsOneWidget);
      expect(find.byType(SplashPage), findsOneWidget);
      await tester.tap(find.text(AppStrings.commonRetry));
      await tester.pumpAndSettle();
      expect(find.byType(OnboardingIntroPage), findsOneWidget);
    });
  });

  group('태블릿 · 가로 (C1-REV-05)', () {
    for (final size in const [Size(1024, 844), Size(844, 390)]) {
      testWidgets(
        '03 @ ${size.width.toInt()}×${size.height.toInt()} 본문 480 상한 · 중앙',
        (tester) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);
          await pumpPrivacy(tester, config: (_) async => ProviderConfig.empty);
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          final row = tester.getRect(find.textContaining(consentText));
          expect(row.width, lessThanOrEqualTo(AppSpacing.contentMaxWidth));
          final button = tester.getRect(find.byType(PrimaryButton));
          expect(button.width, lessThanOrEqualTo(AppSpacing.contentMaxWidth));
          expect((button.center.dx - size.width / 2).abs(), lessThan(1));
        },
      );
    }
  });
}
