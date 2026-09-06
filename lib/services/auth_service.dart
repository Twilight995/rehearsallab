import 'dart:convert';
import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:rehearsallab/core/enum/auth_error_code.dart';
import 'package:rehearsallab/core/models/result.dart';
import 'package:rehearsallab/models/user_account.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 로그인 · 가입 실패. `code`로 문구를 고른다 (AppStrings.authError). `cause`는 로그용.
class AuthException implements Exception {
  final AuthErrorCode code;
  final Object? cause;
  const AuthException(this.code, [this.cause]);

  @override
  String toString() =>
      'AuthException(${code.name}${cause == null ? '' : ', $cause'})';
}

/// 04 로그인 · 05 가입 (통합 문서 4장 "로그인/가입 성공 → 06/07").
/// 외부 인증 서버 없이 기기 안에서만 계정을 관리한다 (계약서 1장: 수업 제공 API 사용 금지).
/// 명령은 `Future<Result<T>>`이며 저장소 예외는 모두 `Failure(AuthException(storage))`로 돌려준다.
/// 세션은 서비스가 보관하며 Notifier가 `currentUser()`로 복원한다.
abstract class AuthService {
  static const int passwordMinLength = 8;
  static final RegExp _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  /// 가입 · 로그인 공통 입력 검증. 통과하면 null.
  static AuthErrorCode? validate(
    String email,
    String password, {
    String? passwordConfirm,
  }) {
    if (!_emailPattern.hasMatch(email.trim())) {
      return AuthErrorCode.invalidEmail;
    }
    if (password.length < passwordMinLength) {
      return AuthErrorCode.passwordTooShort;
    }
    if (passwordConfirm != null && passwordConfirm != password) {
      return AuthErrorCode.passwordMismatch;
    }
    return null;
  }

  static String normalizeEmail(String email) => email.trim().toLowerCase();

  Future<Result<UserAccount>> signUp(String email, String password);

  Future<Result<UserAccount>> signIn(String email, String password);

  /// 저장된 세션의 계정. 없으면 null.
  Future<Result<UserAccount?>> currentUser();

  Future<Result<void>> signOut();
}

/// 비밀번호 저장용 KDF: PBKDF2-HMAC-SHA256 (C1-REV-04, OWASP Password Storage).
/// 레코드에 알고리즘 · 반복 횟수 · salt를 함께 저장해 나중에 비용을 올려도 기존 레코드를 검증할 수 있다.
/// 반복 횟수는 순수 Dart 비용을 고려한 값(데스크톱 약 0.45초)이며, `offload`면 별도 isolate에서 계산한다.
class PasswordHasher {
  static const String algorithm = 'pbkdf2-sha256';
  static const String legacyAlgorithm = 'sha256';
  static const int defaultIterations = 210000;
  static const int _keyLength = 32;
  static final Random _random = Random.secure();

  final int iterations;
  final bool offload;

  const PasswordHasher({
    this.iterations = defaultIterations,
    this.offload = false,
  });

  static String newSalt() {
    final bytes = List<int>.generate(16, (_) => _random.nextInt(256));
    return base64Url.encode(bytes);
  }

  Future<String> hash(String password, String salt) => offload
      ? Isolate.run(() => derive(password, salt, iterations))
      : Future.value(derive(password, salt, iterations));

  /// 순수 계산 (테스트 · 검증용). 결과는 16진수 문자열.
  static String derive(String password, String salt, int iterations) {
    final hmac = Hmac(sha256, utf8.encode(password));
    final saltBytes = utf8.encode(salt);
    final output = <int>[];
    var block = 1;
    while (output.length < _keyLength) {
      var u = Uint8List.fromList(
        hmac.convert([
          ...saltBytes,
          (block >> 24) & 0xff,
          (block >> 16) & 0xff,
          (block >> 8) & 0xff,
          block & 0xff,
        ]).bytes,
      );
      final t = Uint8List.fromList(u);
      for (var i = 1; i < iterations; i++) {
        u = Uint8List.fromList(hmac.convert(u).bytes);
        for (var j = 0; j < t.length; j++) {
          t[j] ^= u[j];
        }
      }
      output.addAll(t);
      block++;
    }
    return output
        .sublist(0, _keyLength)
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join();
  }

