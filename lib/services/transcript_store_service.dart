import 'package:rehearsallab/core/models/result.dart';
import 'package:rehearsallab/services/transcription_service.dart';

/// 전체 전사문 보관소. Report에는 전체 전사문을 복사하지 않으므로(통합 문서 5장)
/// AI 해석 · 재시도에 필요한 전사문은 여기서만 읽는다.
///
/// 소유권 · 수명 (계약서 9장 합의, P0-REV-05):
/// - 저장: 처리 파이프라인이 받아쓰기 성공 직후 `save()`. expiresAt은 Rehearsal.transcript.expiresAt과 같다.
/// - 읽기: 파이프라인의 `retryInterpret()`가 `load()`로 읽고, 기한(Rehearsal.transcript.effectiveRetryDeadline)을
///   지났으면 Failure를 돌려준다. UI가 전사문을 직접 읽지 않는다.
/// - 삭제: 보관 만료 · 즉시 삭제 정책 · 발표/리허설 삭제 시 `delete()`, 주기 정리는 `purgeExpired(now)` (X2-2).
/// - Rehearsal.transcript 상태 갱신과 LocalStore 저장은 호출자(처리 Notifier)가 파이프라인 결과를 받아 수행한다.
abstract class TranscriptStoreService {
  Future<Result<void>> save({
    required String rehearsalId,
    required Transcript transcript,
    required DateTime expiresAt,
  });

  /// 없거나 만료되어 지워졌으면 null
  Future<Result<Transcript?>> load(String rehearsalId);

  Future<Result<void>> delete(String rehearsalId);

  /// now 기준 만료된 전사문을 지우고 지운 rehearsalId 목록을 돌려준다.
  Future<Result<List<String>>> purgeExpired(DateTime now);
}

/// 메모리 구현 (mock · 테스트).
class MemoryTranscriptStoreService implements TranscriptStoreService {
  final Map<String, ({Transcript transcript, DateTime expiresAt})> _entries =
      {};

  @override
  Future<Result<void>> save({
    required String rehearsalId,
    required Transcript transcript,
    required DateTime expiresAt,
  }) async {
    _entries[rehearsalId] = (transcript: transcript, expiresAt: expiresAt);
    return const Success(null);
  }

  @override
  Future<Result<Transcript?>> load(String rehearsalId) async =>
      Success(_entries[rehearsalId]?.transcript);

  @override
  Future<Result<void>> delete(String rehearsalId) async {
    _entries.remove(rehearsalId);
    return const Success(null);
  }

  @override
  Future<Result<List<String>>> purgeExpired(DateTime now) async {
    final expired = _entries.entries
        .where((e) => !e.value.expiresAt.isAfter(now))
        .map((e) => e.key)
        .toList();
    for (final id in expired) {
      _entries.remove(id);
    }
    return Success(expired);
  }

  int get length => _entries.length;
}
