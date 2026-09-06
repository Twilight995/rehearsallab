import 'package:flutter_test/flutter_test.dart';
import 'package:rehearsallab/core/models/result.dart';
import 'package:rehearsallab/models/report.dart';
import 'package:rehearsallab/models/script_analysis.dart';
import 'package:rehearsallab/services/local_store_service.dart';
import 'package:rehearsallab/services/mock/demo_data.dart';

void main() {
  group('MemoryLocalStoreService 발표 삭제 (P0-REV-04 cascade)', () {
    late MemoryLocalStoreService store;

    setUp(() {
      final other = DemoData.presentations[1];
      final otherVersion = DemoData.scriptV1.copyWith(
        id: 'other-v1',
        presentationId: other.id,
      );
      final otherAnalysis = DemoData.analysisV1.copyWith(
        id: 'other-a',
        scriptVersionId: 'other-v1',
      );
      final otherRehearsal = DemoData.rehearsal1.copyWith(
        id: 'other-r',
        presentationId: other.id,
        scriptVersionId: 'other-v1',
        reportId: 'other-rep',
      );
      final otherReport = DemoData.report1.copyWith(
        id: 'other-rep',
        rehearsalId: 'other-r',
      );
      store = MemoryLocalStoreService(
        presentations: [DemoData.presentation, other],
        versions: [
          DemoData.scriptV1,
          DemoData.scriptV2,
          DemoData.scriptV3,
          otherVersion,
        ],
        analyses: [DemoData.analysisV1, otherAnalysis],
        rehearsals: [...DemoData.rehearsals, otherRehearsal],
        reports: [...DemoData.reports, otherReport],
      );
    });

    Future<T?> value<T>(Future<Result<T?>> f) async =>
        ((await f) as Success<T?>).value;

    test('발표를 지우면 원고 버전 · 분석 · 리허설 · 리포트가 모두 사라진다', () async {
      await store.deletePresentation(DemoData.presentationId);
      expect(
        await value<ScriptAnalysis>(store.loadAnalysis(DemoData.scriptV1Id)),
        isNull,
      );
      expect(await value<Report>(store.loadReport('demo-report-3')), isNull);
      expect(await value<Report>(store.loadReport('demo-report-1')), isNull);
      final versions =
          ((await store.loadScriptVersions(DemoData.presentationId)) as Success)
                  .value
              as List;
      expect(versions, isEmpty);
      final rehearsals =
          ((await store.loadRehearsals(DemoData.presentationId)) as Success)
                  .value
              as List;
      expect(rehearsals, isEmpty);
      final presentations =
          ((await store.loadPresentations()) as Success).value as List;
      expect(presentations.length, 1);
    });

    test('다른 발표의 데이터는 보존된다', () async {
      await store.deletePresentation(DemoData.presentationId);
      expect(
        await value<ScriptAnalysis>(store.loadAnalysis('other-v1')),
        isNotNull,
      );
      expect(await value<Report>(store.loadReport('other-rep')), isNotNull);
      final rehearsals =
          ((await store.loadRehearsals(DemoData.presentations[1].id))
                      as Success)
                  .value
              as List;
      expect(rehearsals.length, 1);
    });

    test('리허설 삭제는 리포트도 지운다', () async {
      await store.deleteRehearsal('demo-rehearsal-3');
      expect(await value<Report>(store.loadReport('demo-report-3')), isNull);
      expect(await value<Report>(store.loadReport('demo-report-2')), isNotNull);
    });

    test('deleteAll 후 모두 비어 있다', () async {
      await store.deleteAll();
      final presentations =
          ((await store.loadPresentations()) as Success).value as List;
      expect(presentations, isEmpty);
      expect(await value<Report>(store.loadReport('other-rep')), isNull);
    });
  });
}
