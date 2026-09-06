import 'package:rehearsallab/app/app_config.dart';
import 'package:rehearsallab/core/enum/audio_state.dart';
import 'package:rehearsallab/core/enum/match_rate_scope.dart';
import 'package:rehearsallab/core/enum/processing_stage.dart';
import 'package:rehearsallab/core/enum/retention_option.dart';
import 'package:rehearsallab/core/enum/stage_state.dart';
import 'package:rehearsallab/core/enum/transcript_state.dart';
import 'package:rehearsallab/core/models/result.dart';
import 'package:rehearsallab/models/presentation.dart';
import 'package:rehearsallab/models/rehearsal.dart';
import 'package:rehearsallab/models/report.dart';
import 'package:rehearsallab/models/script_version.dart';
import 'package:rehearsallab/services/alignment_service.dart';
import 'package:rehearsallab/services/metrics_service.dart';
import 'package:rehearsallab/services/report_interpret_service.dart';
import 'package:rehearsallab/services/script_estimate_service.dart';
import 'package:rehearsallab/services/transcript_store_service.dart';
import 'package:rehearsallab/services/transcription_service.dart';

/// 파이프라인 진행 관찰값. 단계별 상태를 그대로 노출한다 (부분 실패 원칙).
class PipelineProgress {
  final Map<ProcessingStage, StageState> stages;

  /// 단계 · 전사문 · 실패 시각이 갱신된 리허설. 저장은 호출자(처리 Notifier)가 한다.
  final Rehearsal rehearsal;

  /// 지표 · 대조가 끝나면 채워진다 (AI 실패여도 존재)
  final Report? report;
  final String? errorMessage;

  const PipelineProgress({
    required this.stages,
    required this.rehearsal,
    this.report,
    this.errorMessage,
  });

  ProcessingStage? get failedStage => ProcessingStage.values
      .cast<ProcessingStage?>()
      .firstWhere((s) => stages[s] == StageState.failed, orElse: () => null);

  bool get isFinished =>
      failedStage != null ||
      ProcessingStage.values.every((s) => stages[s] == StageState.succeeded);
}

/// 리허설 처리 5단계 (X1-4). 화면 17 · 18 · 19.
///
/// - 업로드 → 받아쓰기 → 지표 계산 → 원고 대조 → AI 해석
/// - 각 단계 성공 · 실패를 따로 보존한다. AI만 실패하면 report.ai == null인 부분 리포트를 만든다.
/// - 받아쓰기 성공 직후 전사문을 TranscriptStoreService에 저장하고 Rehearsal.transcript를 채운다.
///   7일/30일: expiresAt = 녹음 시각 + 보관 기간. 즉시 삭제: AI 성공 시 전사문 삭제, AI 실패 시 tempRetained (+24h).
/// - 전 회차 비교(prevMatchRate)는 호출자가 넘긴 `previousReport`가 있고 **두 리포트 모두 scope=full**일 때만 채운다.
/// - 실패 시각 `firstFailureAt`은 최초 실패 때만 기록한다. 시계는 주입 가능(now).
abstract class ProcessingPipelineService {
  Stream<PipelineProgress> run({
    required Rehearsal rehearsal,
    required Presentation presentation,
    required ScriptVersion script,
    required String audioFilePath,
    required RetentionOption retention,
    Report? previousReport,
  });

  /// AI 해석만 다시 시도. 전사문은 TranscriptStoreService에서 읽고, 기한이 지났으면 Failure.
  /// 성공하면 `PipelineProgress`(interpret 단계 succeeded · reportId · 전사문 상태가 갱신된 Rehearsal, ai가 채워진 Report)를
  /// 돌려주며, 즉시 삭제 옵션의 임시 전사문(tempRetained)은 여기서 삭제한다. **호출자(처리 Notifier)는 돌려받은
  /// Rehearsal과 Report를 LocalStore에 저장할 책임**이 있다. 실패하면 Rehearsal은 바뀌지 않는다(firstFailureAt 유지).
  Future<Result<PipelineProgress>> retryInterpret({
    required Rehearsal rehearsal,
    required Presentation presentation,
    required ScriptVersion script,
    required Report partialReport,
  });
}

/// Mock 서비스들을 순서대로 실행하는 Mock 파이프라인.
class MockProcessingPipelineService implements ProcessingPipelineService {
  final TranscriptionService transcription;
  final MetricsService metrics;
  final AlignmentService alignment;
  final ReportInterpretService interpret;
  final TranscriptStoreService transcriptStore;
  final ScriptEstimateService scriptEstimate;
  final Duration stepDelay;
  final DateTime Function() now;

