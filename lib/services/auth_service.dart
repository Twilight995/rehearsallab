import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:rehearsallab/core/enum/auth_error_code.dart';
import 'package:rehearsallab/core/models/result.dart';
import 'package:rehearsallab/models/user_account.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 로그인 · 가입 실패. `code`로 문구를 고른다 (AppStrings.authError).
class AuthException implements Exception {
  final AuthErrorCode code;
  const AuthException(this.code);

  @override
  String toString() => 'AuthException(${code.name})';
}

/// 04 로그인 · 05 가입 (통합 문서 4장 "로그인/가입 성공 → 06/07").
/// 외부 인증 서버 없이 기기 안에서만 계정을 관리한다 (계약서 1장: 수업 제공 API 사용 금지).
/// 명령은 `Future<Result<T>>`. 세션은 서비스가 보관하며 Notifier가 `currentUser()`로 복원한다.
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

/// 비밀번호 저장용 salted SHA-256. 원문은 어디에도 저장하지 않는다.
class PasswordHasher {
  static final Random _random = Random.secure();

  static String newSalt() {
    final bytes = List<int>.generate(16, (_) => _random.nextInt(256));
    return base64Url.encode(bytes);
  }

  static String hash(String password, String salt) =>
      sha256.convert(utf8.encode('$salt:$password')).toString();
}

/// 저장소에 남는 계정 레코드 (해시 · salt 포함). 화면에는 UserAccount만 노출한다.
class _StoredAccount {
  final UserAccount account;
  final String salt;
  final String passwordHash;

  const _StoredAccount({
    required this.account,
    required this.salt,
    required this.passwordHash,
  });

  bool matches(String password) =>
      PasswordHasher.hash(password, salt) == passwordHash;

  Map<String, dynamic> toMap() => <String, dynamic>{
    ...account.toMap(),
    'salt': salt,
    'password_hash': passwordHash,
  };

  factory _StoredAccount.fromMap(Map<String, dynamic> map) => _StoredAccount(
    account: UserAccount.fromMap(map),
    salt: map['salt'] as String,
    passwordHash: map['password_hash'] as String,
  );
}

/// 메모리 · 사전 저장 방식 공통 로직. 하위 클래스는 저장소 읽기/쓰기만 구현한다.
abstract class _AccountStoreAuthService extends AuthService {
  Future<Map<String, _StoredAccount>> _loadAccounts();
  Future<void> _saveAccounts(Map<String, _StoredAccount> accounts);
  Future<String?> _loadSessionUserId();
  Future<void> _saveSessionUserId(String? userId);

  @override
  Future<Result<UserAccount>> signUp(String email, String password) async {
    final invalid = AuthService.validate(email, password);
    if (invalid != null) return Failure(AuthException(invalid));
    final key = AuthService.normalizeEmail(email);
    final accounts = await _loadAccounts();
    if (accounts.containsKey(key)) {
      return const Failure(AuthException(AuthErrorCode.emailTaken));
    }
    final salt = PasswordHasher.newSalt();
    final account = UserAccount(
      id: 'u-${DateTime.now().microsecondsSinceEpoch}',
      email: key,
      createdAt: DateTime.now(),
    );
    accounts[key] = _StoredAccount(
      account: account,
      salt: salt,
      passwordHash: PasswordHasher.hash(password, salt),
    );
    await _saveAccounts(accounts);
    await _saveSessionUserId(account.id);
    return Success(account);
  }

  @override
  Future<Result<UserAccount>> signIn(String email, String password) async {
    final invalid = AuthService.validate(email, password);
    if (invalid != null) return Failure(AuthException(invalid));
    final stored = (await _loadAccounts())[AuthService.normalizeEmail(email)];
    if (stored == null || !stored.matches(password)) {
      return const Failure(AuthException(AuthErrorCode.invalidCredentials));
    }
    await _saveSessionUserId(stored.account.id);
    return Success(stored.account);
  }

  @override
  Future<Result<UserAccount?>> currentUser() async {
    final userId = await _loadSessionUserId();
    if (userId == null) return const Success(null);
    for (final stored in (await _loadAccounts()).values) {
      if (stored.account.id == userId) return Success(stored.account);
    }
    // 세션은 남았는데 계정이 없음(데이터 삭제 등) → 세션 정리
    await _saveSessionUserId(null);
    return const Success(null);
  }

  @override
  Future<Result<void>> signOut() async {
    await _saveSessionUserId(null);
    return const Success(null);
  }
}

/// mock 모드: 메모리 계정. 데모 계정 1개를 미리 넣어 04 화면 값(k.student@univ.ac.kr)으로 바로 로그인된다.
class MockAuthService extends _AccountStoreAuthService {
  static const String demoEmail = 'k.student@univ.ac.kr';
  static const String demoPassword = 'rehearsal';

  final Map<String, _StoredAccount> _accounts = {};
  String? _sessionUserId;

  MockAuthService({bool seedDemoAccount = true}) {
    if (seedDemoAccount) {
      const salt = 'demo-salt';
      _accounts[demoEmail] = _StoredAccount(
        account: UserAccount(
          id: 'u-demo',
          email: demoEmail,
          createdAt: DateTime(2026, 9, 1),
        ),
        salt: salt,
        passwordHash: PasswordHasher.hash(demoPassword, salt),
      );
    }
  }

  @override
  Future<Map<String, _StoredAccount>> _loadAccounts() async => _accounts;

  @override
  Future<void> _saveAccounts(Map<String, _StoredAccount> accounts) async {}

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
  Future<Map<String, _StoredAccount>> _loadAccounts() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(accountsKey);
    if (raw == null || raw.isEmpty) return {};
    final decoded = json.decode(raw) as Map<String, dynamic>;
    return {
      for (final entry in decoded.entries)
        entry.key: _StoredAccount.fromMap(entry.value as Map<String, dynamic>),
    };
  }

  @override
  Future<void> _saveAccounts(Map<String, _StoredAccount> accounts) async {
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
