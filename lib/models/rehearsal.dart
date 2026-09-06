// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:rehearsallab/core/enum/audio_state.dart';
import 'package:rehearsallab/core/enum/external_deletion_state.dart';
import 'package:rehearsallab/core/enum/processing_stage.dart';
import 'package:rehearsallab/core/enum/rehearsal_scope.dart';
import 'package:rehearsallab/core/enum/stage_state.dart';
import 'package:rehearsallab/core/enum/transcript_state.dart';

/// 녹음 원본 상태 (통합 문서 5장 Rehearsal.audio).
class AudioInfo {
  final AudioState state;

  /// 보관 만료 시각 (recordedAt + 보관 기간). 재분석해도 연장 없음
  final DateTime? expiresAt;

  /// 기기 녹음 보관 기한 (최초 실패 시각 + 7일). localOnly일 때만
  final DateTime? localExpiresAt;

  const AudioInfo({required this.state, this.expiresAt, this.localExpiresAt});

  AudioInfo copyWith({
    AudioState? state,
    DateTime? expiresAt,
    DateTime? localExpiresAt,
  }) => AudioInfo(
    state: state ?? this.state,
    expiresAt: expiresAt ?? this.expiresAt,
    localExpiresAt: localExpiresAt ?? this.localExpiresAt,
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    'state': state.name,
    'expires_at': expiresAt?.toIso8601String(),
    'local_expires_at': localExpiresAt?.toIso8601String(),
  };

  factory AudioInfo.fromMap(Map<String, dynamic> map) => AudioInfo(
    state: AudioStateExtension.fromName(map['state'] as String),
    expiresAt: map['expires_at'] != null
        ? DateTime.parse(map['expires_at'] as String)
        : null,
    localExpiresAt: map['local_expires_at'] != null
        ? DateTime.parse(map['local_expires_at'] as String)
        : null,
  );
}

/// 전사문 원본 상태. 받아쓰기 전에는 Rehearsal.transcript 자체가 null.
class TranscriptInfo {
  final TranscriptState state;

  /// 7일/30일 옵션: audio.expiresAt과 동일. 즉시 삭제 + AI 실패: 최초 실패 + 24h
  final DateTime expiresAt;

  /// AI 재시도 가능 기한 (표시용). 없으면 expiresAt까지
  final DateTime? retryDeadlineAt;

  const TranscriptInfo({
    required this.state,
    required this.expiresAt,
    this.retryDeadlineAt,
  });

  DateTime get effectiveRetryDeadline => retryDeadlineAt ?? expiresAt;

  TranscriptInfo copyWith({
    TranscriptState? state,
    DateTime? expiresAt,
    DateTime? retryDeadlineAt,
  }) => TranscriptInfo(
    state: state ?? this.state,
    expiresAt: expiresAt ?? this.expiresAt,
    retryDeadlineAt: retryDeadlineAt ?? this.retryDeadlineAt,
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    'state': state.name,
    'expires_at': expiresAt.toIso8601String(),
    'retry_deadline_at': retryDeadlineAt?.toIso8601String(),
  };

  factory TranscriptInfo.fromMap(Map<String, dynamic> map) => TranscriptInfo(
    state: TranscriptStateExtension.fromName(map['state'] as String),
    expiresAt: DateTime.parse(map['expires_at'] as String),
    retryDeadlineAt: map['retry_deadline_at'] != null
        ? DateTime.parse(map['retry_deadline_at'] as String)
        : null,
  );
}

/// 외부 제공사 삭제 상태 (STT · LLM 각각).
class ExternalDeletion {
  final ExternalDeletionState stt;
  final ExternalDeletionState llm;

  const ExternalDeletion({
    this.stt = ExternalDeletionState.notRequested,
    this.llm = ExternalDeletionState.notRequested,
  });

  ExternalDeletion copyWith({
    ExternalDeletionState? stt,
    ExternalDeletionState? llm,
  }) => ExternalDeletion(stt: stt ?? this.stt, llm: llm ?? this.llm);

  Map<String, dynamic> toMap() => <String, dynamic>{
    'stt': stt.name,
    'llm': llm.name,
  };

