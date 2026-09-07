import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rehearsallab/app/app_config.dart';
import 'package:rehearsallab/core/enum/app_mode.dart';
import 'package:rehearsallab/core/enum/external_deletion_state.dart';
import 'package:rehearsallab/core/enum/retention_option.dart';
import 'package:rehearsallab/core/models/result.dart';
import 'package:rehearsallab/features/consent/consent_provider.dart';
import 'package:rehearsallab/features/presentation/presentation_provider.dart';
import 'package:rehearsallab/models/rehearsal.dart';
import 'package:rehearsallab/services/settings_service.dart';

/// mock 모드는 메모리, live 모드는 SharedPreferences (C1-4).
final settingsServiceProvider = Provider<SettingsService>((ref) {
  return ref.watch(appModeProvider) == AppMode.mock
      ? MockSettingsService()
      : PrefsSettingsService();
});

final retentionOptionProvider =
    AsyncNotifierProvider<RetentionOptionNotifier, RetentionOption>(
      RetentionOptionNotifier.new,
      retry: (retryCount, error) => null,
    );

/// 09 "녹음 · 전사문 보관 기간". 기본 7일. 변경은 이후 녹음부터 적용된다.
class RetentionOptionNotifier extends AsyncNotifier<RetentionOption> {
  @override
  FutureOr<RetentionOption> build() async {
    final result = await ref.read(settingsServiceProvider).loadRetention();
    return switch (result) {
      Success(:final value) => value,
      Failure(:final exception) => throw exception,
    };
  }

  Future<Result<void>> set(RetentionOption option) async {
    final result = await ref
        .read(settingsServiceProvider)
        .saveRetention(option);
    if (result is Success) state = AsyncData(option);
    return result;
  }
}

final externalDeletionProvider =
    AsyncNotifierProvider<ExternalDeletionNotifier, ExternalDeletion>(
      ExternalDeletionNotifier.new,
      retry: (retryCount, error) => null,
    );

/// 09 "외부 보관 · 삭제 상태" (STT · LLM 각각). 32 영구 삭제 뒤 갱신된다.
class ExternalDeletionNotifier extends AsyncNotifier<ExternalDeletion> {
  @override
  FutureOr<ExternalDeletion> build() async {
    final result = await ref
        .read(settingsServiceProvider)
        .loadExternalDeletion();
    return switch (result) {
      Success(:final value) => value,
      Failure(:final exception) => throw exception,
    };
  }

  Future<Result<void>> set(ExternalDeletion status) async {
    final result = await ref
        .read(settingsServiceProvider)
        .saveExternalDeletion(status);
    if (result is Success) state = AsyncData(status);
    return result;
  }
}

/// 31 · 32 "삭제되는 데이터" 집계
class DeleteScope {
  final int presentations;
  final int scriptVersions;
  final int rehearsals;
  final int reports;

  const DeleteScope({
    required this.presentations,
    required this.scriptVersions,
    required this.rehearsals,
    required this.reports,
  });
}

final deleteScopeProvider = FutureProvider<DeleteScope>((ref) async {
  final store = ref.read(localStoreProvider);
  final presentations = await ref.watch(presentationsProvider.future);
  var versions = 0;
  var rehearsals = 0;
  var reports = 0;
  for (final p in presentations) {
    versions += switch (await store.loadScriptVersions(p.id)) {
      Success(:final value) => value.length,
      Failure(:final exception) => throw exception,
    };
    final list = switch (await store.loadRehearsals(p.id)) {
      Success(:final value) => value,
      Failure(:final exception) => throw exception,
    };
    rehearsals += list.length;
    reports += list.where((r) => r.reportId != null).length;
  }
  return DeleteScope(
    presentations: presentations.length,
    scriptVersions: versions,
    rehearsals: rehearsals,
    reports: reports,
  );
}, retry: (retryCount, error) => null);

/// 32 "영구 삭제": 로컬 저장소 전부 삭제 → 외부 제공사 삭제 요청 상태 갱신 → 목록 재조회.
/// 실패하면 지워진 척하지 않고 Failure를 돌려준다 (통합 문서 4장). 계정 · 동의 기록은 유지한다.
final deleteAllDataProvider = Provider<Future<Result<void>> Function()>((ref) {
  return () async {
    final result = await ref.read(localStoreProvider).deleteAll();
    if (result is Failure) return result;
    // 외부 제공사: 실제 삭제 API가 없으므로 제공사 미지정이면 "API 미지원", 설정돼 있으면 "요청 중"으로 둔다
    final config = ref.read(providerConfigProvider).value;
    final stt = config?.stt == null
        ? ExternalDeletionState.unsupported
        : ExternalDeletionState.requested;
    final llm = config?.llm == null
        ? ExternalDeletionState.unsupported
        : ExternalDeletionState.requested;
    await ref
        .read(externalDeletionProvider.notifier)
        .set(ExternalDeletion(stt: stt, llm: llm));
    ref.invalidate(presentationsProvider);
    ref.invalidate(homeCardsProvider);
    ref.invalidate(deleteScopeProvider);
    return const Success(null);
  };
});

/// 발표별 "마지막에 보던 탭" (통합 문서 4장 07 → 상세). 값은 DetailTab.name.
final lastDetailTabProvider = FutureProvider.family<String?, String>((
  ref,
  presentationId,
) async {
  final result = await ref
      .read(settingsServiceProvider)
      .loadLastTab(presentationId);
  return switch (result) {
    Success(:final value) => value,
    Failure() => null,
  };
}, retry: (retryCount, error) => null);
