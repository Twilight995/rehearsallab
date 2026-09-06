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
/// 파일 자체를 읽지 못하거나 형식이 깨지면 예외를 그대로 두어 03이 "불러오지 못함 · 재시도"를 보여준다.
/// Riverpod 자동 재시도는 끈다(`retry: null`) — 실패를 바로 화면에 알리고 사용자가 재시도 버튼으로 다시 읽는다.
final providerConfigProvider = FutureProvider<ProviderConfig>((ref) async {
  final raw = await rootBundle.loadString('assets/providers.json');
  if (raw.trim().isEmpty) return ProviderConfig.empty;
  return ProviderConfig.fromJson(raw);
}, retry: _noRetry);

/// 실패는 화면의 재시도 버튼으로만 복구한다 (자동 재시도 없음).
Duration? _noRetry(int retryCount, Object error) => null;

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
}, retry: _noRetry);

final consentNotifierProvider =
    AsyncNotifierProvider<ConsentNotifier, List<ConsentRecord>>(
      ConsentNotifier.new,
      retry: _noRetry,
    );

/// 프라이버시 동의 상태 (통합 문서 4장: 03 동의 → 저장, 외부 전송 직전 대조).
/// 상태는 계정별 기록 목록. 현재 계정의 기록만 유효한 동의로 본다 (C1-REV-01).
class ConsentNotifier extends AsyncNotifier<List<ConsentRecord>> {
  ConsentService get _service => ref.read(consentServiceProvider);

  @override
  FutureOr<List<ConsentRecord>> build() async {
    final result = await _service.loadConsents();
    return switch (result) {
      Success(:final value) => value,
      Failure(:final exception) => throw exception,
    };
  }

  /// userId의 기록. null이면 로그인 전 미귀속 기록(`local`).
  ConsentRecord? recordFor(String? userId) {
    final key = userId ?? ConsentService.unboundUserId;
    for (final record in state.value ?? const <ConsentRecord>[]) {
      if (record.userId == key) return record;
    }
    return null;
  }

  /// userId(없으면 미귀속)의 동의가 현재 버전과 같은지. 다르거나 없으면 03을 다시 보여준다.
  /// 기록 로드가 끝나지 않았으면 기다린다 (화면이 이 provider를 watch하지 않아도 안전).
  Future<bool> isCurrentFor(String? userId) async {
    await future;
    final version = await ref.read(currentConsentVersionProvider.future);
    return _service.isCurrent(recordFor(userId), version);
  }

  /// 03 "동의하고 시작하기". 화면에 표시한 [version]을 그대로 저장한다 (표시 버전 = 저장 버전).
  Future<Result<ConsentRecord>> accept({
    String userId = ConsentService.unboundUserId,
    String? version,
  }) async {
    final String resolved =
        version ?? (await ref.read(currentConsentVersionProvider.future));
    final record = ConsentRecord(
      userId: userId,
      consentVersion: resolved,
      acceptedAt: DateTime.now(),
    );
    final result = await _service.saveConsent(record);
    if (result case Failure(:final exception)) return Failure(exception);
    _replace(record);
    return Success(record);
  }

  /// 로그인 · 가입 직후: 미귀속(`local`) 기록이 있으면 이 계정의 기록으로 옮긴다.
  /// 미귀속 기록이 없거나 이미 같은 계정이면 아무것도 하지 않는다. 다른 계정 기록은 건드리지 않는다.
  Future<Result<void>> bindUser(String userId) async {
    try {
      await future;
    } on Object catch (e) {
      // 기록 로드 실패 → 호출자가 Result로 처리
      return Failure(e is Exception ? e : Exception(e.toString()));
    }
    final unbound = recordFor(null);
    if (unbound == null || userId == ConsentService.unboundUserId) {
      return const Success(null);
    }
    final bound = unbound.copyWith(userId: userId);
    final saved = await _service.saveConsent(bound);
    if (saved is Failure) return saved;
    final cleared = await _service.clearConsent(
      userId: ConsentService.unboundUserId,
    );
    if (cleared is Failure) return cleared;
    _replace(bound, remove: ConsentService.unboundUserId);
    return const Success(null);
  }

  Future<Result<void>> clear({String? userId}) async {
    final result = await _service.clearConsent(userId: userId);
    if (result is Success) {
      state = AsyncData(
        userId == null
            ? const []
            : [
                for (final r in state.value ?? const <ConsentRecord>[])
                  if (r.userId != userId) r,
              ],
      );
    }
    return result;
  }

  void _replace(ConsentRecord record, {String? remove}) {
    state = AsyncData([
      for (final r in state.value ?? const <ConsentRecord>[])
        if (r.userId != record.userId && r.userId != remove) r,
      record,
    ]);
  }
}
