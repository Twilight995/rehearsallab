import 'dart:convert';

import 'package:rehearsallab/core/models/result.dart';
import 'package:rehearsallab/models/consent_record.dart';
import 'package:rehearsallab/models/provider_config.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 프라이버시 동의. 통합 문서 4·5·9장.
/// consentVersion = hash(sttId, llmId, region, dataTypes[], policyVersion).
/// 외부 전송 직전 · 재시도 직전에 isCurrent()로 대조한다.
///
/// 기록은 **계정별**로 보관한다(userId 하나에 기록 하나). 로그인 전 03에서 한 동의는
/// [unboundUserId]로 저장했다가 최초 로그인 · 가입 계정에 묶는다(ConsentNotifier.bindUser).
/// 다른 계정의 기록은 현재 계정의 동의로 인정하지 않는다 (C1-REV-01).
abstract class ConsentService {
  /// 로그인 전 저장된 미귀속 동의의 userId
  static const String unboundUserId = 'local';

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

  /// 저장된 모든 기록 (계정당 하나).
  Future<Result<List<ConsentRecord>>> loadConsents();

  /// 같은 userId가 있으면 덮어쓴다.
  Future<Result<void>> saveConsent(ConsentRecord record);

  /// userId를 주면 그 기록만, 없으면 전부 지운다.
  Future<Result<void>> clearConsent({String? userId});

  bool isCurrent(ConsentRecord? record, String currentVersion) =>
      record != null && record.consentVersion == currentVersion;
}

/// 메모리 구현 (mock · 테스트).
class MockConsentService extends ConsentService {
  final Map<String, ConsentRecord> _records = {};

  MockConsentService({ConsentRecord? initial}) {
    if (initial != null) _records[initial.userId] = initial;
  }

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
  Future<Result<List<ConsentRecord>>> loadConsents() async =>
      Success(List.unmodifiable(_records.values));

  @override
  Future<Result<void>> saveConsent(ConsentRecord record) async {
    _records[record.userId] = record;
    return const Success(null);
  }

  @override
  Future<Result<void>> clearConsent({String? userId}) async {
    if (userId == null) {
      _records.clear();
    } else {
      _records.remove(userId);
    }
    return const Success(null);
  }
}

/// SharedPreferences 구현 (live 모드, C1-1). 키 `consent.records`에 JSON 배열.
/// 예전 단일 키(`consent.user_id/version/accepted_at`)가 남아 있으면 읽어서 합친다.
class PrefsConsentService extends ConsentService {
  static const String recordsKey = 'consent.records';
  static const String _legacyUser = 'consent.user_id';
  static const String _legacyVersion = 'consent.version';
  static const String _legacyAcceptedAt = 'consent.accepted_at';

  final Future<SharedPreferences> Function() _prefs;

  PrefsConsentService({Future<SharedPreferences> Function()? prefs})
    : _prefs = prefs ?? SharedPreferences.getInstance;

  @override
  String computeConsentVersion(ProviderConfig config) =>
      MockConsentService().computeConsentVersion(config);

  Future<Map<String, ConsentRecord>> _read(SharedPreferences p) async {
    final records = <String, ConsentRecord>{};
    final legacyVersion = p.getString(_legacyVersion);
    final legacyAcceptedAt = p.getString(_legacyAcceptedAt);
    if (legacyVersion != null && legacyAcceptedAt != null) {
      final legacy = ConsentRecord(
        userId: p.getString(_legacyUser) ?? ConsentService.unboundUserId,
        consentVersion: legacyVersion,
        acceptedAt: DateTime.parse(legacyAcceptedAt),
      );
      records[legacy.userId] = legacy;
    }
    final raw = p.getString(recordsKey);
    if (raw != null && raw.isNotEmpty) {
      for (final item in json.decode(raw) as List<dynamic>) {
        final record = ConsentRecord.fromMap(item as Map<String, dynamic>);
        records[record.userId] = record;
      }
    }
    return records;
  }

  Future<void> _write(
    SharedPreferences p,
    Map<String, ConsentRecord> records,
  ) async {
    await p.setString(
      recordsKey,
      json.encode([for (final r in records.values) r.toMap()]),
    );
    await p.remove(_legacyUser);
    await p.remove(_legacyVersion);
    await p.remove(_legacyAcceptedAt);
  }

  @override
  Future<Result<List<ConsentRecord>>> loadConsents() async {
    try {
      final records = await _read(await _prefs());
      return Success(List.unmodifiable(records.values));
    } on Exception catch (e) {
      return Failure(e);
    }
  }

  @override
  Future<Result<void>> saveConsent(ConsentRecord record) async {
    try {
      final p = await _prefs();
      final records = await _read(p);
      records[record.userId] = record;
      await _write(p, records);
      return const Success(null);
    } on Exception catch (e) {
      return Failure(e);
    }
  }

  @override
  Future<Result<void>> clearConsent({String? userId}) async {
    try {
      final p = await _prefs();
      if (userId == null) {
        await _write(p, {});
        await p.remove(recordsKey);
        return const Success(null);
      }
      final records = await _read(p);
      records.remove(userId);
      await _write(p, records);
      return const Success(null);
    } on Exception catch (e) {
      return Failure(e);
    }
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
