import 'package:flutter_test/flutter_test.dart';
import 'package:rehearsallab/core/models/result.dart';
import 'package:rehearsallab/models/consent_record.dart';
import 'package:rehearsallab/models/provider_config.dart';
import 'package:rehearsallab/services/consent_service.dart';

void main() {
  const stt = ProviderEntry(
    id: 'stt-a',
    name: 'STT A',
    region: 'KR',
    policyUrl: 'https://a',
    policyVersion: '1',
  );
  const llm = ProviderEntry(
    id: 'llm-b',
    name: 'LLM B',
    region: 'US',
    policyUrl: 'https://b',
    policyVersion: '1',
  );
  const config = ProviderConfig(stt: stt, llm: llm);

  group('동의 버전', () {
    test('같은 설정이면 항상 같은 값 (안정성)', () {
      final a = MockConsentService().computeConsentVersion(config);
      final b = MockConsentService().computeConsentVersion(config);
      expect(a, b);
      expect(a, startsWith('c-'));
    });

    test('제공사 · 지역 · 정책 버전이 바뀌면 값이 바뀐다 → 재동의 필요', () {
      final service = MockConsentService();
      final base = service.computeConsentVersion(config);
      final changedProvider = service.computeConsentVersion(
        ProviderConfig(
          stt: stt,
          llm: const ProviderEntry(
            id: 'llm-c',
            name: 'LLM C',
            region: 'US',
            policyUrl: 'https://c',
            policyVersion: '1',
          ),
        ),
      );
      final changedRegion = service.computeConsentVersion(
        ProviderConfig(
          stt: stt,
          llm: const ProviderEntry(
            id: 'llm-b',
            name: 'LLM B',
            region: 'EU',
            policyUrl: 'https://b',
            policyVersion: '1',
          ),
        ),
      );
      final changedPolicy = service.computeConsentVersion(
        ProviderConfig(
          stt: stt,
          llm: const ProviderEntry(
            id: 'llm-b',
            name: 'LLM B',
            region: 'US',
            policyUrl: 'https://b',
            policyVersion: '2',
          ),
        ),
      );
      expect(changedProvider, isNot(base));
      expect(changedRegion, isNot(base));
      expect(changedPolicy, isNot(base));
      expect(
        service.isCurrent(
          ConsentRecord(
            userId: 'u',
            consentVersion: base,
            acceptedAt: DateTime(2026),
          ),
          changedPolicy,
        ),
        isFalse,
      );
      expect(
        service.isCurrent(
          ConsentRecord(
            userId: 'u',
            consentVersion: base,
            acceptedAt: DateTime(2026),
          ),
          base,
        ),
        isTrue,
      );
    });

    test('제공사 미지정이면 mock 접두 (전송 차단 상태)', () {
      final v = MockConsentService().computeConsentVersion(
        ProviderConfig.empty,
      );
      expect(v, startsWith('mock-'));
      expect(ProviderConfig.empty.isConfigured, isFalse);
    });

    test('저장 · 불러오기 · 삭제', () async {
      final service = MockConsentService();
      expect(
        ((await service.loadConsent()) as Success<ConsentRecord?>).value,
        isNull,
      );
      final record = ConsentRecord(
        userId: 'u',
        consentVersion: 'c-1',
        acceptedAt: DateTime(2026, 9, 6),
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

    test('fnv1a64는 16자리 16진수', () {
      expect(fnv1a64('abc'), hasLength(16));
      expect(fnv1a64('abc'), isNot(fnv1a64('abd')));
    });
  });
}