  factory ExternalDeletion.fromMap(Map<String, dynamic> map) =>
      ExternalDeletion(
        stt: ExternalDeletionStateExtension.fromName(map['stt'] as String),
        llm: ExternalDeletionStateExtension.fromName(map['llm'] as String),
      );
}

/// 리허설 시작 당시의 제공사 · 정책 스냅샷 (한 제공사분).
class ProviderSnapshotEntry {
  final String id;
  final String region;
  final String policyVersion;

  const ProviderSnapshotEntry({
    required this.id,
    required this.region,
    required this.policyVersion,
  });

  Map<String, dynamic> toMap() => <String, dynamic>{
    'id': id,
    'region': region,
    'policy_version': policyVersion,
  };

  factory ProviderSnapshotEntry.fromMap(Map<String, dynamic> map) =>
      ProviderSnapshotEntry(
        id: map['id'] as String,
        region: map['region'] as String,
        policyVersion: map['policy_version'] as String,
      );
}

/// STT · LLM 스냅샷. mock 모드에서는 둘 다 null.
class ProviderSnapshot {
  final ProviderSnapshotEntry? stt;
  final ProviderSnapshotEntry? llm;

  const ProviderSnapshot({this.stt, this.llm});

  Map<String, dynamic> toMap() => <String, dynamic>{
    'stt': stt?.toMap(),
    'llm': llm?.toMap(),
  };

  factory ProviderSnapshot.fromMap(Map<String, dynamic> map) =>
      ProviderSnapshot(
        stt: map['stt'] != null
            ? ProviderSnapshotEntry.fromMap(map['stt'] as Map<String, dynamic>)
            : null,
        llm: map['llm'] != null
            ? ProviderSnapshotEntry.fromMap(map['llm'] as Map<String, dynamic>)
            : null,
      );
}

/// 리허설 = 원고 한 버전을 읽은 녹음 1회 (통합 문서 5장).
class Rehearsal {
  final String id;
  final String presentationId;

  /// 녹음 시작 시점의 원고 버전 (스냅샷 고정)
  final String scriptVersionId;
  final int round;
  final DateTime recordedAt;

  /// 실제 녹음 누적 시간 (카운트다운 · 일시정지 제외)
  final int durationSec;
  final bool teleprompterOn;

  /// 20:00 상한 도달 여부
  final bool capReached;
  final RehearsalScope scope;
  final AudioInfo audio;
  final TranscriptInfo? transcript;
  final Map<ProcessingStage, StageState> stages;

  /// 만료 · 기한 계산 기준. 반복 실패로 갱신하지 않는다
  final DateTime? firstFailureAt;
  final ExternalDeletion externalDeletion;
  final String consentVersion;
  final ProviderSnapshot providerSnapshot;
  final String? reportId;

  const Rehearsal({
    required this.id,
    required this.presentationId,
    required this.scriptVersionId,
    required this.round,
    required this.recordedAt,
    required this.durationSec,
    required this.teleprompterOn,
    this.capReached = false,
    this.scope = RehearsalScope.full,
    required this.audio,
    this.transcript,
    required this.stages,
    this.firstFailureAt,
    this.externalDeletion = const ExternalDeletion(),
    required this.consentVersion,
    this.providerSnapshot = const ProviderSnapshot(),
    this.reportId,
  });

  Duration get duration => Duration(seconds: durationSec);

  StageState stage(ProcessingStage s) => stages[s] ?? StageState.pending;

  bool get allStagesSucceeded =>
      ProcessingStage.values.every((s) => stage(s) == StageState.succeeded);

  /// AI 해석만 실패했고 나머지는 성공
  bool get isAiOnlyFailure =>
      stage(ProcessingStage.interpret) == StageState.failed &&
      ProcessingStage.values
          .where((s) => s != ProcessingStage.interpret)
          .every((s) => stage(s) == StageState.succeeded);

