import 'package:flutter_test/flutter_test.dart';
import 'package:rehearsallab/core/enum/audio_state.dart';
import 'package:rehearsallab/core/enum/external_deletion_state.dart';
import 'package:rehearsallab/core/enum/match_rate_scope.dart';
import 'package:rehearsallab/core/enum/processing_stage.dart';
import 'package:rehearsallab/core/enum/rehearsal_scope.dart';
import 'package:rehearsallab/core/enum/report_mode.dart';
import 'package:rehearsallab/core/enum/sentence_state.dart';
import 'package:rehearsallab/core/enum/stage_state.dart';
import 'package:rehearsallab/core/enum/transcript_state.dart';
import 'package:rehearsallab/models/consent_record.dart';
import 'package:rehearsallab/models/presentation.dart';
import 'package:rehearsallab/models/provider_config.dart';
import 'package:rehearsallab/models/rehearsal.dart';
import 'package:rehearsallab/models/report.dart';
import 'package:rehearsallab/models/script_analysis.dart';
import 'package:rehearsallab/models/script_version.dart';
import 'package:rehearsallab/services/mock/demo_data.dart';

void main() {
  group('모델 직렬화 왕복 (toJson → fromJson 동일)', () {
    test('Presentation · 날짜 없음(날짜 미정) · Q&A 0분', () {
      final p = DemoData.presentations[2].copyWith(qaMinutes: 0);
      expect(p.date, isNull);
      expect(Presentation.fromJson(p.toJson()), p);
      expect(p.timeSpecLabel, '30분');
      expect(DemoData.presentation.timeSpecLabel, '15분 + Q&A 5분');
      expect(
        Presentation.fromJson(DemoData.presentation.toJson()),
        DemoData.presentation,
      );
    });

    test('ScriptVersion v1 → v2 → v3 부모 연결', () {
      for (final v in [
        DemoData.scriptV1,
        DemoData.scriptV2,
        DemoData.scriptV3,
      ]) {
        expect(ScriptVersion.fromJson(v.toJson()), v);
      }
      expect(DemoData.scriptV2.parentVersionId, DemoData.scriptV1.id);
      expect(DemoData.scriptV3.parentVersionId, DemoData.scriptV2.id);
      expect(DemoData.scriptV3.version, 3);
    });

    test('ScriptAnalysis (3차원 · 4리라이트 · 5섹션)', () {
      final a = DemoData.analysisV1;
      expect(ScriptAnalysis.fromJson(a.toJson()), a);
      expect(a.dimensions.length, 3);
      expect(a.rewrites.length, 4);
      expect(a.appliedRewriteCount, 1);
      expect(a.estimatedTotalSeconds, 880); // 14:40
    });

    test('Rehearsal 전부 성공 · transcript 있음', () {
      final r = DemoData.rehearsal3;
      expect(Rehearsal.fromJson(r.toJson()), r);
      expect(r.allStagesSucceeded, isTrue);
      expect(r.isAiOnlyFailure, isFalse);
    });

    test(
      'Rehearsal 받아쓰기 전 (transcript null · externalDeletion notRequested)',
      () {
        final r = DemoData.rehearsal3.copyWith(
          stages: {
            ProcessingStage.upload: StageState.running,
            for (final s in ProcessingStage.values.skip(1))
              s: StageState.pending,
          },
        );
        final fresh = Rehearsal(
          id: r.id,
          presentationId: r.presentationId,
          scriptVersionId: r.scriptVersionId,
          round: r.round,
          recordedAt: r.recordedAt,
          durationSec: r.durationSec,
          teleprompterOn: true,
          audio: const AudioInfo(state: AudioState.localOnly),
          stages: r.stages,
          consentVersion: r.consentVersion,
        );
        final back = Rehearsal.fromJson(fresh.toJson());
        expect(back, fresh);
        expect(back.transcript, isNull);
        expect(back.externalDeletion.stt, ExternalDeletionState.notRequested);
        expect(back.providerSnapshot.stt, isNull);
      },
    );

    test('Rehearsal AI 실패 × 오디오 {stored, deleted, expired} 조합', () {
      final base = DemoData.rehearsal3.copyWith(
        stages: {
          for (final s in ProcessingStage.values) s: StageState.succeeded,
          ProcessingStage.interpret: StageState.failed,
        },
        firstFailureAt: DateTime(2026, 9, 9, 21, 16),
      );
      for (final audio in [
        AudioState.stored,
        AudioState.deleted,
        AudioState.expired,
      ]) {
        final r = base.copyWith(
          audio: AudioInfo(
            state: audio,
            expiresAt: DateTime(2026, 9, 16, 21, 14),
          ),
          transcript: TranscriptInfo(
            state: audio == AudioState.deleted
                ? TranscriptState.tempRetained
                : TranscriptState.stored,
            expiresAt: DateTime(2026, 9, 16, 21, 14),
            retryDeadlineAt: audio == AudioState.deleted
                ? DateTime(2026, 9, 10, 21, 16)
                : null,
          ),
          externalDeletion: const ExternalDeletion(
            stt: ExternalDeletionState.unknown,
            llm: ExternalDeletionState.requested,
          ),
        );
        final back = Rehearsal.fromJson(r.toJson());
        expect(back, r, reason: '오디오 $audio');
        expect(back.isAiOnlyFailure, isTrue);
        expect(back.audio.state, audio);
        expect(back.externalDeletion.stt, ExternalDeletionState.unknown);
        final modes = ReportModeExtension.derive(
          hasAi: false,
          audioState: audio,
        );
        expect(modes.contains(ReportMode.partial), isTrue);
        expect(
          modes.contains(ReportMode.audioUnavailable),
          audio != AudioState.stored,
          reason: 'ReportMode는 파생값이며 두 모드가 동시에 가능',
        );
      }
    });

    test('Rehearsal 부분 리허설 (capReached · scope partial)', () {
      final r = DemoData.rehearsal3.copyWith(
        capReached: true,
        scope: RehearsalScope.partial,
      );
      final back = Rehearsal.fromJson(r.toJson());
      expect(back.capReached, isTrue);
      expect(back.scope, RehearsalScope.partial);
    });

    test('Report 전체 · 부분(ai null) · 도달 구간 일치율', () {
      expect(Report.fromJson(DemoData.report3.toJson()), DemoData.report3);
      final partial = DemoData.report3Partial;
      final back = Report.fromJson(partial.toJson());
      expect(back.ai, isNull);
      expect(back.hasAi, isFalse);
      expect(back.metrics.fillers.length, 7);
      expect(back.missedCount, 6);
      expect(back.addedCount, 3);
      expect(back.reorderedCount, 1);
      expect(DemoData.report3.matchRateDeltaPp, closeTo(6, 0.01));

      final reached = DemoData.report3.copyWith(
        matchRateScope: MatchRateScope.reached,
        alignment: [
          ...DemoData.alignment3,
          const AlignedSentence(
            scriptSentenceRef: 15,
            state: SentenceState.notReached,
          ),
        ],
      );
      final reachedBack = Report.fromJson(reached.toJson());
      expect(reachedBack.matchRateScope, MatchRateScope.reached);
      expect(reachedBack.alignment.last.state, SentenceState.notReached);
    });

    test('Report 섹션 시간 합 = 12:40', () {
      expect(DemoData.metrics3.totalSec, 760);
      expect(DemoData.metrics3.wpmSeries.length, 32);
    });

    test('ConsentRecord', () {
      final c = ConsentRecord(
        userId: 'u1',
        consentVersion: 'c-abc',
        acceptedAt: DateTime(2026, 9, 6),
      );
      expect(ConsentRecord.fromJson(c.toJson()), c);
    });

    test('ProviderConfig 비어 있음 · 채워짐', () {
      expect(
        ProviderConfig.fromJson(ProviderConfig.empty.toJson()).isConfigured,
        isFalse,
      );
      const filled = ProviderConfig(
        stt: ProviderEntry(
          id: 'stt-x',
          name: 'STT X',
          region: 'KR',
          policyUrl: 'https://x',
          policyVersion: '2026-09',
        ),
        llm: ProviderEntry(
          id: 'llm-y',
          name: 'LLM Y',
          region: 'US',
          policyUrl: 'https://y',
          policyVersion: '2026-08',
          retention: {'text': '30일'},
        ),
      );
      final back = ProviderConfig.fromJson(filled.toJson());
      expect(back, filled);
      expect(back.isConfigured, isTrue);
      expect(back.llm!.retentionLabel('text'), '30일');
      expect(back.stt!.retentionLabel('audio'), '미확정');
    });
  });
}
