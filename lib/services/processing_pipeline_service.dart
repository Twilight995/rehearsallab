import 'package:rehearsallab/core/enum/processing_stage.dart';
import 'package:rehearsallab/core/enum/stage_state.dart';
import 'package:rehearsallab/core/models/result.dart';
import 'package:rehearsallab/models/presentation.dart';
import 'package:rehearsallab/models/rehearsal.dart';
import 'package:rehearsallab/models/report.dart';
import 'package:rehearsallab/models/script_version.dart';
import 'package:rehearsallab/services/alignment_service.dart';
import 'package:rehearsallab/services/metrics_service.dart';
import 'package:rehearsallab/services/mock/demo_data.dart';
import 'package:rehearsallab/services/report_interpret_service.dart';
import 'package:rehearsallab/services/transcription_service.dart';

/// 파이프라인 진행 관찰값. 단계별 상태를 그대로 노출한다 (부분 실패 원칙).
class PipelineProgress {
  final Map<ProcessingStage, StageState> stages;
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
/// - 전송 전 실패(업로드)와 전송 후 실패(받아쓰기 타임아웃)는 Rehearsal.externalDeletion 상태가 다르다.
/// - 재시도 기한 · 보관 만료 계산은 주입 가능한 시계(now)를 쓴다 (X2-2 테스트).
abstract class ProcessingPipelineService {
  Stream<PipelineProgress> run({
    required Rehearsal rehearsal,
    required Presentation presentation,
    required ScriptVersion script,
    required String audioFilePath,
  });

  /// AI 해석만 다시 시도 (오디오 불필요, 전사문 필요).
  Future<Result<Report>> retryInterpret({
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
  final Duration stepDelay;
  final DateTime Function() now;

  MockProcessingPipelineService({
    this.transcription = const MockTranscriptionService(delay: Duration.zero),
    this.metrics = const MockMetricsService(),
    this.alignment = const MockAlignmentService(),
    this.interpret = const MockReportInterpretService(delay: Duration.zero),
    this.stepDelay = const Duration(milliseconds: 800),
    DateTime Function()? now,
  }) : now = now ?? DateTime.now;

  @override
  Stream<PipelineProgress> run({
    required Rehearsal rehearsal,
    required Presentation presentation,
    required ScriptVersion script,
    required String audioFilePath,
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
      case Failure(:final exception):
        stages[ProcessingStage.transcribe] = StageState.failed;
        current = current.copyWith(
          stages: Map.of(stages),
          firstFailureAt: current.firstFailureAt ?? now(),
        );
        yield progress(error: exception.toString());
        return;
    }

    stages[ProcessingStage.metrics] = StageState.running;
    current = current.copyWith(stages: Map.of(stages));
    yield progress();
    await Future<void>.delayed(stepDelay);
    final metricsResult = metrics.compute(
      transcript: transcript,
      sections: const [],
      totalSec: rehearsal.durationSec,
      talkMinutes: presentation.talkMinutes,
    );
    final ReportMetrics reportMetrics;
    switch (metricsResult) {
      case Success(:final value):
        reportMetrics = value;
        stages[ProcessingStage.metrics] = StageState.succeeded;
      case Failure(:final exception):
        stages[ProcessingStage.metrics] = StageState.failed;
        current = current.copyWith(
          stages: Map.of(stages),
          firstFailureAt: current.firstFailureAt ?? now(),
        );
        yield progress(error: exception.toString());
        return;
    }

    stages[ProcessingStage.align] = StageState.running;
    current = current.copyWith(stages: Map.of(stages));
    yield progress();
    await Future<void>.delayed(stepDelay);
    final aligned = alignment.align(
      scriptSentences: const [],
      transcript: transcript,
      capReached: rehearsal.capReached,
    );
    final AlignmentResult alignmentResult;
    switch (aligned) {
      case Success(:final value):
        alignmentResult = value;
        stages[ProcessingStage.align] = StageState.succeeded;
      case Failure(:final exception):
        stages[ProcessingStage.align] = StageState.failed;
        current = current.copyWith(
          stages: Map.of(stages),
          firstFailureAt: current.firstFailureAt ?? now(),
        );
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
      prevMatchRate: DemoData.report2.matchRate,
      createdAt: now(),
    );

    stages[ProcessingStage.interpret] = StageState.running;
    current = current.copyWith(stages: Map.of(stages));
    yield progress(report: report);
    final interpreted = await interpret.interpret(
      presentation: presentation,
      script: script,
      partialReport: report,
    );
    switch (interpreted) {
      case Success(:final value):
        report = report.copyWith(ai: value);
        stages[ProcessingStage.interpret] = StageState.succeeded;
        current = current.copyWith(stages: Map.of(stages), reportId: report.id);
        yield progress(report: report);
      case Failure(:final exception):
        stages[ProcessingStage.interpret] = StageState.failed;
        current = current.copyWith(
          stages: Map.of(stages),
          firstFailureAt: current.firstFailureAt ?? now(),
          reportId: report.id,
        );
        yield progress(report: report, error: exception.toString());
    }
  }

  @override
  Future<Result<Report>> retryInterpret({
    required Rehearsal rehearsal,
    required Presentation presentation,
    required ScriptVersion script,
    required Report partialReport,
  }) async {
    final result = await interpret.interpret(
      presentation: presentation,
      script: script,
      partialReport: partialReport,
    );
    return switch (result) {
      Success(:final value) => Success(partialReport.copyWith(ai: value)),
      Failure(:final exception) => Failure(exception),
    };
  }
}
