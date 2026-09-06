import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rehearsallab/app/app_config.dart';
import 'package:rehearsallab/core/enum/app_mode.dart';
import 'package:rehearsallab/core/models/result.dart';
import 'package:rehearsallab/models/consent_record.dart';
import 'package:rehearsallab/models/provider_config.dart';
import 'package:rehearsallab/services/consent_service.dart';

/// assets/providers.json → ProviderConfig. 비어 있으면 ProviderConfig.empty (제공사 미지정 · 전송 차단).
final providerConfigProvider = FutureProvider<ProviderConfig>((ref) async {
  try {
    final raw = await rootBundle.loadString('assets/providers.json');
    return ProviderConfig.fromJson(raw);
  } on Exception {
    return ProviderConfig.empty;
  }
});

/// mock 모드는 메모리, live 모드는 SharedPreferences (C1-1).
final consentServiceProvider = Provider<ConsentService>((ref) {
  return ref.watch(appModeProvider) == AppMode.mock
      ? MockConsentService()
      : PrefsConsentService();
});

/// 현재 제공사 설정으로 계산한 동의 버전. 제공사 · 지역 · 정책 버전이 바뀌면 값이 바뀐다.
final currentConsentVersionProvider = FutureProvider<String>((ref) async {
  final config = await ref.watch(providerConfigProvider.future);
  return ref.watch(consentServiceProvider).computeConsentVersion(config);
});

final consentNotifierProvider =
    AsyncNotifierProvider<ConsentNotifier, ConsentRecord?>(ConsentNotifier.new);

/// 프라이버시 동의 상태 (통합 문서 4장: 03 동의 → 저장, 외부 전송 직전 대조).
class ConsentNotifier extends AsyncNotifier<ConsentRecord?> {
  ConsentService get _service => ref.read(consentServiceProvider);

  @override
  FutureOr<ConsentRecord?> build() async {
    final result = await _service.loadConsent();
    return switch (result) {
      Success(:final value) => value,
      Failure(:final exception) => throw exception,
    };
  }

  /// 저장된 동의가 현재 버전과 같은지. 다르면 03을 다시 보여준다.
  Future<bool> isCurrent() async {
    final version = await ref.read(currentConsentVersionProvider.future);
    return _service.isCurrent(state.value, version);
  }

  /// 03 "동의하고 시작하기". 동의 시각 · 버전을 저장한다.
  Future<Result<ConsentRecord>> accept({String userId = 'local'}) async {
    final version = await ref.read(currentConsentVersionProvider.future);
    final record = ConsentRecord(
      userId: userId,
      consentVersion: version,
      acceptedAt: DateTime.now(),
    );
    final result = await _service.saveConsent(record);
    if (result is Success) {
      state = AsyncData(record);
      return Success(record);
    }
    return Failure((result as Failure).exception);
  }

  /// 로그인 · 가입 직후: 계정 없이(`local`) 저장된 동의를 이 계정에 묶는다. 이미 다른 계정이면 그대로 둔다.
  Future<Result<void>> bindUser(String userId) async {
    final record = state.value;
    if (record == null || record.userId == userId || record.userId != 'local') {
      return const Success(null);
    }
    final bound = record.copyWith(userId: userId);
    final result = await _service.saveConsent(bound);
    if (result is Success) state = AsyncData(bound);
    return result;
  }

  Future<Result<void>> clear() async {
    final result = await _service.clearConsent();
    if (result is Success) state = const AsyncData(null);
    return result;
  }
}
