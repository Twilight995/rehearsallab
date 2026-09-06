import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rehearsallab/app/app_strings.dart';
import 'package:rehearsallab/app/router/app_page.dart';
import 'package:rehearsallab/app/router/app_router.dart';
import 'package:rehearsallab/app/theme/app_spacing.dart';
import 'package:rehearsallab/app/theme/app_theme.dart';
import 'package:rehearsallab/core/enum/auth_error_code.dart';
import 'package:rehearsallab/core/models/result.dart';
import 'package:rehearsallab/features/auth/auth_provider.dart';
import 'package:rehearsallab/features/consent/consent_provider.dart';
import 'package:rehearsallab/models/consent_record.dart';
import 'package:rehearsallab/models/provider_config.dart';
import 'package:rehearsallab/models/user_account.dart';
import 'package:rehearsallab/services/auth_service.dart';
import 'package:rehearsallab/services/consent_service.dart';
import 'package:rehearsallab/ui/common/app_top_bar.dart';
import 'package:rehearsallab/ui/common/primary_button.dart';
import 'package:rehearsallab/ui/pages/home/home_page.dart';
import 'package:rehearsallab/ui/pages/login/login_page.dart';
import 'package:rehearsallab/ui/pages/onboarding_privacy/onboarding_privacy_page.dart';
import 'package:rehearsallab/ui/pages/signup/signup_page.dart';
import 'package:rehearsallab/ui/pages/splash/splash_page.dart';

/// 저장소가 예외를 던지는 상황 (Result 경계 밖으로 새는지 확인)
class _ThrowingAuthService extends AuthService {
  @override
  Future<Result<UserAccount?>> currentUser() async => const Success(null);

  @override
  Future<Result<UserAccount>> signIn(String email, String password) =>
      throw StateError('storage exploded');

  @override
  Future<Result<UserAccount>> signUp(String email, String password) =>
      throw StateError('storage exploded');

  @override
  Future<Result<void>> signOut() async => const Success(null);
}

