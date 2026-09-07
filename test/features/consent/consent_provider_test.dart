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

  group('ConsentNotifier (03 동의 · 4장 대조 · 계정별 기록)', () {
    test('처음에는 기록 없음 → isCurrentFor(null) false', () async {
      final c = container();
      await c.read(consentNotifierProvider.future);
      expect(c.read(consentNotifierProvider).value, isEmpty);
      expect(c.read(consentNotifierProvider.notifier).recordFor(null), isNull);
      expect(
        await c.read(consentNotifierProvider.notifier).isCurrentFor(null),
        isFalse,
      );
    });

    test('accept → 미귀속(local) 기록 · 현재 버전 · isCurrentFor(null) true', () async {
      final c = container();
      await c.read(consentNotifierProvider.future);
      final result = await c.read(consentNotifierProvider.notifier).accept();
      expect(result, isA<Success<ConsentRecord>>());
      final version = await c.read(currentConsentVersionProvider.future);
      final record = c.read(consentNotifierProvider.notifier).recordFor(null);
      expect(record?.userId, ConsentService.unboundUserId);
      expect(record?.consentVersion, version);
      expect(
        await c.read(consentNotifierProvider.notifier).isCurrentFor(null),
        isTrue,
      );
    });

    test('accept(version)은 표시한 버전을 그대로 저장한다', () async {
      final c = container();
      await c.read(consentNotifierProvider.future);
      await c
          .read(consentNotifierProvider.notifier)
          .accept(userId: 'u-1', version: 'shown-1');
      expect(
        c
            .read(consentNotifierProvider.notifier)
            .recordFor('u-1')
            ?.consentVersion,
        'shown-1',
      );
    });

    test('다른 계정의 기록은 현재 계정의 동의가 아니다 (C1-REV-01)', () async {
      final c = container();
      await c.read(consentNotifierProvider.future);
      await c
          .read(consentNotifierProvider.notifier)
          .accept(userId: 'account-A');
      final notifier = c.read(consentNotifierProvider.notifier);
      expect(await notifier.isCurrentFor('account-A'), isTrue);
      expect(await notifier.isCurrentFor('account-B'), isFalse);
      expect(await notifier.isCurrentFor(null), isFalse);
    });

    test('계정별 기록은 서로 덮어쓰지 않는다', () async {
      final c = container();
      await c.read(consentNotifierProvider.future);
      final notifier = c.read(consentNotifierProvider.notifier);
      await notifier.accept(userId: 'account-A');
      await notifier.accept(userId: 'account-B');
      expect(c.read(consentNotifierProvider).value, hasLength(2));
      expect(await notifier.isCurrentFor('account-A'), isTrue);
      expect(await notifier.isCurrentFor('account-B'), isTrue);
    });

    test('bindUser: local 기록을 계정으로 옮기고 local은 지운다', () async {
      final service = MockConsentService();
      final c = container(service: service);
      await c.read(consentNotifierProvider.future);
      final notifier = c.read(consentNotifierProvider.notifier);
      await notifier.accept();
      expect(await notifier.bindUser('u-1'), isA<Success<void>>());
      expect(notifier.recordFor(null), isNull);
      expect(notifier.recordFor('u-1'), isNotNull);
      final stored =
          (await service.loadConsents()) as Success<List<ConsentRecord>>;
      expect(stored.value.map((r) => r.userId), ['u-1']);
    });

    test('bindUser: local 기록이 없으면 아무것도 하지 않는다 (다른 계정 기록 유지)', () async {
      final c = container();
      await c.read(consentNotifierProvider.future);
      final notifier = c.read(consentNotifierProvider.notifier);
      await notifier.accept(userId: 'account-A');
      await notifier.bindUser('account-B');
      expect(notifier.recordFor('account-A'), isNotNull);
      expect(notifier.recordFor('account-B'), isNull);
    });

    test('제공사가 바뀌면 저장된 동의는 더 이상 현재가 아니다 (재동의 필요)', () async {
      final service = MockConsentService();
      final before = container(config: ProviderConfig.empty, service: service);
      await before.read(consentNotifierProvider.future);
      await before.read(consentNotifierProvider.notifier).accept();

      final after = container(config: filled, service: service);
      await after.read(consentNotifierProvider.future);
      expect(
        after.read(consentNotifierProvider.notifier).recordFor(null),
        isNotNull,
        reason: '기록은 남아 있음',
      );
      expect(
        await after.read(consentNotifierProvider.notifier).isCurrentFor(null),
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

    test('clear(userId)는 그 계정만 지운다', () async {
      final c = container();
      await c.read(consentNotifierProvider.future);
      final notifier = c.read(consentNotifierProvider.notifier);
      await notifier.accept(userId: 'a');
      await notifier.accept(userId: 'b');
      await notifier.clear(userId: 'a');
      expect(notifier.recordFor('a'), isNull);
      expect(notifier.recordFor('b'), isNotNull);
      await notifier.clear();
      expect(c.read(consentNotifierProvider).value, isEmpty);
    });
  });

  group('PrefsConsentService (SharedPreferences)', () {
    List<ConsentRecord> valueOf(Result<List<ConsentRecord>> r) =>
        (r as Success<List<ConsentRecord>>).value;

    test('저장 · 불러오기 · 삭제 왕복 (계정 2개)', () async {
      SharedPreferences.setMockInitialValues({});
      final service = PrefsConsentService();
      expect(valueOf(await service.loadConsents()), isEmpty);
      final a = ConsentRecord(
        userId: 'a',
        consentVersion: 'c-1',
        acceptedAt: DateTime(2026, 9, 6, 12),
      );
      final b = a.copyWith(userId: 'b');
      await service.saveConsent(a);
      await service.saveConsent(b);
      expect(valueOf(await service.loadConsents()), containsAll([a, b]));
      await service.clearConsent(userId: 'a');
      expect(valueOf(await service.loadConsents()), [b]);
      await service.clearConsent();
      expect(valueOf(await service.loadConsents()), isEmpty);
    });

    test('예전 단일 키 기록을 읽어 합친다', () async {
      SharedPreferences.setMockInitialValues({
        'consent.user_id': 'local',
        'consent.version': 'old-1',
        'consent.accepted_at': DateTime(2026, 9, 1).toIso8601String(),
      });
      final service = PrefsConsentService();
      final records = valueOf(await service.loadConsents());
      expect(records.single.userId, 'local');
      expect(records.single.consentVersion, 'old-1');
      // 다시 저장하면 새 키로만 남는다
      await service.saveConsent(records.single.copyWith(userId: 'u-1'));
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('consent.version'), isNull);
      expect(valueOf(await service.loadConsents()).length, 2);
    });

    test('버전 계산은 Mock과 동일', () {
      expect(
        PrefsConsentService().computeConsentVersion(filled),
        MockConsentService().computeConsentVersion(filled),
      );
    });
  });
}
