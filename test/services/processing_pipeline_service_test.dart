import 'package:flutter_test/flutter_test.dart';
import 'package:rehearsallab/core/enum/audio_state.dart';
import 'package:rehearsallab/core/enum/match_rate_scope.dart';
import 'package:rehearsallab/core/enum/processing_stage.dart';
import 'package:rehearsallab/core/enum/rehearsal_scope.dart';
import 'package:rehearsallab/core/enum/retention_option.dart';
import 'package:rehearsallab/core/enum/stage_state.dart';
import 'package:rehearsallab/core/enum/transcript_state.dart';
import 'package:rehearsallab/core/models/result.dart';
import 'package:rehearsallab/models/presentation.dart';
import 'package:rehearsallab/models/rehearsal.dart';
import 'package:rehearsallab/models/report.dart';
import 'package:rehearsallab/models/script_version.dart';
import 'package:rehearsallab/services/mock/demo_data.dart';
import 'package:rehearsallab/services/processing_pipeline_service.dart';
import 'package:rehearsallab/services/report_interpret_service.dart';
import 'package:rehearsallab/services/transcript_store_service.dart';
import 'package:rehearsallab/services/transcription_service.dart';

/// 해석 호출 시점에 시계를 앞으로 돌린 뒤 실패하는 Mock (단계 사이 경과 시간 재현).
class _FailAfterAdvancing implements ReportInterpretService {
  final void Function() advance;

  const _FailAfterAdvancing(this.advance);

  @override
  Future<Result<AiFeedback>> interpret({
    required Presentation presentation,
    required ScriptVersion script,
    required Transcript transcript,
    required Report partialReport,
  }) async {
    advance();
    return Failure(Exception('제공사 응답 시간 초과 (timeout 20초)'));
  }
}

