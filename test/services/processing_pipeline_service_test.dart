import 'package:flutter_test/flutter_test.dart';
import 'package:rehearsallab/core/enum/processing_stage.dart';
import 'package:rehearsallab/core/enum/stage_state.dart';
import 'package:rehearsallab/core/models/result.dart';
import 'package:rehearsallab/models/report.dart';
import 'package:rehearsallab/services/mock/demo_data.dart';
import 'package:rehearsallab/services/processing_pipeline_service.dart';
import 'package:rehearsallab/services/report_interpret_service.dart';
import 'package:rehearsallab/services/transcription_service.dart';

void main() {
  final fixedNow = DateTime(2026, 9, 9, 21, 16);

  group('Mock 파이프라인', () {
    test('전부 성공 → 5단계 succeeded, report.ai 존재', () async {
      final pipeline = MockProcessingPipelineService(
        stepDelay: Duration.zero,
        now: () => fixedNow,
      );
      final progresses = await pipeline
          .run(
            rehearsal: DemoData.rehearsal3,
            presentation: DemoData.presentation,
            script: DemoData.scriptV3,
            audioFilePath: 'mock://a.m4a',
          )
          .toList();
      final last = progresses.last;
      expect(last.isFinished, isTrue);
      expect(last.failedStage, isNull);
      expect(
        last.stages.values.every((s) => s == StageState.succeeded),
        isTrue,
      );
      expect(last.report?.ai, isNotNull);
      expect(last.rehearsal.reportId, last.report!.id);
    });

    test('AI만 실패 → 부분 리포트(ai null) + firstFailureAt 기록', () async {
      final pipeline = MockProcessingPipelineService(
        stepDelay: Duration.zero,
        interpret: const MockReportInterpretService(
          delay: Duration.zero,
          failWithTimeout: true,
        ),
        now: () => fixedNow,
      );
      final last = await pipeline
          .run(
            rehearsal: DemoData.rehearsal3,
            presentation: DemoData.presentation,
            script: DemoData.scriptV3,
            audioFilePath: 'mock://a.m4a',
          )
          .last;
      expect(last.failedStage, ProcessingStage.interpret);
      expect(last.stages[ProcessingStage.align], StageState.succeeded);
      expect(last.report, isNotNull);
      expect(last.report!.ai, isNull);
      expect(last.rehearsal.firstFailureAt, fixedNow);
      expect(last.rehearsal.isAiOnlyFailure, isTrue);
      expect(last.errorMessage, contains('timeout'));
    });

    test('받아쓰기 실패 → transcribe failed, report 없음, 이후 단계 pending', () async {
      final pipeline = MockProcessingPipelineService(
        stepDelay: Duration.zero,
        transcription: const MockTranscriptionService(
          delay: Duration.zero,
          fail: true,
        ),
        now: () => fixedNow,
      );
      final last = await pipeline
          .run(
            rehearsal: DemoData.rehearsal3,
            presentation: DemoData.presentation,
            script: DemoData.scriptV3,
            audioFilePath: 'mock://a.m4a',
          )
          .last;
      expect(last.failedStage, ProcessingStage.transcribe);
      expect(last.report, isNull);
      expect(last.stages[ProcessingStage.metrics], StageState.pending);
      expect(last.rehearsal.firstFailureAt, fixedNow);
    });

    test('반복 실패해도 firstFailureAt은 갱신되지 않는다', () async {
      final earlier = DateTime(2026, 9, 9, 20);
      final pipeline = MockProcessingPipelineService(
        stepDelay: Duration.zero,
        interpret: const MockReportInterpretService(
          delay: Duration.zero,
          failWithTimeout: true,
        ),
        now: () => fixedNow,
      );
      final last = await pipeline
          .run(
            rehearsal: DemoData.rehearsal3.copyWith(firstFailureAt: earlier),
            presentation: DemoData.presentation,
            script: DemoData.scriptV3,
            audioFilePath: 'mock://a.m4a',
          )
          .last;
      expect(last.rehearsal.firstFailureAt, earlier);
    });

    test('AI 재시도 성공 → ai 채워짐', () async {
      final pipeline = MockProcessingPipelineService(stepDelay: Duration.zero);
      final result = await pipeline.retryInterpret(
        rehearsal: DemoData.rehearsal3,
        presentation: DemoData.presentation,
        script: DemoData.scriptV3,
        partialReport: DemoData.report3Partial,
      );
      expect(result, isA<Success<Report>>());
      expect((result as Success<Report>).value.ai, isNotNull);
    });
  });
}
