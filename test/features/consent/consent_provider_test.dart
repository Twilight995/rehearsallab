import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rehearsallab/core/models/result.dart';
import 'package:rehearsallab/features/consent/consent_provider.dart';
import 'package:rehearsallab/models/consent_record.dart';
import 'package:rehearsallab/models/provider_config.dart';
import 'package:rehearsallab/services/consent_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const filled = ProviderConfig(
    stt: ProviderEntry(
      id: 'stt-a',
      name: 'STT A',
      region: 'KR',
      policyUrl: 'https://a',
      policyVersion: '1',
    ),
    llm: ProviderEntry(
      id: 'llm-b',
      name: 'LLM B',
      region: 'US',
      policyUrl: 'https://b',
      policyVersion: '1',
    ),
  );

  ProviderContainer container({
    ProviderConfig config = ProviderConfig.empty,
    ConsentService? service,
  }) {
    final c = ProviderContainer(
      overrides: [
        providerConfigProvider.overrideWith((ref) async => config),
        if (service != null) consentServiceProvider.overrideWithValue(service),
      ],
    );
    addTearDown(c.dispose);
    return c;
  }

  group('ConsentNotifier (03 동의 · 4장 대조)', () {
    test('처음에는 동의 없음 → isCurrent false', () async {
      final c = container();
      await c.read(consentNotifierProvider.future);
      expect(c.read(consentNotifierProvider).value, isNull);
      expect(
        await c.read(consentNotifierProvider.notifier).isCurrent(),
        isFalse,
      );
    });

    test('accept → 현재 버전으로 저장 · isCurrent true', () async {
      final c = container();
      await c.read(consentNotifierProvider.future);
      final result = await c.read(consentNotifierProvider.notifier).accept();
      expect(result, isA<Success<ConsentRecord>>());
      final version = await c.read(currentConsentVersionProvider.future);
      expect(c.read(consentNotifierProvider).value?.consentVersion, version);
      expect(
        await c.read(consentNotifierProvider.notifier).isCurrent(),
        isTrue,
      );
    });

    test('제공사가 바뀌면 저장된 동의는 더 이상 현재가 아니다 (재동의 필요)', () async {
      final service = MockConsentService();
      final before = container(config: ProviderConfig.empty, service: service);
      await before.read(consentNotifierProvider.future);
      await before.read(consentNotifierProvider.notifier).accept();

      final after = container(config: filled, service: service);
      await after.read(consentNotifierProvider.future);
      expect(
        after.read(consentNotifierProvider).value,
        isNotNull,
        reason: '기록은 남아 있음',
      );
      expect(
        await after.read(consentNotifierProvider.notifier).isCurrent(),
        isFalse,
      );
    });

    test('mock 모드 · 제공사 미지정이면 버전이 mock- 접두', () async {
      final c = container();
      expect(
        await c.read(currentConsentVersionProvider.future),
        startsWith('mock-'),
      );
    });
  });

  group('PrefsConsentService (SharedPreferences)', () {
    test('저장 · 불러오기 · 삭제 왕복', () async {
      SharedPreferences.setMockInitialValues({});
      final service = PrefsConsentService();
      expect(
        ((await service.loadConsent()) as Success<ConsentRecord?>).value,
        isNull,
      );
      final record = ConsentRecord(
        userId: 'u',
        consentVersion: 'c-1',
        acceptedAt: DateTime(2026, 9, 6, 12),
      );
      await service.saveConsent(record);
      expect(
        ((await service.loadConsent()) as Success<ConsentRecord?>).value,
        record,
      );
      await service.clearConsent();
      expect(
        ((await service.loadConsent()) as Success<ConsentRecord?>).value,
        isNull,
      );
    });

    test('버전 계산은 Mock과 동일', () {
      expect(
        PrefsConsentService().computeConsentVersion(filled),
        MockConsentService().computeConsentVersion(filled),
      );
    });
  });
}