void main() {
  final fixedNow = DateTime(2026, 9, 9, 21, 16);
  final recordedAt = DemoData.rehearsal3.recordedAt;

  /// 처리 전 상태의 리허설 (전사문 없음 · 기기 녹음)
  Rehearsal fresh({bool capReached = false}) => Rehearsal(
    id: 'r-new',
    presentationId: DemoData.presentationId,
    scriptVersionId: DemoData.scriptV3Id,
    round: 4,
    recordedAt: recordedAt,
    durationSec: 760,
    teleprompterOn: true,
    capReached: capReached,
    scope: capReached ? RehearsalScope.partial : RehearsalScope.full,
    audio: const AudioInfo(state: AudioState.localOnly),
    stages: {for (final s in ProcessingStage.values) s: StageState.pending},
    consentVersion: DemoData.consentVersion,
  );

  MockProcessingPipelineService pipeline({
    ReportInterpretService? interpret,
    TranscriptionService? transcription,
    MemoryTranscriptStoreService? store,
    DateTime Function()? now,
  }) => MockProcessingPipelineService(
    stepDelay: Duration.zero,
    interpret:
        interpret ?? const MockReportInterpretService(delay: Duration.zero),
    transcription:
        transcription ?? const MockTranscriptionService(delay: Duration.zero),
    transcriptStore: store,
    now: now ?? () => fixedNow,
  );

  Future<PipelineProgress> runLast(
    MockProcessingPipelineService p, {
    Rehearsal? rehearsal,
    RetentionOption retention = RetentionOption.days7,
    Report? previous,
  }) => p
      .run(
        rehearsal: rehearsal ?? fresh(),
        presentation: DemoData.presentation,
        script: DemoData.scriptV3,
        audioFilePath: 'mock://a.m4a',
        retention: retention,
        previousReport: previous,
      )
      .last;

  const failing = MockReportInterpretService(
    delay: Duration.zero,
    failWithTimeout: true,
  );

  group('Mock 파이프라인 · 단계 상태', () {
    test(
      '전부 성공 (7일) → 5단계 succeeded, ai 존재, 전사문 stored · 만료 = 녹음+7일',
      () async {
        final store = MemoryTranscriptStoreService();
        final last = await runLast(pipeline(store: store));
        expect(last.isFinished, isTrue);
        expect(last.failedStage, isNull);
        expect(last.report?.ai, isNotNull);
        expect(last.rehearsal.reportId, last.report!.id);
        expect(last.rehearsal.transcript?.state, TranscriptState.stored);
        expect(
          last.rehearsal.transcript?.expiresAt,
          recordedAt.add(const Duration(days: 7)),
        );
        expect(store.length, 1);
      },
    );

    test(
      'AI만 실패 (7일) → 부분 리포트(ai null), firstFailureAt, 재시도 기한 = 원본 만료',
      () async {
        final last = await runLast(pipeline(interpret: failing));
        expect(last.failedStage, ProcessingStage.interpret);
        expect(last.stages[ProcessingStage.align], StageState.succeeded);
        expect(last.report, isNotNull);
        expect(last.report!.ai, isNull);
        expect(last.rehearsal.firstFailureAt, fixedNow);
        expect(last.rehearsal.isAiOnlyFailure, isTrue);
        expect(last.rehearsal.transcript?.state, TranscriptState.stored);
        expect(last.rehearsal.transcript?.retryDeadlineAt, isNull);
        expect(
          last.rehearsal.transcript?.effectiveRetryDeadline,
          recordedAt.add(const Duration(days: 7)),
        );
        expect(last.errorMessage, contains('timeout'));
      },
    );

    test(
      '즉시 삭제 + AI 실패 → 오디오 deleted, 전사문 tempRetained · 기한 = 최초 실패 + 24h',
      () async {
        final last = await runLast(
          pipeline(interpret: failing),
          retention: RetentionOption.immediate,
        );
        expect(last.rehearsal.audio.state, AudioState.deleted);
        expect(last.rehearsal.transcript?.state, TranscriptState.tempRetained);
        expect(
          last.rehearsal.transcript?.retryDeadlineAt,
          fixedNow.add(const Duration(hours: 24)),
        );
      },
    );

    test('즉시 삭제 + 전부 성공 → 오디오 · 전사문 삭제, 저장소 비움', () async {
      final store = MemoryTranscriptStoreService();
      final last = await runLast(
        pipeline(store: store),
        retention: RetentionOption.immediate,
      );
      expect(last.report?.ai, isNotNull);
      expect(last.rehearsal.audio.state, AudioState.deleted);
      expect(last.rehearsal.transcript?.state, TranscriptState.deleted);
      expect(store.length, 0);
    });

    test(
      '받아쓰기 실패 → transcribe failed, report 없음, 전사문 없음, 이후 단계 pending',
      () async {
        final last = await runLast(
          pipeline(
            transcription: const MockTranscriptionService(
              delay: Duration.zero,
              fail: true,
            ),
          ),
        );
        expect(last.failedStage, ProcessingStage.transcribe);
        expect(last.report, isNull);
        expect(last.rehearsal.transcript, isNull);
        expect(last.stages[ProcessingStage.metrics], StageState.pending);
        expect(last.rehearsal.firstFailureAt, fixedNow);
      },
    );

    test('반복 실패해도 firstFailureAt은 갱신되지 않는다', () async {
      final earlier = DateTime(2026, 9, 9, 20);
      final last = await runLast(
        pipeline(interpret: failing),
        rehearsal: fresh().copyWith(firstFailureAt: earlier),
      );
      expect(last.rehearsal.firstFailureAt, earlier);
    });
  });

  group('전 회차 비교 (P0-REV-06)', () {
    test('첫 회차 → prevMatchRate null', () async {
      final last = await runLast(pipeline());
      expect(last.report!.prevMatchRate, isNull);
      expect(last.report!.matchRateDeltaPp, isNull);
    });

    test('전 회차 full + 이번 full → 전 회차 값', () async {
      final last = await runLast(pipeline(), previous: DemoData.report2);
      expect(last.report!.matchRateScope, MatchRateScope.full);
      expect(last.report!.prevMatchRate, DemoData.report2.matchRate);
    });

    test('부분 리허설(capReached) → scope reached, prevMatchRate null', () async {
      final last = await runLast(
        pipeline(),
        rehearsal: fresh(capReached: true),
        previous: DemoData.report2,
      );
      expect(last.report!.matchRateScope, MatchRateScope.reached);
      expect(last.report!.prevMatchRate, isNull);
    });

    test('전 회차가 부분 리허설이면 이번이 full이어도 null', () {
      final prevPartial = DemoData.report2.copyWith(
        matchRateScope: MatchRateScope.reached,
      );
      expect(
        MockProcessingPipelineService.comparablePrevMatchRate(
          previous: prevPartial,
          currentScope: MatchRateScope.full,
        ),
        isNull,
      );
    });
  });

  group('즉시 삭제 옵션 전사문 기한 (P0-REV-11)', () {
    test('단계 사이에 시간이 흐르면 저장소 만료 = 화면 기한 = 최초 실패 + 24h', () async {
      // 받아쓰기 21:16:00, AI 실패 21:16:20 → 기한은 21:16:20 + 24h 하나뿐이어야 한다.
      var clock = DateTime(2026, 9, 9, 21, 16, 0);
      final store = MemoryTranscriptStoreService();
      final p = MockProcessingPipelineService(
        stepDelay: Duration.zero,
        transcription: const MockTranscriptionService(delay: Duration.zero),
        interpret: _FailAfterAdvancing(
          () => clock = clock.add(const Duration(seconds: 20)),
        ),
        transcriptStore: store,
        now: () => clock,
      );
      final last = await runLast(p, retention: RetentionOption.immediate);
      final deadline = DateTime(
        2026,
        9,
        9,
        21,
        16,
        20,
      ).add(const Duration(hours: 24));
      expect(last.rehearsal.firstFailureAt, DateTime(2026, 9, 9, 21, 16, 20));
      expect(last.rehearsal.transcript?.retryDeadlineAt, deadline);
      expect(last.rehearsal.transcript?.expiresAt, deadline);
      // 정확한 만료 경계: 기한 1초 전에는 남고, 기한 도달 시 삭제
      final keep =
          (await store.purgeExpired(
                    deadline.subtract(const Duration(seconds: 1)),
                  )
                  as Success<List<String>>)
              .value;
      expect(keep, isEmpty);
      expect(store.length, 1);
      final purged =
          (await store.purgeExpired(deadline) as Success<List<String>>).value;
      expect(purged, ['r-new']);
    });

    test('반복 실패해도 기한은 최초 실패 기준으로 연장되지 않는다 (저장소 · Rehearsal 동일)', () async {
      final earlier = DateTime(2026, 9, 9, 20);
      final store = MemoryTranscriptStoreService();
      final last = await runLast(
        pipeline(interpret: failing, store: store),
        rehearsal: fresh().copyWith(firstFailureAt: earlier),
        retention: RetentionOption.immediate,
      );
      final deadline = earlier.add(const Duration(hours: 24));
      expect(last.rehearsal.transcript?.retryDeadlineAt, deadline);
      final purged =
          (await store.purgeExpired(deadline) as Success<List<String>>).value;
      expect(purged, ['r-new'], reason: '저장소 만료도 같은 기한');
    });
  });

  group('AI 재시도 (P0-REV-05 전사문 경로 · P0-REV-12 정리 책임)', () {
    test(
      '7일 옵션(stored): 재시도 성공 → ai 채워짐, 단계 succeeded, 전사문은 원본 만료까지 보관',
      () async {
        final store = MemoryTranscriptStoreService();
        final p = pipeline(store: store);
        await store.save(
          rehearsalId: DemoData.rehearsal3.id,
          transcript: MockTranscriptionService.demoTranscript,
          expiresAt: DateTime(2026, 9, 16),
        );
        final failed = DemoData.rehearsal3.copyWith(
          stages: {
            ...DemoData.rehearsal3.stages,
            ProcessingStage.interpret: StageState.failed,
          },
        );
        final result = await p.retryInterpret(
          rehearsal: failed,
          presentation: DemoData.presentation,
          script: DemoData.scriptV3,
          partialReport: DemoData.report3Partial,
        );
        expect(result, isA<Success<PipelineProgress>>());
        final progress = (result as Success<PipelineProgress>).value;
        expect(progress.report?.ai, isNotNull);
        expect(
          progress.stages[ProcessingStage.interpret],
          StageState.succeeded,
        );
        expect(progress.rehearsal.reportId, progress.report!.id);
        expect(progress.rehearsal.transcript?.state, TranscriptState.stored);
        expect(store.length, 1, reason: '7일 옵션은 성공해도 조기 삭제하지 않는다');
      },
    );

    test('즉시 삭제 옵션(tempRetained): 재시도 성공 → 임시 전사문 삭제, 상태 deleted', () async {
      final store = MemoryTranscriptStoreService();
      final p = pipeline(store: store);
      final deadline = DateTime(2026, 9, 10, 21, 16);
      await store.save(
        rehearsalId: DemoData.rehearsal3.id,
        transcript: MockTranscriptionService.demoTranscript,
        expiresAt: deadline,
      );
      final temp = DemoData.rehearsal3.copyWith(
        stages: {
          ...DemoData.rehearsal3.stages,
          ProcessingStage.interpret: StageState.failed,
        },
        transcript: TranscriptInfo(
          state: TranscriptState.tempRetained,
          expiresAt: deadline,
          retryDeadlineAt: deadline,
        ),
      );
      final result = await p.retryInterpret(
        rehearsal: temp,
        presentation: DemoData.presentation,
        script: DemoData.scriptV3,
        partialReport: DemoData.report3Partial,
      );
      final progress = (result as Success<PipelineProgress>).value;
      expect(progress.report?.ai, isNotNull);
      expect(progress.rehearsal.transcript?.state, TranscriptState.deleted);
      expect(
        ((await store.load(DemoData.rehearsal3.id)) as Success).value,
        isNull,
      );
      expect(store.length, 0);
    });

    test('재시도 실패 → Failure, Rehearsal 미변경 · 전사문 유지', () async {
      final store = MemoryTranscriptStoreService();
      final p = pipeline(store: store, interpret: failing);
      await store.save(
        rehearsalId: DemoData.rehearsal3.id,
        transcript: MockTranscriptionService.demoTranscript,
        expiresAt: DateTime(2026, 9, 16),
      );
      final result = await p.retryInterpret(
        rehearsal: DemoData.rehearsal3,
        presentation: DemoData.presentation,
        script: DemoData.scriptV3,
        partialReport: DemoData.report3Partial,
      );
      expect(result, isA<Failure<PipelineProgress>>());
      expect(store.length, 1);
    });

    test('재시도 기한 경과 → Failure (전사문 있어도)', () async {
      final store = MemoryTranscriptStoreService();
      final p = pipeline(store: store, now: () => DateTime(2026, 9, 17));
      await store.save(
        rehearsalId: DemoData.rehearsal3.id,
        transcript: MockTranscriptionService.demoTranscript,
        expiresAt: DateTime(2026, 9, 16),
      );
      final result = await p.retryInterpret(
        rehearsal: DemoData.rehearsal3,
        presentation: DemoData.presentation,
        script: DemoData.scriptV3,
        partialReport: DemoData.report3Partial,
      );
      expect(result, isA<Failure<PipelineProgress>>());
      expect(
        (result as Failure<PipelineProgress>).exception.toString(),
        contains('기한'),
      );
    });

    test('전사문 삭제됨 → Failure, 새 리허설 안내', () async {
      final p = pipeline();
      final deleted = DemoData.rehearsal3.copyWith(
        transcript: DemoData.rehearsal3.transcript!.copyWith(
          state: TranscriptState.deleted,
        ),
      );
      final result = await p.retryInterpret(
        rehearsal: deleted,
        presentation: DemoData.presentation,
        script: DemoData.scriptV3,
        partialReport: DemoData.report3Partial,
      );
      expect(result, isA<Failure<PipelineProgress>>());
      expect(
        (result as Failure<PipelineProgress>).exception.toString(),
        contains('새 리허설'),
      );
    });

    test('purgeExpired는 만료된 전사문만 지운다', () async {
      final store = MemoryTranscriptStoreService();
      await store.save(
        rehearsalId: 'old',
        transcript: MockTranscriptionService.demoTranscript,
        expiresAt: DateTime(2026, 9, 1),
      );
      await store.save(
        rehearsalId: 'new',
        transcript: MockTranscriptionService.demoTranscript,
        expiresAt: DateTime(2026, 9, 30),
      );
      final purged =
          (await store.purgeExpired(DateTime(2026, 9, 9))
                  as Success<List<String>>)
              .value;
      expect(purged, ['old']);
      expect(store.length, 1);
    });
  });
}
