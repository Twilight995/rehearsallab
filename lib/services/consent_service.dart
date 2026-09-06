import 'package:rehearsallab/core/models/result.dart';
import 'package:rehearsallab/models/consent_record.dart';
import 'package:rehearsallab/models/provider_config.dart';

/// 프라이버시 동의. 통합 문서 4·5·9장.
/// consentVersion = hash(sttId, llmId, region, dataTypes[], policyVersion).
/// 외부 전송 직전 · 재시도 직전에 isCurrent()로 대조한다.
abstract class ConsentService {
  /// LLM에 보내는 데이터 종류 (통합 문서 5장 전송 범위 합의)
  static const List<String> dataTypes = [
    'audio->stt',
    'script->llm',
    'transcript->llm',
    'presentation_type->llm',
    'audience->llm',
    'derived_metrics->llm',
  ];

  /// 순수 계산. 제공사 미지정이면 "mock" 접두 버전을 돌려준다.
  String computeConsentVersion(ProviderConfig config);

  Future<Result<ConsentRecord?>> loadConsent();
  Future<Result<void>> saveConsent(ConsentRecord record);
  Future<Result<void>> clearConsent();

  bool isCurrent(ConsentRecord? record, String currentVersion) =>
      record != null && record.consentVersion == currentVersion;
}

/// 메모리 구현 (mock · 테스트). Phase 1에서 SharedPreferences 구현으로 교체.
class MockConsentService extends ConsentService {
  ConsentRecord? _record;

  MockConsentService({ConsentRecord? initial}) : _record = initial;

  @override
  String computeConsentVersion(ProviderConfig config) {
    final parts = [
      config.stt?.id ?? '-',
      config.llm?.id ?? '-',
      config.stt?.region ?? '-',
      config.llm?.region ?? '-',
      ConsentService.dataTypes.join(','),
      config.stt?.policyVersion ?? '-',
      config.llm?.policyVersion ?? '-',
    ];
    final digest = fnv1a64(parts.join('|'));
    return config.isConfigured ? 'c-$digest' : 'mock-$digest';
  }

  @override
  Future<Result<ConsentRecord?>> loadConsent() async => Success(_record);

  @override
  Future<Result<void>> saveConsent(ConsentRecord record) async {
    _record = record;
    return const Success(null);
  }

  @override
  Future<Result<void>> clearConsent() async {
    _record = null;
    return const Success(null);
  }
}

/// 플랫폼과 무관하게 같은 값을 내는 64비트 FNV-1a 해시 (16진수 문자열).
/// 암호학적 용도가 아니라 동의 버전 식별용이다.
String fnv1a64(String input) {
  const int prime = 0x100000001b3;
  int hash = 0xcbf29ce484222325;
  for (final unit in input.codeUnits) {
    hash ^= unit;
    hash = (hash * prime) & 0xFFFFFFFFFFFFFFFF;
  }
  final hi = (hash >>> 32) & 0xFFFFFFFF;
  final lo = hash & 0xFFFFFFFF;
  return hi.toRadixString(16).padLeft(8, '0') +
      lo.toRadixString(16).padLeft(8, '0');
}
