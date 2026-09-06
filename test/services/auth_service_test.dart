import 'package:flutter_test/flutter_test.dart';
import 'package:rehearsallab/core/enum/auth_error_code.dart';
import 'package:rehearsallab/core/models/result.dart';
import 'package:rehearsallab/models/user_account.dart';
import 'package:rehearsallab/services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  AuthErrorCode? codeOf(Result<Object?> result) =>
      ((result as Failure).exception as AuthException).code;

  group('입력 검증 (04 · 05)', () {
    test('이메일 형식', () {
      expect(
        AuthService.validate('not-an-email', 'password1'),
        AuthErrorCode.invalidEmail,
      );
      expect(
        AuthService.validate('a@b', 'password1'),
        AuthErrorCode.invalidEmail,
      );
      expect(AuthService.validate(' k@univ.ac.kr ', 'password1'), isNull);
    });

    test('비밀번호 8자 이상', () {
      expect(
        AuthService.validate('k@univ.ac.kr', '1234567'),
        AuthErrorCode.passwordTooShort,
      );
      expect(AuthService.validate('k@univ.ac.kr', '12345678'), isNull);
    });

    test('가입은 확인 비밀번호 일치', () {
      expect(
        AuthService.validate(
          'k@univ.ac.kr',
          'password1',
          passwordConfirm: 'password2',
        ),
        AuthErrorCode.passwordMismatch,
      );
    });

    test('검증 순서: 이메일 → 길이 → 확인', () {
      expect(
        AuthService.validate('bad', 'short', passwordConfirm: 'x'),
        AuthErrorCode.invalidEmail,
      );
    });
  });

  group('MockAuthService', () {
    test('데모 계정으로 로그인 · 세션 복원', () async {
      final service = MockAuthService();
      expect(
        ((await service.currentUser()) as Success<UserAccount?>).value,
        isNull,
      );
      final result = await service.signIn(
        MockAuthService.demoEmail,
        MockAuthService.demoPassword,
      );
      expect(result, isA<Success<UserAccount>>());
      expect(
        ((await service.currentUser()) as Success<UserAccount?>).value?.email,
        MockAuthService.demoEmail,
      );
      await service.signOut();
      expect(
        ((await service.currentUser()) as Success<UserAccount?>).value,
        isNull,
      );
    });

    test('가입 → 같은 이메일 재가입 거부 · 대소문자/공백 정규화', () async {
      final service = MockAuthService(seedDemoAccount: false);
      final first = await service.signUp('New@Univ.ac.kr', 'password1');
      expect((first as Success<UserAccount>).value.email, 'new@univ.ac.kr');
      expect(first.value.displayName, 'new');
      expect(
        codeOf(await service.signUp(' new@univ.ac.kr ', 'password9')),
        AuthErrorCode.emailTaken,
      );
    });

    test('틀린 비밀번호 · 없는 계정 모두 invalidCredentials (구분 없음)', () async {
      final service = MockAuthService();
      expect(
        codeOf(await service.signIn(MockAuthService.demoEmail, 'wrongpass')),
        AuthErrorCode.invalidCredentials,
      );
      expect(
        codeOf(await service.signIn('nobody@univ.ac.kr', 'wrongpass')),
        AuthErrorCode.invalidCredentials,
      );
    });

    test('검증 실패는 저장소를 건드리지 않는다', () async {
      final service = MockAuthService(seedDemoAccount: false);
      expect(
        codeOf(await service.signUp('bad', 'password1')),
        AuthErrorCode.invalidEmail,
      );
      expect(
        ((await service.currentUser()) as Success<UserAccount?>).value,
        isNull,
      );
    });
  });

  group('PrefsAuthService (SharedPreferences)', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('가입 후 새 인스턴스에서도 세션 · 로그인 유지', () async {
      final a = PrefsAuthService();
      final signedUp = await a.signUp('k@univ.ac.kr', 'password1');
      expect(signedUp, isA<Success<UserAccount>>());

      final b = PrefsAuthService();
      final restored = ((await b.currentUser()) as Success<UserAccount?>).value;
      expect(restored, (signedUp as Success<UserAccount>).value);

      await b.signOut();
      expect(
        ((await PrefsAuthService().currentUser()) as Success<UserAccount?>)
            .value,
        isNull,
      );
      expect(
        await PrefsAuthService().signIn('k@univ.ac.kr', 'password1'),
        isA<Success<UserAccount>>(),
      );
    });

    test('비밀번호 원문은 저장되지 않는다 (salted SHA-256)', () async {
      await PrefsAuthService().signUp('k@univ.ac.kr', 'password1');
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(PrefsAuthService.accountsKey)!;
      expect(raw, isNot(contains('password1')));
      expect(raw, contains('password_hash'));
      expect(raw, contains('salt'));
    });

    test('세션만 남고 계정이 없으면 세션을 정리한다', () async {
      SharedPreferences.setMockInitialValues({
        PrefsAuthService.sessionKey: 'u-ghost',
      });
      final service = PrefsAuthService();
      expect(
        ((await service.currentUser()) as Success<UserAccount?>).value,
        isNull,
      );
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(PrefsAuthService.sessionKey), isNull);
    });
  });

  group('PasswordHasher', () {
    test('같은 비밀번호라도 salt가 다르면 해시가 다르다', () {
      final s1 = PasswordHasher.newSalt();
      final s2 = PasswordHasher.newSalt();
      expect(s1, isNot(s2));
      expect(
        PasswordHasher.hash('password1', s1),
        isNot(PasswordHasher.hash('password1', s2)),
      );
      expect(
        PasswordHasher.hash('password1', s1),
        PasswordHasher.hash('password1', s1),
      );
    });
  });

  group('UserAccount 직렬화', () {
    test('왕복', () {
      final account = UserAccount(
        id: 'u-1',
        email: 'k@univ.ac.kr',
        createdAt: DateTime(2026, 9, 6, 10),
      );
      expect(UserAccount.fromJson(account.toJson()), account);
      expect(account.toMap().keys, ['id', 'email', 'created_at']);
    });
  });
}
