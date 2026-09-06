import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rehearsallab/core/models/result.dart';
import 'package:rehearsallab/features/auth/auth_provider.dart';
import 'package:rehearsallab/features/consent/consent_provider.dart';
import 'package:rehearsallab/models/provider_config.dart';
import 'package:rehearsallab/models/user_account.dart';
import 'package:rehearsallab/services/auth_service.dart';
import 'package:rehearsallab/services/consent_service.dart';

void main() {
  ProviderContainer container({AuthService? auth, ConsentService? consent}) {
    final c = ProviderContainer(
      overrides: [
        providerConfigProvider.overrideWith(
          (ref) async => ProviderConfig.empty,
        ),
        if (auth != null) authServiceProvider.overrideWithValue(auth),
        if (consent != null) consentServiceProvider.overrideWithValue(consent),
      ],
    );
    addTearDown(c.dispose);
    return c;
  }

  group('AuthNotifier (04 · 05 → 06/07)', () {
    test('처음에는 세션 없음', () async {
      final c = container();
      expect(await c.read(authNotifierProvider.future), isNull);
    });

    test('signIn 성공 → 상태에 계정', () async {
      final c = container();
      await c.read(authNotifierProvider.future);
      final result = await c
          .read(authNotifierProvider.notifier)
          .signIn(MockAuthService.demoEmail, MockAuthService.demoPassword);
      expect(result, isA<Success<UserAccount>>());
      expect(
        c.read(authNotifierProvider).value?.email,
        MockAuthService.demoEmail,
      );
    });

    test('signIn 실패 → 상태 유지(null) · Failure 반환', () async {
      final c = container();
      await c.read(authNotifierProvider.future);
      final result = await c
          .read(authNotifierProvider.notifier)
          .signIn(MockAuthService.demoEmail, 'wrong-password');
      expect(result, isA<Failure<UserAccount>>());
      expect(c.read(authNotifierProvider).value, isNull);
    });

    test('signUp 성공 → 세션 · signOut → null', () async {
      final c = container(auth: MockAuthService(seedDemoAccount: false));
      await c.read(authNotifierProvider.future);
      final notifier = c.read(authNotifierProvider.notifier);
      await notifier.signUp('new@univ.ac.kr', 'password1');
      expect(c.read(authNotifierProvider).value?.email, 'new@univ.ac.kr');
      await notifier.signOut();
      expect(c.read(authNotifierProvider).value, isNull);
    });

    test('로그인 직후 03에서 저장된 local 동의를 계정에 묶는다', () async {
      final consent = MockConsentService();
      final c = container(consent: consent);
      await c.read(consentNotifierProvider.future);
      await c.read(consentNotifierProvider.notifier).accept();
      expect(c.read(consentNotifierProvider).value?.userId, 'local');

      await c.read(authNotifierProvider.future);
      final result = await c
          .read(authNotifierProvider.notifier)
          .signIn(MockAuthService.demoEmail, MockAuthService.demoPassword);
      final userId = (result as Success<UserAccount>).value.id;
      expect(c.read(consentNotifierProvider).value?.userId, userId);
      expect(
        ((await consent.loadConsent()) as Success).value?.userId,
        userId,
        reason: '저장소에도 반영',
      );
    });

    test('다른 계정에 묶인 동의는 덮어쓰지 않는다', () async {
      final consent = MockConsentService();
      final c = container(consent: consent);
      await c.read(consentNotifierProvider.future);
      await c.read(consentNotifierProvider.notifier).accept(userId: 'u-other');
      await c.read(authNotifierProvider.future);
      await c
          .read(authNotifierProvider.notifier)
          .signIn(MockAuthService.demoEmail, MockAuthService.demoPassword);
      expect(c.read(consentNotifierProvider).value?.userId, 'u-other');
    });
  });
}