  /// 초기 구현의 단일 SHA-256 (`sha256(salt:password)`). 검증 전용 · 새로 만들지 않음.
  static String legacyHash(String password, String salt) =>
      sha256.convert(utf8.encode('$salt:$password')).toString();
}

/// 저장소에 남는 계정 레코드 (해시 · salt · 알고리즘 · 반복 횟수). 화면에는 UserAccount만 노출한다.
class StoredAccount {
  final UserAccount account;
  final String salt;
  final String passwordHash;
  final String algorithm;
  final int iterations;

  const StoredAccount({
    required this.account,
    required this.salt,
    required this.passwordHash,
    this.algorithm = PasswordHasher.algorithm,
    this.iterations = PasswordHasher.defaultIterations,
  });

  bool get isLegacy => algorithm == PasswordHasher.legacyAlgorithm;

  Future<bool> matches(String password, PasswordHasher hasher) async {
    if (isLegacy) {
      return PasswordHasher.legacyHash(password, salt) == passwordHash;
    }
    final derived = hasher.offload
        ? await Isolate.run(
            () => PasswordHasher.derive(password, salt, iterations),
          )
        : PasswordHasher.derive(password, salt, iterations);
    return derived == passwordHash;
  }

  Map<String, dynamic> toMap() => <String, dynamic>{
    ...account.toMap(),
    'salt': salt,
    'password_hash': passwordHash,
    'algorithm': algorithm,
    'iterations': iterations,
  };

  /// `algorithm`이 없는 레코드는 초기 단일 SHA-256 레코드로 읽는다.
  factory StoredAccount.fromMap(Map<String, dynamic> map) => StoredAccount(
    account: UserAccount.fromMap(map),
    salt: map['salt'] as String,
    passwordHash: map['password_hash'] as String,
    algorithm: map['algorithm'] as String? ?? PasswordHasher.legacyAlgorithm,
    iterations: map['iterations'] as int? ?? 1,
  );
}

/// 메모리 · 사전 저장 방식 공통 로직. 하위 클래스는 저장소 읽기/쓰기만 구현한다.
abstract class _AccountStoreAuthService extends AuthService {
  PasswordHasher get _hasher;

  Future<Map<String, StoredAccount>> _loadAccounts();
  Future<void> _saveAccounts(Map<String, StoredAccount> accounts);
  Future<String?> _loadSessionUserId();
  Future<void> _saveSessionUserId(String? userId);

  /// 저장소 예외 → Failure(storage). 손상 데이터는 지우지 않고 그대로 둔다.
  Future<Result<T>> _guard<T>(Future<Result<T>> Function() body) async {
    try {
      return await body();
    } on Exception catch (e) {
      return Failure(AuthException(AuthErrorCode.storage, e));
    } on Error catch (e) {
      // 형식이 맞지 않는 JSON의 캐스트 실패(TypeError) 등
      return Failure(AuthException(AuthErrorCode.storage, e));
    }
  }

  Future<StoredAccount> _newRecord(UserAccount account, String password) async {
    final salt = PasswordHasher.newSalt();
    return StoredAccount(
      account: account,
      salt: salt,
      passwordHash: await _hasher.hash(password, salt),
      algorithm: PasswordHasher.algorithm,
      iterations: _hasher.iterations,
    );
  }

  @override
  Future<Result<UserAccount>> signUp(String email, String password) {
    final invalid = AuthService.validate(email, password);
    if (invalid != null) return Future.value(Failure(AuthException(invalid)));
    return _guard(() async {
      final key = AuthService.normalizeEmail(email);
      final accounts = await _loadAccounts();
      if (accounts.containsKey(key)) {
        return const Failure(AuthException(AuthErrorCode.emailTaken));
      }
      final account = UserAccount(
        id: 'u-${DateTime.now().microsecondsSinceEpoch}',
        email: key,
        createdAt: DateTime.now(),
      );
      accounts[key] = await _newRecord(account, password);
      await _saveAccounts(accounts);
      await _saveSessionUserId(account.id);
      return Success(account);
    });
  }