void main() {
  const widths = [320.0, 390.0, 430.0];
  const scales = [1.0, 1.3];

  Future<GoRouter> pumpApp(
    WidgetTester tester, {
    required String initial,
    AuthService? auth,
    ConsentService? consent,
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
          if (auth != null) authServiceProvider.overrideWithValue(auth),
          if (consent != null)
            consentServiceProvider.overrideWithValue(consent),
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

  /// 로그인 전 03에서 저장된 미귀속 동의 (현재 버전)
  MockConsentService localConsent() {
    final service = MockConsentService();
    service.saveConsent(
      ConsentRecord(
        userId: ConsentService.unboundUserId,
        consentVersion: service.computeConsentVersion(ProviderConfig.empty),
        acceptedAt: DateTime(2026),
      ),
    );
    return service;
  }

  Future<void> enter(WidgetTester tester, String label, String text) async {
    final field = find.ancestor(
      of: find.text(label),
      matching: find.byType(Column),
    );
    await tester.enterText(
      find.descendant(of: field.first, matching: find.byType(TextField)),
      text,
    );
  }

  Future<void> submit(WidgetTester tester, String label) async {
    await tester.ensureVisible(find.text(label));
    await tester.tap(find.text(label));
    await tester.pumpAndSettle();
  }

  Future<void> demoLogin(WidgetTester tester) async {
    await enter(tester, AppStrings.authEmailLabel, MockAuthService.demoEmail);
    await enter(
      tester,
      AppStrings.authPasswordLabel,
      MockAuthService.demoPassword,
    );
    await submit(tester, AppStrings.loginButton);
  }

  group('04 로그인', () {
    testWidgets('빈 입력으로 로그인 → 이메일 형식 오류 문구 (색+텍스트)', (tester) async {
      await pumpApp(tester, initial: AppPage.login.path);
      expect(find.text(AppStrings.loginTitle), findsOneWidget);
      await submit(tester, AppStrings.loginButton);
      expect(
        find.text(AppStrings.authError(AuthErrorCode.invalidEmail)),
        findsOneWidget,
      );
      expect(find.byType(LoginPage), findsOneWidget);
    });

    testWidgets('짧은 비밀번호 → 길이 오류', (tester) async {
      await pumpApp(tester, initial: AppPage.login.path);
      await enter(tester, AppStrings.authEmailLabel, 'k@univ.ac.kr');
      await enter(tester, AppStrings.authPasswordLabel, '1234');
      await submit(tester, AppStrings.loginButton);
      expect(
        find.text(AppStrings.authError(AuthErrorCode.passwordTooShort)),
        findsOneWidget,
      );
    });

    testWidgets('틀린 비밀번호 → 자격 오류 · 화면 유지', (tester) async {
      await pumpApp(tester, initial: AppPage.login.path);
      await enter(tester, AppStrings.authEmailLabel, MockAuthService.demoEmail);
      await enter(tester, AppStrings.authPasswordLabel, 'wrong-password');
      await submit(tester, AppStrings.loginButton);
      expect(
        find.text(AppStrings.authError(AuthErrorCode.invalidCredentials)),
        findsOneWidget,
      );
      expect(find.byType(LoginPage), findsOneWidget);
    });

    testWidgets('미귀속 동의 있음 + 데모 로그인 성공 → 홈 · 동의는 계정에 묶임', (tester) async {
      final consent = localConsent();
      await pumpApp(tester, initial: AppPage.login.path, consent: consent);
      await demoLogin(tester);
      expect(find.byType(HomePage), findsOneWidget);
      final records =
          ((await consent.loadConsents()) as Success<List<ConsentRecord>>)
              .value;
      expect(records.map((r) => r.userId), ['u-demo']);
    });

    testWidgets('이 계정의 동의가 없으면 로그인 성공 후 03 재동의 → 동의하면 홈', (tester) async {
      await pumpApp(tester, initial: AppPage.login.path);
      await demoLogin(tester);
      expect(find.byType(OnboardingPrivacyPage), findsOneWidget);
      await tester.ensureVisible(find.textContaining('이해했고 동의합니다'));
      await tester.tap(find.textContaining('이해했고 동의합니다'));
      await tester.pumpAndSettle();
      await submit(tester, AppStrings.privacyAgreeButton);
      expect(find.byType(HomePage), findsOneWidget, reason: '세션이 있으면 홈');
    });

    testWidgets('저장소 예외 → 문구 표시 · 버튼 복구 (C1-REV-03)', (tester) async {
      await pumpApp(
        tester,
        initial: AppPage.login.path,
        auth: _ThrowingAuthService(),
      );
      await enter(tester, AppStrings.authEmailLabel, MockAuthService.demoEmail);
      await enter(tester, AppStrings.authPasswordLabel, 'password1');
      await submit(tester, AppStrings.loginButton);
      expect(tester.takeException(), isNull);
      expect(find.text(AppStrings.authErrorUnknown), findsOneWidget);
      expect(
        tester.widget<PrimaryButton>(find.byType(PrimaryButton)).onPressed,
        isNotNull,
        reason: '다시 시도 가능',
      );
    });

    testWidgets('가입하기 링크 → 05 · 뒤로가기 → 04', (tester) async {
      await pumpApp(tester, initial: AppPage.login.path);
      await submit(tester, AppStrings.loginToSignup);
      expect(find.byType(SignupPage), findsOneWidget);
      await tester.tap(find.byTooltip(AppStrings.commonBack));
      await tester.pumpAndSettle();
      expect(find.byType(LoginPage), findsOneWidget);
    });

    testWidgets('비밀번호 찾기 → 프로토타입 안내 스낵바', (tester) async {
      await pumpApp(tester, initial: AppPage.login.path);
      await submit(tester, AppStrings.loginForgot);
      expect(find.text(AppStrings.loginForgotNotice), findsOneWidget);
    });

    testWidgets('스택이 없을 때 뒤로가기 → 03 동의', (tester) async {
      await pumpApp(tester, initial: AppPage.login.path);
      await tester.tap(find.byTooltip(AppStrings.commonBack));
      await tester.pumpAndSettle();
      expect(find.byType(OnboardingPrivacyPage), findsOneWidget);
    });
  });

  group('05 가입', () {
    testWidgets('확인 불일치 → 오류, 일치 → 홈 · 세션 생성', (tester) async {
      final auth = MockAuthService(seedDemoAccount: false);
      await pumpApp(
        tester,
        initial: AppPage.signup.path,
        auth: auth,
        consent: localConsent(),
      );
      await enter(tester, AppStrings.authEmailLabel, 'new@univ.ac.kr');
      await enter(tester, AppStrings.authPasswordLabel, 'password1');
      await enter(tester, AppStrings.authPasswordConfirmLabel, 'password2');
      await submit(tester, AppStrings.signupButton);
      expect(
        find.text(AppStrings.authError(AuthErrorCode.passwordMismatch)),
        findsOneWidget,
      );

      await enter(tester, AppStrings.authPasswordConfirmLabel, 'password1');
      await submit(tester, AppStrings.signupButton);
      expect(find.byType(HomePage), findsOneWidget);
      expect(
        ((await auth.currentUser()) as Success<UserAccount?>).value?.email,
        'new@univ.ac.kr',
      );
    });

    testWidgets('동의 없이 가입 → 03 재동의', (tester) async {
      await pumpApp(
        tester,
        initial: AppPage.signup.path,
        auth: MockAuthService(seedDemoAccount: false),
      );
      await enter(tester, AppStrings.authEmailLabel, 'new@univ.ac.kr');
      await enter(tester, AppStrings.authPasswordLabel, 'password1');
      await enter(tester, AppStrings.authPasswordConfirmLabel, 'password1');
      await submit(tester, AppStrings.signupButton);
      expect(find.byType(OnboardingPrivacyPage), findsOneWidget);
    });

    testWidgets('이미 가입된 이메일 → emailTaken', (tester) async {
      await pumpApp(tester, initial: AppPage.signup.path);
      await enter(tester, AppStrings.authEmailLabel, MockAuthService.demoEmail);
      await enter(tester, AppStrings.authPasswordLabel, 'password1');
      await enter(tester, AppStrings.authPasswordConfirmLabel, 'password1');
      await submit(tester, AppStrings.signupButton);
      expect(
        find.text(AppStrings.authError(AuthErrorCode.emailTaken)),
        findsOneWidget,
      );
    });

    testWidgets('로그인 링크 (스택 없음) → 04', (tester) async {
      await pumpApp(tester, initial: AppPage.signup.path);
      await submit(tester, AppStrings.signupToLogin);
      expect(find.byType(LoginPage), findsOneWidget);
    });
  });

  group('00 스플래시 세션 분기', () {
    Future<void> pumpSplash(
      WidgetTester tester, {
      required MockConsentService consent,
      required MockAuthService auth,
    }) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            providerConfigProvider.overrideWith(
              (ref) async => ProviderConfig.empty,
            ),
            consentServiceProvider.overrideWithValue(consent),
            authServiceProvider.overrideWithValue(auth),
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
                  path: AppPage.login.path,
                  builder: (_, _) => const LoginPage(),
                ),
                GoRoute(
                  path: AppPage.home.path,
                  builder: (_, _) => const HomePage(),
                ),
                GoRoute(
                  path: AppPage.onboardingIntro.path,
                  builder: (_, _) => const Scaffold(body: Text('intro')),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    MockConsentService consentFor(String userId) {
      final service = MockConsentService();
      service.saveConsent(
        ConsentRecord(
          userId: userId,
          consentVersion: service.computeConsentVersion(ProviderConfig.empty),
          acceptedAt: DateTime(2026),
        ),
      );
      return service;
    }

    testWidgets('세션 계정의 동의가 현재 → 홈', (tester) async {
      final auth = MockAuthService();
      await auth.signIn(
        MockAuthService.demoEmail,
        MockAuthService.demoPassword,
      );
      await pumpSplash(tester, consent: consentFor('u-demo'), auth: auth);
      expect(find.byType(HomePage), findsOneWidget);
    });

    testWidgets('세션은 있지만 다른 계정의 동의만 있음 → 01 소개 (재동의)', (tester) async {
      final auth = MockAuthService();
      await auth.signIn(
        MockAuthService.demoEmail,
        MockAuthService.demoPassword,
      );
      await pumpSplash(tester, consent: consentFor('account-A'), auth: auth);
      expect(find.text('intro'), findsOneWidget);
    });

    testWidgets('세션 없음 + 미귀속 동의 현재 → 04 로그인', (tester) async {
      await pumpSplash(
        tester,
        consent: consentFor(ConsentService.unboundUserId),
        auth: MockAuthService(),
      );
      expect(find.byType(LoginPage), findsOneWidget);
    });
  });

  group('접근성 · 반응형', () {
    testWidgets('뒤로가기 · 링크 버튼 히트 영역 ≥ 48', (tester) async {
      await pumpApp(tester, initial: AppPage.login.path);
      expect(
        tester.getSize(find.byTooltip(AppStrings.commonBack)).height,
        greaterThanOrEqualTo(48),
      );
      expect(
        tester.getSize(find.byType(AppTopBar)).height,
        AppTopBar.barHeight,
      );
      for (final label in [AppStrings.loginToSignup, AppStrings.loginForgot]) {
        expect(
          tester
              .getSize(
                find.ancestor(
                  of: find.text(label),
                  matching: find.byType(TextButton),
                ),
              )
              .height,
          greaterThanOrEqualTo(48),
          reason: label,
        );
      }
    });

    for (final page in [AppPage.login, AppPage.signup]) {
      for (final w in widths) {
        for (final s in scales) {
          testWidgets('${page.name} @ ${w.toInt()}×640 ×$s 넘침 없음 · 오류 표시 후에도', (
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
            final cta = page == AppPage.login
                ? AppStrings.loginButton
                : AppStrings.signupButton;
            await submit(tester, cta);
            expect(tester.takeException(), isNull);
            expect(
              find.text(AppStrings.authError(AuthErrorCode.invalidEmail)),
              findsOneWidget,
            );
            expect(find.byType(PrimaryButton), findsOneWidget);
          });
        }
      }

      for (final size in const [Size(1024, 844), Size(844, 390)]) {
        testWidgets(
          '${page.name} @ ${size.width.toInt()}×${size.height.toInt()} 본문 480 상한 · 중앙 (C1-REV-05)',
          (tester) async {
            tester.view.physicalSize = size;
            tester.view.devicePixelRatio = 1.0;
            addTearDown(tester.view.reset);
            await pumpApp(tester, initial: page.path, size: size);
            expect(tester.takeException(), isNull);
            final field = tester.getRect(find.byType(TextField).first);
            expect(field.width, lessThanOrEqualTo(AppSpacing.contentMaxWidth));
            expect(
              (field.center.dx - size.width / 2).abs(),
              lessThan(1),
              reason: '가운데 정렬',
            );
            final button = tester.getRect(find.byType(PrimaryButton));
            expect(button.width, lessThanOrEqualTo(AppSpacing.contentMaxWidth));
          },
        );
      }
    }

    testWidgets('320×640 · 글자 1.3 · 키보드 250 · 상단 24에서 가입 CTA 스크롤 도달', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      tester.view.viewInsets = const FakeViewPadding(bottom: 250);
      tester.view.viewPadding = const FakeViewPadding(top: 24, bottom: 24);
      tester.view.padding = const FakeViewPadding(top: 24);
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.light,
            home: MediaQuery(
              data: MediaQueryData.fromView(
                tester.view,
              ).copyWith(textScaler: const TextScaler.linear(1.3)),
              child: const SignupPage(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text(AppStrings.signupButton));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text(AppStrings.signupButton).hitTestable(), findsOneWidget);
    });
  });
}
