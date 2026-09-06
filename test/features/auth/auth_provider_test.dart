import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rehearsallab/core/enum/auth_error_code.dart';
import 'package:rehearsallab/core/models/result.dart';
import 'package:rehearsallab/features/auth/auth_provider.dart';
import 'package:rehearsallab/features/consent/consent_provider.dart';
import 'package:rehearsallab/models/consent_record.dart';
import 'package:rehearsallab/models/provider_config.dart';
import 'package:rehearsallab/models/user_account.dart';
import 'package:rehearsallab/services/auth_service.dart';
import 'package:rehearsallab/services/consent_service.dart';

/// 동의 저장이 실패하는 상황을 흉내 내는 서비스 (C1-REV-03)
class _FailingSaveConsentService extends MockConsentService {
  bool fail = false;

  @override
  Future<Result<void>> saveConsent(ConsentRecord record) async =>
      fail ? Failure(Exception('write failed')) : super.saveConsent(record);
}

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

  Future<Result<UserAccount>> demoSignIn(ProviderContainer c) => c
      .read(authNotifierProvider.notifier)
      .signIn(MockAuthService.demoEmail, MockAuthService.demoPassword);

  group('AuthNotifier (04 · 05 → 06/07)', () {
    test('처음에는 세션 없음', () async {
      final c = container();
      expect(await c.read(authNotifierProvider.future), isNull);
    });

    test('signIn 성공 → 상태에 계정', () async {
      final c = container();
      await c.read(authNotifierProvider.future);
      final result = await demoSignIn(c);
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
      final consentNotifier = c.read(consentNotifierProvider.notifier);
      expect(consentNotifier.recordFor(null), isNotNull);

      await c.read(authNotifierProvider.future);
      final userId = ((await demoSignIn(c)) as Success<UserAccount>).value.id;
      expect(consentNotifier.recordFor(null), isNull, reason: 'local 소진');
      expect(consentNotifier.recordFor(userId), isNotNull);
      expect(await consentNotifier.isCurrentFor(userId), isTrue);
      final stored =
          ((await consent.loadConsents()) as Success<List<ConsentRecord>>)
              .value;
      expect(stored.map((r) => r.userId), [userId], reason: '저장소에도 반영');
    });

    test('다른 계정(A)의 동의는 B의 동의로 인정하지 않는다 (C1-REV-01 재현)', () async {
      final c = container();
      await c.read(consentNotifierProvider.future);
      await c.read(authNotifierProvider.future);
      await c
          .read(consentNotifierProvider.notifier)
          .accept(userId: 'account-A');
      await demoSignIn(c);
      expect(c.read(authNotifierProvider).value?.id, 'u-demo');
      final consentNotifier = c.read(consentNotifierProvider.notifier);
      expect(await consentNotifier.isCurrentFor('u-demo'), isFalse);
      expect(
        consentNotifier.recordFor('account-A'),
        isNotNull,
        reason: 'A 기록 유지',
      );
    });

    test('A 동의 → 로그아웃 → B 로그인 → B 재동의 → 둘 다 유효', () async {
      final auth = MockAuthService();
      await auth.signUp('b@univ.ac.kr', 'password1');
      await auth.signOut();
      final c = container(auth: auth);
      await c.read(consentNotifierProvider.future);
      await c.read(authNotifierProvider.future);
      final consentNotifier = c.read(consentNotifierProvider.notifier);
      final authNotifier = c.read(authNotifierProvider.notifier);

      await consentNotifier.accept();
      final a = ((await demoSignIn(c)) as Success<UserAccount>).value;
      expect(await consentNotifier.isCurrentFor(a.id), isTrue);
      await authNotifier.signOut();

      final b =
          ((await authNotifier.signIn('b@univ.ac.kr', 'password1'))
                  as Success<UserAccount>)
              .value;
      expect(
        await consentNotifier.isCurrentFor(b.id),
        isFalse,
        reason: 'B는 재동의',
      );
      await consentNotifier.accept(userId: b.id);
      expect(await consentNotifier.isCurrentFor(b.id), isTrue);
      expect(await consentNotifier.isCurrentFor(a.id), isTrue, reason: 'A 유지');
    });

    test('동의 묶기 실패 → Failure(consentBind) · 세션 없음 (C1-REV-03 재현)', () async {
      final consent = _FailingSaveConsentService();
      final auth = MockAuthService();
      final c = container(auth: auth, consent: consent);
      await c.read(consentNotifierProvider.future);
      await c.read(authNotifierProvider.future);
      await c.read(consentNotifierProvider.notifier).accept();
      consent.fail = true;

      final result = await demoSignIn(c);
      expect(result, isA<Failure<UserAccount>>());
      final exception = (result as Failure<UserAccount>).exception;
      expect((exception as AuthException).code, AuthErrorCode.consentBind);
      expect(c.read(authNotifierProvider).value, isNull);
      expect(
        ((await auth.currentUser()) as Success<UserAccount?>).value,
        isNull,
        reason: '서비스 세션도 되돌림',
      );
    });
  });
}