  MockProcessingPipelineService({
    this.transcription = const MockTranscriptionService(delay: Duration.zero),
    this.metrics = const MockMetricsService(),
    this.alignment = const MockAlignmentService(),
    this.interpret = const MockReportInterpretService(delay: Duration.zero),
    TranscriptStoreService? transcriptStore,
    ScriptEstimateService? scriptEstimate,
    this.stepDelay = const Duration(milliseconds: 800),
    DateTime Function()? now,
  }) : transcriptStore = transcriptStore ?? MemoryTranscriptStoreService(),
       scriptEstimate = scriptEstimate ?? ScriptEstimateService(),
       now = now ?? DateTime.now;

  /// 두 리포트 모두 원고 전체 기준일 때만 전 회차 일치율을 돌려준다.
  static double? comparablePrevMatchRate({
    required Report? previous,
    required MatchRateScope currentScope,
  }) {
    if (previous == null) return null;
    if (currentScope != MatchRateScope.full) return null;
    if (previous.matchRateScope != MatchRateScope.full) return null;
    return previous.matchRate;
  }

  @override
  Stream<PipelineProgress> run({
    required Rehearsal rehearsal,
    required Presentation presentation,
    required ScriptVersion script,
    required String audioFilePath,
    required RetentionOption retention,
    Report? previousReport,
  }) async* {
    final stages = <ProcessingStage, StageState>{
      for (final s in ProcessingStage.values) s: StageState.pending,
    };
    var current = rehearsal;

    PipelineProgress progress({Report? report, String? error}) =>
        PipelineProgress(
          stages: Map.unmodifiable(stages),
          rehearsal: current,
          report: report,
          errorMessage: error,
        );

    Rehearsal failAt(ProcessingStage stage) {
      stages[stage] = StageState.failed;
      return current.copyWith(
        stages: Map.of(stages),
        firstFailureAt: current.firstFailureAt ?? now(),
      );
    }

    stages[ProcessingStage.upload] = StageState.running;
    yield progress();
    await Future<void>.delayed(stepDelay);
    stages[ProcessingStage.upload] = StageState.succeeded;

    stages[ProcessingStage.transcribe] = StageState.running;
    current = current.copyWith(stages: Map.of(stages));
    yield progress();
    final transcribed = await transcription.transcribe(
      audioFilePath: audioFilePath,
      provider: null,
    );
    final Transcript transcript;
    switch (transcribed) {
      case Success(:final value):
        transcript = value;
        stages[ProcessingStage.transcribe] = StageState.succeeded;
        final retentionDuration = retention.duration;
        final expiresAt = retentionDuration != null
            ? rehearsal.recordedAt.add(retentionDuration)
            : now().add(AppConfig.transcriptRetryWindow);
        await transcriptStore.save(
          rehearsalId: rehearsal.id,
          transcript: transcript,
          expiresAt: expiresAt,
        );
        current = current.copyWith(
          stages: Map.of(stages),
          transcript: TranscriptInfo(
            state: TranscriptState.stored,
            expiresAt: expiresAt,
          ),
        );
      case Failure(:final exception):
        current = failAt(ProcessingStage.transcribe);
        yield progress(error: exception.toString());
        return;
    }

    final sections = scriptEstimate.splitSections(script.text);
    final sentences = scriptEstimate.splitSentences(script.text);

    stages[ProcessingStage.metrics] = StageState.running;
    current = current.copyWith(stages: Map.of(stages));
    yield progress();
    await Future<void>.delayed(stepDelay);
    final metricsResult = metrics.compute(
      transcript: transcript,
      sections: sections,
      totalSec: rehearsal.durationSec,
      talkMinutes: presentation.talkMinutes,
    );
    final ReportMetrics reportMetrics;
    switch (metricsResult) {
      case Success(:final value):
        reportMetrics = value;
        stages[ProcessingStage.metrics] = StageState.succeeded;
      case Failure(:final exception):
        current = failAt(ProcessingStage.metrics);
        yield progress(error: exception.toString());
        return;
    }

    stages[ProcessingStage.align] = StageState.running;
    current = current.copyWith(stages: Map.of(stages));
    yield progress();
    await Future<void>.delayed(stepDelay);
    final aligned = alignment.align(
      scriptSentences: sentences,
      transcript: transcript,
      capReached: rehearsal.capReached,
    );
    final AlignmentResult alignmentResult;
    switch (aligned) {
      case Success(:final value):
        alignmentResult = value;
        stages[ProcessingStage.align] = StageState.succeeded;
      case Failure(:final exception):
        current = failAt(ProcessingStage.align);
        yield progress(error: exception.toString());
        return;
    }

    var report = Report(
      id: 'report-${rehearsal.id}',
      rehearsalId: rehearsal.id,
      metrics: reportMetrics,
      alignment: alignmentResult.sentences,
      matchRate: alignmentResult.matchRate,
      matchRateScope: alignmentResult.scope,
      prevMatchRate: comparablePrevMatchRate(
        previous: previousReport,
        currentScope: alignmentResult.scope,
      ),
      createdAt: now(),
    );

    stages[ProcessingStage.interpret] = StageState.running;
    current = current.copyWith(stages: Map.of(stages));
    yield progress(report: report);
    final interpreted = await interpret.interpret(
      presentation: presentation,
      script: script,
      transcript: transcript,
      partialReport: report,
    );
    switch (interpreted) {
      case Success(:final value):
        report = report.copyWith(ai: value);
        stages[ProcessingStage.interpret] = StageState.succeeded;
        current = current.copyWith(stages: Map.of(stages), reportId: report.id);
        if (retention == RetentionOption.immediate) {
          await transcriptStore.delete(rehearsal.id);
          current = current.copyWith(
            audio: current.audio.copyWith(state: AudioState.deleted),
            transcript: current.transcript?.copyWith(
              state: TranscriptState.deleted,
            ),
          );
        }
        yield progress(report: report);
      case Failure(:final exception):
        current = failAt(
          ProcessingStage.interpret,
        ).copyWith(reportId: report.id);
        if (retention == RetentionOption.immediate) {
          // 단일 확정 기한 = 최초 실패 시각 + 24h. 저장소와 Rehearsal에 같은 값을 적고,
          // 반복 실패(firstFailureAt 유지)에는 연장하지 않는다 (P0-REV-11).
          final deadline = current.firstFailureAt!.add(
            AppConfig.transcriptRetryWindow,
          );
          await transcriptStore.save(
            rehearsalId: rehearsal.id,
            transcript: transcript,
            expiresAt: deadline,
          );
          current = current.copyWith(
            audio: current.audio.copyWith(state: AudioState.deleted),
            transcript: current.transcript?.copyWith(
              state: TranscriptState.tempRetained,
              expiresAt: deadline,
              retryDeadlineAt: deadline,
            ),
          );
        }
        yield progress(report: report, error: exception.toString());
    }
  }

