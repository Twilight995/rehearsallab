import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rehearsallab/app/app_config.dart';
import 'package:rehearsallab/core/enum/app_mode.dart';
import 'package:rehearsallab/core/enum/auth_error_code.dart';
import 'package:rehearsallab/core/models/result.dart';
import 'package:rehearsallab/features/consent/consent_provider.dart';
import 'package:rehearsallab/models/user_account.dart';
import 'package:rehearsallab/services/auth_service.dart';

/// mock 모드는 메모리(데모 계정 포함), live 모드는 SharedPreferences (C1-2).
final authServiceProvider = Provider<AuthService>((ref) {
  return ref.watch(appModeProvider) == AppMode.mock
      ? MockAuthService()
      : PrefsAuthService();
});

final authNotifierProvider = AsyncNotifierProvider<AuthNotifier, UserAccount?>(
  AuthNotifier.new,
  retry: (retryCount, error) => null,
);

/// 로그인 세션 (통합 문서 4장: 로그인/가입 성공 → 06/07). null이면 로그아웃 상태.
class AuthNotifier extends AsyncNotifier<UserAccount?> {
  AuthService get _service => ref.read(authServiceProvider);

  @override
  FutureOr<UserAccount?> build() async {
    final result = await _service.currentUser();
    return switch (result) {
      Success(:final value) => value,
      Failure(:final exception) => throw exception,
    };
  }

  Future<Result<UserAccount>> signIn(String email, String password) =>
      _apply(() => _service.signIn(email, password));

  Future<Result<UserAccount>> signUp(String email, String password) =>
      _apply(() => _service.signUp(email, password));

  Future<Result<void>> signOut() async {
    final result = await _service.signOut();
    if (result is Success) state = const AsyncData(null);
    return result;
  }

  /// 성공하면 03에서 계정 없이(`local`) 저장된 동의를 이 계정에 묶은 뒤 세션 상태를 바꾼다.
  /// 묶기에 실패하면 세션을 되돌리고 Failure(consentBind)를 돌려준다 — 동의 저장이 안 된 채로
  /// 홈에 들어가지 않는다 (C1-REV-03).
  Future<Result<UserAccount>> _apply(
    Future<Result<UserAccount>> Function() action,
  ) async {
    final result = await action();
    if (result case Success(:final value)) {
      final bound = await ref
          .read(consentNotifierProvider.notifier)
          .bindUser(value.id);
      if (bound case Failure(:final exception)) {
        await _service.signOut();
        state = const AsyncData(null);
        return Failure(AuthException(AuthErrorCode.consentBind, exception));
      }
      state = AsyncData(value);
    }
    return result;
  }
}