  Rehearsal copyWith({
    String? id,
    String? presentationId,
    String? scriptVersionId,
    int? round,
    DateTime? recordedAt,
    int? durationSec,
    bool? teleprompterOn,
    bool? capReached,
    RehearsalScope? scope,
    AudioInfo? audio,
    TranscriptInfo? transcript,
    Map<ProcessingStage, StageState>? stages,
    DateTime? firstFailureAt,
    ExternalDeletion? externalDeletion,
    String? consentVersion,
    ProviderSnapshot? providerSnapshot,
    String? reportId,
  }) {
    return Rehearsal(
      id: id ?? this.id,
      presentationId: presentationId ?? this.presentationId,
      scriptVersionId: scriptVersionId ?? this.scriptVersionId,
      round: round ?? this.round,
      recordedAt: recordedAt ?? this.recordedAt,
      durationSec: durationSec ?? this.durationSec,
      teleprompterOn: teleprompterOn ?? this.teleprompterOn,
      capReached: capReached ?? this.capReached,
      scope: scope ?? this.scope,
      audio: audio ?? this.audio,
      transcript: transcript ?? this.transcript,
      stages: stages ?? this.stages,
      firstFailureAt: firstFailureAt ?? this.firstFailureAt,
      externalDeletion: externalDeletion ?? this.externalDeletion,
      consentVersion: consentVersion ?? this.consentVersion,
      providerSnapshot: providerSnapshot ?? this.providerSnapshot,
      reportId: reportId ?? this.reportId,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'presentation_id': presentationId,
      'script_version_id': scriptVersionId,
      'round': round,
      'recorded_at': recordedAt.toIso8601String(),
      'duration_sec': durationSec,
      'teleprompter_on': teleprompterOn,
      'cap_reached': capReached,
      'scope': scope.name,
      'audio': audio.toMap(),
      'transcript': transcript?.toMap(),
      'stages': {for (final e in stages.entries) e.key.name: e.value.name},
      'first_failure_at': firstFailureAt?.toIso8601String(),
      'external_deletion': externalDeletion.toMap(),
      'consent_version': consentVersion,
      'provider_snapshot': providerSnapshot.toMap(),
      'report_id': reportId,
    };
  }

  factory Rehearsal.fromMap(Map<String, dynamic> map) {
    final rawStages = map['stages'] as Map<String, dynamic>? ?? {};
    return Rehearsal(
      id: map['id'] as String,
      presentationId: map['presentation_id'] as String,
      scriptVersionId: map['script_version_id'] as String,
      round: map['round'] as int,
      recordedAt: DateTime.parse(map['recorded_at'] as String),
      durationSec: map['duration_sec'] as int,
      teleprompterOn: map['teleprompter_on'] as bool? ?? true,
      capReached: map['cap_reached'] as bool? ?? false,
      scope: RehearsalScopeExtension.fromName(
        map['scope'] as String? ?? RehearsalScope.full.name,
      ),
      audio: AudioInfo.fromMap(map['audio'] as Map<String, dynamic>),
      transcript: map['transcript'] != null
          ? TranscriptInfo.fromMap(map['transcript'] as Map<String, dynamic>)
          : null,
      stages: {
        for (final e in rawStages.entries)
          ProcessingStageExtension.fromName(e.key):
              StageStateExtension.fromName(e.value as String),
      },
      firstFailureAt: map['first_failure_at'] != null
          ? DateTime.parse(map['first_failure_at'] as String)
          : null,
      externalDeletion: map['external_deletion'] != null
          ? ExternalDeletion.fromMap(
              map['external_deletion'] as Map<String, dynamic>,
            )
          : const ExternalDeletion(),
      consentVersion: map['consent_version'] as String,
      providerSnapshot: map['provider_snapshot'] != null
          ? ProviderSnapshot.fromMap(
              map['provider_snapshot'] as Map<String, dynamic>,
            )
          : const ProviderSnapshot(),
      reportId: map['report_id'] as String?,
    );
  }

  String toJson() => json.encode(toMap());

  factory Rehearsal.fromJson(String source) =>
      Rehearsal.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'Rehearsal(id: $id, round: $round, scriptVersionId: $scriptVersionId, durationSec: $durationSec, scope: $scope, audio: ${audio.state}, transcript: ${transcript?.state}, stages: $stages)';
  }

  @override
  bool operator ==(covariant Rehearsal other) {
    if (identical(this, other)) return true;
    return other.toJson() == toJson();
  }

  @override
  int get hashCode => toJson().hashCode;
}
