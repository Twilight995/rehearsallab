import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rehearsallab/app/app_strings.dart';
import 'package:rehearsallab/core/enum/auth_error_code.dart';
import 'package:rehearsallab/core/models/result.dart';
import 'package:rehearsallab/features/auth/auth_provider.dart';
import 'package:rehearsallab/features/consent/consent_provider.dart';
import 'package:rehearsallab/models/consent_record.dart';
import 'package:rehearsallab/models/user_account.dart';
import 'package:rehearsallab/services/auth_service.dart';
import 'package:rehearsallab/services/consent_service.dart';
import 'package:rehearsallab/ui/common/primary_button.dart';
import 'package:rehearsallab/ui/pages/login/login_page.dart';
import 'package:rehearsallab/ui/pages/signup/signup_page.dart';

/// 로그인 · 가입 성공 **후** 동의 조회(제공사 설정 · 현재 버전)가 실패하는 경로 (C1-REV-03 잔여).
/// 문구 표시 · 버튼 복구 · 세션 롤백까지 확인한다.
void main() {
  Future<MockAuthService> pumpPage(WidgetTester tester, Widget page) async {
    final auth = MockAuthService(seedDemoAccount: false);
    await auth.signUp('k@univ.ac.kr', 'password1');
    await auth.signOut();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          providerConfigProvider.overrideWith(
            (_) async => throw Exception('config failure'),
          ),
          authServiceProvider.overrideWithValue(auth),
        ],
        child: MaterialApp(home: page),
      ),
    );
    await tester.pumpAndSettle();
    return auth;
  }

  Future<void> fill(WidgetTester tester, int fields) async {
    await tester.enterText(find.byType(TextField).at(0), 'k@univ.ac.kr');
    await tester.enterText(find.byType(TextField).at(1), 'password1');
    if (fields > 2) {
      await tester.enterText(find.byType(TextField).at(2), 'password1');
    }
  }

  Future<void> submit(WidgetTester tester, String label) async {
    await tester.ensureVisible(find.text(label));
    await tester.tap(find.text(label));
    await tester.pumpAndSettle();
  }

  Future<bool> hasSession(MockAuthService auth) async =>
      ((await auth.currentUser()) as Success<UserAccount?>).value != null;

  testWidgets('04 로그인 성공 후 동의 조회 실패 → 문구 · 버튼 복구 · 세션 롤백', (tester) async {
    final auth = await pumpPage(tester, const LoginPage());
    await fill(tester, 2);
    await submit(tester, AppStrings.loginButton);
    expect(tester.takeException(), isNull);
    expect(
      find.text(AppStrings.authError(AuthErrorCode.consentCheck)),
      findsOneWidget,
    );
    expect(
      tester.widget<PrimaryButton>(find.byType(PrimaryButton)).onPressed,
      isNotNull,
    );
    expect(find.byType(LoginPage), findsOneWidget);
    expect(await hasSession(auth), isFalse, reason: '반쪽 로그인 상태를 남기지 않음');
  });

  testWidgets('05 가입 성공 후 동의 조회 실패 → 문구 · 버튼 복구 · 세션 롤백 · 계정은 유지', (
    tester,
  ) async {
    final auth = MockAuthService(seedDemoAccount: false);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          providerConfigProvider.overrideWith(
            (_) async => throw Exception('config failure'),
          ),
          authServiceProvider.overrideWithValue(auth),
        ],
        child: const MaterialApp(home: SignupPage()),
      ),
    );
    await tester.pumpAndSettle();
    await fill(tester, 3);
    await submit(tester, AppStrings.signupButton);
    expect(tester.takeException(), isNull);
    expect(
      find.text(AppStrings.authError(AuthErrorCode.consentCheck)),
      findsOneWidget,
    );
    expect(
      tester.widget<PrimaryButton>(find.byType(PrimaryButton)).onPressed,
      isNotNull,
    );
    expect(await hasSession(auth), isFalse);
    expect(
      await auth.signIn('k@univ.ac.kr', 'password1'),
      isA<Success<UserAccount>>(),
      reason: '가입된 계정은 남아 있어 다음 로그인으로 이어짐',
    );
  });

  testWidgets('동의 기록 로드 실패 → bindUser Failure → consentBind 문구 · 세션 없음', (
    tester,
  ) async {
    final auth = MockAuthService();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          consentServiceProvider.overrideWithValue(_LoadFailingConsent()),
          authServiceProvider.overrideWithValue(auth),
        ],
        child: const MaterialApp(home: LoginPage()),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(TextField).at(0),
      MockAuthService.demoEmail,
    );
    await tester.enterText(
      find.byType(TextField).at(1),
      MockAuthService.demoPassword,
    );
    await submit(tester, AppStrings.loginButton);
    expect(tester.takeException(), isNull);
    expect(
      find.text(AppStrings.authError(AuthErrorCode.consentBind)),
      findsOneWidget,
    );
    expect(await hasSession(auth), isFalse);
  });
}

class _LoadFailingConsent extends MockConsentService {
  @override
  Future<Result<List<ConsentRecord>>> loadConsents() async =>
      Failure(Exception('consent storage failure'));
}
