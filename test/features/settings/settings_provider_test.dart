import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rehearsallab/core/enum/external_deletion_state.dart';
import 'package:rehearsallab/core/enum/retention_option.dart';
import 'package:rehearsallab/core/models/result.dart';
import 'package:rehearsallab/features/consent/consent_provider.dart';
import 'package:rehearsallab/features/presentation/presentation_provider.dart';
import 'package:rehearsallab/features/settings/settings_provider.dart';
import 'package:rehearsallab/models/provider_config.dart';
import 'package:rehearsallab/models/rehearsal.dart';
import 'package:rehearsallab/services/local_store_service.dart';
import 'package:rehearsallab/services/mock/demo_data.dart';
import 'package:rehearsallab/services/settings_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FailingDeleteStore extends MemoryLocalStoreService {
  _FailingDeleteStore({super.presentations});

  @override
  Future<Result<void>> deleteAll() async => Failure(Exception('disk error'));
}

void main() {
  ProviderContainer container({
    LocalStoreService? store,
    ProviderConfig config = ProviderConfig.empty,
    SettingsService? settings,
  }) {
    final c = ProviderContainer(
      overrides: [
        providerConfigProvider.overrideWith((ref) async => config),
        if (store != null) localStoreProvider.overrideWithValue(store),
        if (settings != null)
          settingsServiceProvider.overrideWithValue(settings),
      ],
    );
    addTearDown(c.dispose);
    return c;
  }

  group('보관 기간 · 외부 삭제 상태', () {
    test('기본 7일 → 30일로 변경 · 저장소 반영', () async {
      final service = MockSettingsService();
      final c = container(settings: service);
      expect(
        await c.read(retentionOptionProvider.future),
        RetentionOption.days7,
      );
      await c
          .read(retentionOptionProvider.notifier)
          .set(RetentionOption.days30);
      expect(c.read(retentionOptionProvider).value, RetentionOption.days30);
      expect(
        ((await service.loadRetention()) as Success<RetentionOption>).value,
        RetentionOption.days30,
      );
    });

    test('PrefsSettingsService 왕복 (보관 · 외부 상태 · 마지막 탭)', () async {
      SharedPreferences.setMockInitialValues({});
      final a = PrefsSettingsService();
      await a.saveRetention(RetentionOption.immediate);
      await a.saveExternalDeletion(
        const ExternalDeletion(
          stt: ExternalDeletionState.requested,
          llm: ExternalDeletionState.done,
        ),
      );
      await a.saveLastTab('p1', 'qa');
      final b = PrefsSettingsService();
      expect(
        ((await b.loadRetention()) as Success<RetentionOption>).value,
        RetentionOption.immediate,
      );
      final external =
          ((await b.loadExternalDeletion()) as Success<ExternalDeletion>).value;
      expect(external.stt, ExternalDeletionState.requested);
      expect(external.llm, ExternalDeletionState.done);
      expect(((await b.loadLastTab('p1')) as Success<String?>).value, 'qa');
      expect(((await b.loadLastTab('p2')) as Success<String?>).value, isNull);
    });
  });

  group('삭제 범위 · 영구 삭제', () {
    test('데모 데이터 집계: 발표 3 · 원고 4 · 리허설 3 · 리포트 3', () async {
      final c = container();
      await c.read(presentationsProvider.future);
      final scope = await c.read(deleteScopeProvider.future);
      expect(scope.presentations, 3);
      expect(scope.scriptVersions, 4);
      expect(scope.rehearsals, 3);
      expect(scope.reports, 3);
    });

    test('deleteAll 성공 → 목록 비움 · 제공사 미지정이면 외부 상태 "API 미지원"', () async {
      final store = MemoryLocalStoreService(
        presentations: DemoData.presentations,
        rehearsals: [DemoData.rehearsal1],
      );
      final c = container(store: store);
      await c.read(providerConfigProvider.future);
      await c.read(presentationsProvider.future);
      await c.read(externalDeletionProvider.future);
      expect(await c.read(deleteAllDataProvider)(), isA<Success<void>>());
      expect(await c.read(presentationsProvider.future), isEmpty);
      final external = c.read(externalDeletionProvider).value!;
      expect(external.stt, ExternalDeletionState.unsupported);
      expect(external.llm, ExternalDeletionState.unsupported);
      expect(
        ((await store.loadRehearsals(DemoData.presentationId))
                as Success<List<Rehearsal>>)
            .value,
        isEmpty,
      );
    });

    test('제공사가 설정돼 있으면 삭제 후 외부 상태 "요청 중"', () async {
      const config = ProviderConfig(
        stt: ProviderEntry(
          id: 's',
          name: 'S',
          region: 'KR',
          policyUrl: 'u',
          policyVersion: '1',
        ),
        llm: ProviderEntry(
          id: 'l',
          name: 'L',
          region: 'US',
          policyUrl: 'u',
          policyVersion: '1',
        ),
      );
      final c = container(store: MemoryLocalStoreService(), config: config);
      await c.read(providerConfigProvider.future);
      await c.read(presentationsProvider.future);
      await c.read(externalDeletionProvider.future);
      await c.read(deleteAllDataProvider)();
      expect(
        c.read(externalDeletionProvider).value!.stt,
        ExternalDeletionState.requested,
      );
    });

    test('deleteAll 실패 → Failure · 목록 유지 · 외부 상태 변경 없음', () async {
      final c = container(
        store: _FailingDeleteStore(presentations: DemoData.presentations),
      );
      await c.read(providerConfigProvider.future);
      await c.read(presentationsProvider.future);
      await c.read(externalDeletionProvider.future);
      expect(await c.read(deleteAllDataProvider)(), isA<Failure<void>>());
      expect(await c.read(presentationsProvider.future), hasLength(3));
      expect(
        c.read(externalDeletionProvider).value!.stt,
        ExternalDeletionState.notRequested,
      );
    });
  });
}
