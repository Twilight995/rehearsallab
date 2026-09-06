import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:rehearsallab/core/enum/match_rate_scope.dart';
import 'package:rehearsallab/core/enum/sentence_state.dart';
import 'package:rehearsallab/models/rehearsal.dart';
import 'package:rehearsallab/models/report.dart';
import 'package:rehearsallab/services/mock/demo_data.dart';

/// 통합 문서 5장 계약 형식으로 직접 쓴 fixture (P0-REV-03).
/// 앱이 만든 JSON을 다시 읽는 왕복이 아니라, 계약 문서를 보고 손으로 쓴 JSON을 읽을 수 있어야 한다.
const String contractReportJson = '''
{
  "id": "rep-1",
  "rehearsal_id": "reh-1",
  "metrics": {
    "wpm_series": [{"time_sec": 0, "wpm": 130}, {"time_sec": 30, "wpm": 181}],
    "fillers": [{"time_sec": 12, "text": "어"}],
    "silences": [{"start_sec": 40, "end_sec": 44}],
    "section_times": [
      {"name": "배경", "actual_sec": 120, "recommended_sec": 135, "start_sec": 0},
      {"name": "방법", "actual_sec": 310, "recommended_sec": 270, "start_sec": 120}
    ]
  },
  "alignment": {
    "sentences": [
      {"script_sentence_ref": 0, "state": "read", "time_sec": 4, "spoken_text": null},
      {"script_sentence_ref": 1, "state": "missed", "time_sec": null, "spoken_text": null},
      {"script_sentence_ref": 1, "state": "added", "time_sec": 30, "spoken_text": "그니까 어"},
      {"script_sentence_ref": 2, "state": "notReached", "time_sec": null, "spoken_text": null}
    ]
  },
  "match_rate": 0.5,
  "match_rate_scope": "reached",
  "prev_match_rate": null,
  "ai": null,
  "created_at": "2026-09-09T21:16:00.000"
}
''';

void main() {
  group('Report 저장 스키마 = 통합 문서 5장', () {
    test('계약 형식 fixture를 읽는다 (alignment.sentences 중첩 · snake_case)', () {
      final report = Report.fromJson(contractReportJson);
      expect(report.id, 'rep-1');
      expect(report.alignment.length, 4);
      expect(report.alignment[2].state, SentenceState.added);
      expect(report.alignment[2].spokenText, '그니까 어');
      expect(report.alignment[3].state, SentenceState.notReached);
      expect(report.matchRateScope, MatchRateScope.reached);
      expect(report.prevMatchRate, isNull);
      expect(report.ai, isNull);
      expect(report.metrics.wpmSeries[1].wpm, 181);
    });

    test('toMap 출력 키가 계약과 같다', () {
      final map = DemoData.report3.toMap();
      expect(
        map.keys,
        containsAll([
          'id',
          'rehearsal_id',
          'metrics',
          'alignment',
          'match_rate',
          'match_rate_scope',
          'prev_match_rate',
          'ai',
          'created_at',
        ]),
      );
      final alignment = map['alignment'];
      expect(alignment, isA<Map<String, dynamic>>());
      expect((alignment as Map<String, dynamic>)['sentences'], isA<List>());
      final sentence =
          (alignment['sentences'] as List).first as Map<String, dynamic>;
      expect(
        sentence.keys,
        containsAll([
          'script_sentence_ref',
          'state',
          'time_sec',
          'spoken_text',
        ]),
      );
      final metrics = map['metrics'] as Map<String, dynamic>;
      expect(
        metrics.keys,
        containsAll(['wpm_series', 'fillers', 'silences', 'section_times']),
      );
      expect(map['ai'], isA<Map<String, dynamic>>());
      expect(
        (map['ai'] as Map<String, dynamic>).keys,
        containsAll(['top_actions', 'dimensions', 'failed_at']),
      );
    });

    test('계약 fixture → toJson → fromJson 왕복 동일', () {
      final report = Report.fromJson(contractReportJson);
      expect(Report.fromJson(report.toJson()), report);
    });

    test('전체 전사문 필드는 존재하지 않는다 (spoken_text는 추가 문장에만)', () {
      final map = DemoData.report3.toMap();
      final encoded = json.encode(map);
      expect(encoded.contains('transcript'), isFalse);
      final sentences =
          (map['alignment'] as Map<String, dynamic>)['sentences'] as List;
      for (final s in sentences.cast<Map<String, dynamic>>()) {
        if (s['state'] != 'added') expect(s['spoken_text'], isNull);
      }
    });
  });

  group('Rehearsal 저장 스키마 키', () {
    test('통합 문서 5장 키 목록', () {
      final map = DemoData.rehearsal3.toMap();
      expect(
        map.keys,
        containsAll([
          'id',
          'presentation_id',
          'script_version_id',
          'round',
          'recorded_at',
          'duration_sec',
          'teleprompter_on',
          'cap_reached',
          'scope',
          'audio',
          'transcript',
          'stages',
          'first_failure_at',
          'external_deletion',
          'consent_version',
          'provider_snapshot',
          'report_id',
        ]),
      );
      expect(
        (map['audio'] as Map<String, dynamic>).keys,
        containsAll(['state', 'expires_at', 'local_expires_at']),
      );
      expect(
        (map['transcript'] as Map<String, dynamic>).keys,
        containsAll(['state', 'expires_at', 'retry_deadline_at']),
      );
      expect(
        (map['external_deletion'] as Map<String, dynamic>).keys,
        containsAll(['stt', 'llm']),
      );
      expect(
        (map['provider_snapshot'] as Map<String, dynamic>).keys,
        containsAll(['stt', 'llm']),
      );
      expect(
        (map['stages'] as Map<String, dynamic>).keys,
        containsAll(['upload', 'transcribe', 'metrics', 'align', 'interpret']),
      );
    });

    test('받아쓰기 전 fixture: transcript null · provider_snapshot 비어 있음', () {
      const raw = '''
{
  "id": "reh-2", "presentation_id": "p1", "script_version_id": "v1", "round": 1,
  "recorded_at": "2026-09-09T21:14:00.000", "duration_sec": 100, "teleprompter_on": true,
  "cap_reached": false, "scope": "full",
  "audio": {"state": "localOnly", "expires_at": null, "local_expires_at": null},
  "transcript": null,
  "stages": {"upload": "running", "transcribe": "pending", "metrics": "pending", "align": "pending", "interpret": "pending"},
  "first_failure_at": null,
  "external_deletion": {"stt": "notRequested", "llm": "notRequested"},
  "consent_version": "c-1",
  "provider_snapshot": {"stt": null, "llm": null},
  "report_id": null
}
''';
      final r = Rehearsal.fromJson(raw);
      expect(r.transcript, isNull);
      expect(r.providerSnapshot.stt, isNull);
      expect(Rehearsal.fromJson(r.toJson()), r);
    });
  });
}