  @override
  Future<Result<PipelineProgress>> retryInterpret({
    required Rehearsal rehearsal,
    required Presentation presentation,
    required ScriptVersion script,
    required Report partialReport,
  }) async {
    final info = rehearsal.transcript;
    if (info == null || info.state == TranscriptState.deleted) {
      return Failure(
        Exception('전사문이 삭제되어 AI 해석을 다시 시도할 수 없습니다. 새 리허설이 필요합니다.'),
      );
    }
    if (!now().isBefore(info.effectiveRetryDeadline)) {
      return Failure(Exception('재시도 기한이 지났습니다. 새 리허설이 필요합니다.'));
    }
    final loaded = await transcriptStore.load(rehearsal.id);
    final Transcript transcript;
    switch (loaded) {
      case Success(:final value):
        if (value == null) {
          return Failure(Exception('보관된 전사문을 찾을 수 없습니다.'));
        }
        transcript = value;
      case Failure(:final exception):
        return Failure(exception);
    }
    final result = await interpret.interpret(
      presentation: presentation,
      script: script,
      transcript: transcript,
      partialReport: partialReport,
    );
    switch (result) {
      case Failure(:final exception):
        return Failure(exception);
      case Success(:final value):
        final report = partialReport.copyWith(ai: value);
        final stages = Map<ProcessingStage, StageState>.of(rehearsal.stages)
          ..[ProcessingStage.interpret] = StageState.succeeded;
        var updated = rehearsal.copyWith(stages: stages, reportId: report.id);
        // 즉시 삭제 옵션의 임시 전사문은 성공 · 포기 · 만료 · 발표 삭제 중 먼저 오는 시점에 지운다 (P0-REV-12).
        // 7일/30일(stored)은 성공해도 원본 만료까지 보관한다.
        if (info.state == TranscriptState.tempRetained) {
          await transcriptStore.delete(rehearsal.id);
          updated = updated.copyWith(
            transcript: info.copyWith(state: TranscriptState.deleted),
          );
        }
        return Success(
          PipelineProgress(
            stages: Map.unmodifiable(stages),
            rehearsal: updated,
            report: report,
          ),
        );
    }
  }
}