  @override
  Future<Result<UserAccount>> signIn(String email, String password) {
    final invalid = AuthService.validate(email, password);
    if (invalid != null) return Future.value(Failure(AuthException(invalid)));
    return _guard(() async {
      final key = AuthService.normalizeEmail(email);
      final accounts = await _loadAccounts();
      final stored = accounts[key];
      if (stored == null || !await stored.matches(password, _hasher)) {
        return const Failure(AuthException(AuthErrorCode.invalidCredentials));
      }
      if (stored.isLegacy) {
        // 초기 단일 해시 레코드는 로그인 성공 시 PBKDF2로 다시 저장한다
        accounts[key] = await _newRecord(stored.account, password);
        await _saveAccounts(accounts);
      }
      await _saveSessionUserId(stored.account.id);
      return Success(stored.account);
    });
  }

  @override
  Future<Result<UserAccount?>> currentUser() => _guard(() async {
    final userId = await _loadSessionUserId();
    if (userId == null) return const Success(null);
    for (final stored in (await _loadAccounts()).values) {
      if (stored.account.id == userId) return Success(stored.account);
    }
    // 세션은 남았는데 계정이 없음(데이터 삭제 등) → 세션만 정리
    await _saveSessionUserId(null);
    return const Success(null);
  });

  @override
  Future<Result<void>> signOut() => _guard(() async {
    await _saveSessionUserId(null);
    return const Success(null);
  });
}

/// mock 모드: 메모리 계정. 데모 계정 1개를 미리 넣어 04 화면 값(k.student@univ.ac.kr)으로 바로 로그인된다.
/// 테스트 속도를 위해 반복 횟수를 낮춘 hasher를 쓴다 (영속 저장 없음).
class MockAuthService extends _AccountStoreAuthService {
  static const String demoEmail = 'k.student@univ.ac.kr';
  static const String demoPassword = 'rehearsal';
  static const PasswordHasher demoHasher = PasswordHasher(iterations: 1000);

  final Map<String, StoredAccount> _accounts = {};
  String? _sessionUserId;

  @override
  final PasswordHasher _hasher;

  MockAuthService({bool seedDemoAccount = true, PasswordHasher? hasher})
    : _hasher = hasher ?? demoHasher {
    if (seedDemoAccount) {
      const salt = 'demo-salt';
      _accounts[demoEmail] = StoredAccount(
        account: UserAccount(
          id: 'u-demo',
          email: demoEmail,
          createdAt: DateTime(2026, 9, 1),
        ),
        salt: salt,
        passwordHash: PasswordHasher.derive(
          demoPassword,
          salt,
          _hasher.iterations,
        ),
        iterations: _hasher.iterations,
      );
    }
  }

  @override
  Future<Map<String, StoredAccount>> _loadAccounts() async => _accounts;

  @override
  Future<void> _saveAccounts(Map<String, StoredAccount> accounts) async {}

  @override
  Future<String?> _loadSessionUserId() async => _sessionUserId;

  @override
  Future<void> _saveSessionUserId(String? userId) async =>
      _sessionUserId = userId;
}

/// live 모드: SharedPreferences. 계정 목록은 JSON 하나, 세션은 user id 하나.
class PrefsAuthService extends _AccountStoreAuthService {
  static const String accountsKey = 'auth.accounts';
  static const String sessionKey = 'auth.session_user_id';

  @override
  final PasswordHasher _hasher;

  PrefsAuthService({PasswordHasher? hasher})
    : _hasher = hasher ?? const PasswordHasher(offload: true);

  @override
  Future<Map<String, StoredAccount>> _loadAccounts() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(accountsKey);
    if (raw == null || raw.isEmpty) return {};
    final decoded = json.decode(raw) as Map<String, dynamic>;
    return {
      for (final entry in decoded.entries)
        entry.key: StoredAccount.fromMap(entry.value as Map<String, dynamic>),
    };
  }

  @override
  Future<void> _saveAccounts(Map<String, StoredAccount> accounts) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      accountsKey,
      json.encode({
        for (final entry in accounts.entries) entry.key: entry.value.toMap(),
      }),
    );
  }

  @override
  Future<String?> _loadSessionUserId() async =>
      (await SharedPreferences.getInstance()).getString(sessionKey);

  @override
  Future<void> _saveSessionUserId(String? userId) async {
    final prefs = await SharedPreferences.getInstance();
    if (userId == null) {
      await prefs.remove(sessionKey);
    } else {
      await prefs.setString(sessionKey, userId);
    }
  }
}
