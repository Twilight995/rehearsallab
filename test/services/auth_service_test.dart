import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:rehearsallab/core/enum/auth_error_code.dart';
import 'package:rehearsallab/core/models/result.dart';
import 'package:rehearsallab/models/user_account.dart';
import 'package:rehearsallab/services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  AuthErrorCode? codeOf(Result<Object?> result) =>
      ((result as Failure).exception as AuthException).code;

  /// 테스트용 저비용 hasher (알고리즘은 동일, 반복만 낮춤)
  const fast = PasswordHasher(iterations: 1000);

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
      final a = PrefsAuthService(hasher: fast);
      final signedUp = await a.signUp('k@univ.ac.kr', 'password1');
      expect(signedUp, isA<Success<UserAccount>>());

      final b = PrefsAuthService(hasher: fast);
      final restored = ((await b.currentUser()) as Success<UserAccount?>).value;
      expect(restored, (signedUp as Success<UserAccount>).value);

      await b.signOut();
      expect(
        ((await PrefsAuthService(hasher: fast).currentUser())
                as Success<UserAccount?>)
            .value,
        isNull,
      );
      expect(
        await PrefsAuthService(
          hasher: fast,
        ).signIn('k@univ.ac.kr', 'password1'),
        isA<Success<UserAccount>>(),
      );
    });

    test('비밀번호 원문은 저장되지 않고 KDF 파라미터를 함께 저장한다 (C1-REV-04)', () async {
      await PrefsAuthService(hasher: fast).signUp('k@univ.ac.kr', 'password1');
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(PrefsAuthService.accountsKey)!;
      expect(raw, isNot(contains('password1')));
      final record =
          (json.decode(raw) as Map<String, dynamic>)['k@univ.ac.kr']
              as Map<String, dynamic>;
      expect(record['algorithm'], PasswordHasher.algorithm);
      expect(record['iterations'], 1000);
      expect(record['salt'], isNotEmpty);
      expect((record['password_hash'] as String).length, 64);
    });

    test('손상된 JSON → Failure(storage), 데이터는 지우지 않는다 (C1-REV-03 재현)', () async {
      SharedPreferences.setMockInitialValues({
        PrefsAuthService.accountsKey: '{broken',
      });
      final service = PrefsAuthService(hasher: fast);
      expect(
        codeOf(await service.signIn('a@b.com', 'abcdefgh')),
        AuthErrorCode.storage,
      );
      expect(
        codeOf(await service.signUp('a@b.com', 'abcdefgh')),
        AuthErrorCode.storage,
      );
      expect(
        await service.currentUser(),
        isA<Success<UserAccount?>>(),
        reason: '세션 키가 없으면 계정 목록을 읽지 않는다',
      );
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(PrefsAuthService.accountsKey), '{broken');

      SharedPreferences.setMockInitialValues({
        PrefsAuthService.accountsKey: '{broken',
        PrefsAuthService.sessionKey: 'u-1',
      });
      expect(
        codeOf(await PrefsAuthService(hasher: fast).currentUser()),
        AuthErrorCode.storage,
        reason: '세션이 있으면 목록을 읽다가 실패 → Failure',
      );
    });

    test('형식이 다른 JSON(필드 누락)도 Failure(storage)', () async {
      SharedPreferences.setMockInitialValues({
        PrefsAuthService.accountsKey: json.encode({
          'a@b.com': {'id': 'u-1'},
        }),
      });
      expect(
        codeOf(
          await PrefsAuthService(hasher: fast).signIn('a@b.com', 'abcdefgh'),
        ),
        AuthErrorCode.storage,
      );
    });

    test('세션만 남고 계정이 없으면 세션을 정리한다', () async {
      SharedPreferences.setMockInitialValues({
        PrefsAuthService.sessionKey: 'u-ghost',
      });
      final service = PrefsAuthService(hasher: fast);
      expect(
        ((await service.currentUser()) as Success<UserAccount?>).value,
        isNull,
      );
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(PrefsAuthService.sessionKey), isNull);
    });

    test('초기 단일 SHA-256 레코드는 로그인 성공 시 PBKDF2로 다시 저장된다', () async {
      const salt = 'old-salt';
      SharedPreferences.setMockInitialValues({
        PrefsAuthService.accountsKey: json.encode({
          'old@b.com': {
            'id': 'u-old',
            'email': 'old@b.com',
            'created_at': DateTime(2026, 9, 1).toIso8601String(),
            'salt': salt,
            'password_hash': PasswordHasher.legacyHash('password1', salt),
          },
        }),
      });
      final service = PrefsAuthService(hasher: fast);
      expect(
        await service.signIn('old@b.com', 'password1'),
        isA<Success<UserAccount>>(),
      );
      final prefs = await SharedPreferences.getInstance();
      final record =
          (json.decode(prefs.getString(PrefsAuthService.accountsKey)!)
                  as Map<String, dynamic>)['old@b.com']
              as Map<String, dynamic>;
      expect(record['algorithm'], PasswordHasher.algorithm);
      expect(record['iterations'], 1000);
      expect(record['salt'], isNot(salt));
      expect(
        await PrefsAuthService(hasher: fast).signIn('old@b.com', 'password1'),
        isA<Success<UserAccount>>(),
        reason: '재저장 후에도 로그인',
      );
      expect(
        codeOf(
          await PrefsAuthService(hasher: fast).signIn('old@b.com', 'wrong-pw'),
        ),
        AuthErrorCode.invalidCredentials,
      );
    });

    test('저장 비용이 현재 정책보다 낮으면 로그인 성공 시 상향 재저장 (C1-REV-04)', () async {
      await PrefsAuthService(hasher: fast).signUp('k@univ.ac.kr', 'password1');
      final stronger = PrefsAuthService(
        hasher: const PasswordHasher(iterations: 3000),
      );
      expect(
        await stronger.signIn('k@univ.ac.kr', 'password1'),
        isA<Success<UserAccount>>(),
      );
      Future<int> storedIterations() async {
        final prefs = await SharedPreferences.getInstance();
        final map =
            json.decode(prefs.getString(PrefsAuthService.accountsKey)!)
                as Map<String, dynamic>;
        return (map['k@univ.ac.kr'] as Map<String, dynamic>)['iterations']
            as int;
      }

      expect(await storedIterations(), 3000, reason: '1000 → 3000 상향');
      expect(
        await PrefsAuthService(
          hasher: fast,
        ).signIn('k@univ.ac.kr', 'password1'),
        isA<Success<UserAccount>>(),
        reason: '낮은 hasher로도 저장된 3000으로 검증',
      );
      expect(await storedIterations(), 3000, reason: '높은 비용을 낮추지 않는다');
    });

    test('반복 횟수가 다른 hasher로도 저장된 파라미터로 검증한다', () async {
      await PrefsAuthService(hasher: fast).signUp('k@univ.ac.kr', 'password1');
      expect(
        await PrefsAuthService(
          hasher: const PasswordHasher(iterations: 2000),
        ).signIn('k@univ.ac.kr', 'password1'),
        isA<Success<UserAccount>>(),
      );
    });
  });

  group('PasswordHasher (PBKDF2-HMAC-SHA256)', () {
    test('같은 비밀번호라도 salt가 다르면 해시가 다르고, 같은 입력은 같은 값', () {
      final s1 = PasswordHasher.newSalt();
      final s2 = PasswordHasher.newSalt();
      expect(s1, isNot(s2));
      expect(
        PasswordHasher.derive('password1', s1, 1000),
        isNot(PasswordHasher.derive('password1', s2, 1000)),
      );
      expect(
        PasswordHasher.derive('password1', s1, 1000),
        PasswordHasher.derive('password1', s1, 1000),
      );
      expect(
        PasswordHasher.derive('password1', s1, 1000),
        isNot(PasswordHasher.derive('password1', s1, 1001)),
        reason: '반복 횟수도 결과에 반영',
      );
    });

    test('RFC 6070 PBKDF2-HMAC-SHA256 검증 벡터 (password/salt, 4096회)', () {
      expect(
        PasswordHasher.derive('password', 'salt', 4096),
        'c5e478d59288c841aa530db6845c4c8d962893a001ce4e11a4963873aa98134a',
      );
    });

    test('live 기본 반복 횟수는 OWASP 권고(PBKDF2-HMAC-SHA256 600,000) 이상', () {
      expect(PasswordHasher.defaultIterations, greaterThanOrEqualTo(600000));
      expect(const PasswordHasher(offload: true).iterations, 600000);
      expect(const PasswordHasher().offload, isFalse);
      expect(PrefsAuthService, isNotNull);
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
