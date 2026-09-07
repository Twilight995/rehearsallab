import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:rehearsallab/core/models/result.dart';
import 'package:rehearsallab/models/presentation.dart';
import 'package:rehearsallab/models/rehearsal.dart';
import 'package:rehearsallab/models/report.dart';
import 'package:rehearsallab/models/script_version.dart';
import 'package:rehearsallab/services/local_store_service.dart';
import 'package:rehearsallab/services/mock/demo_data.dart';

void main() {
  late Directory temp;
  FileLocalStoreService store() =>
      FileLocalStoreService(baseDirectory: () async => temp);
  File fileOf(String name) =>
      File(p.join(temp.path, FileLocalStoreService.folderName, name));

  setUp(() async {
    temp = await Directory.systemTemp.createTemp('rehearsallab_store_');
  });

  tearDown(() async {
    if (await temp.exists()) await temp.delete(recursive: true);
  });

  T value<T>(Result<T> r) => (r as Success<T>).value;

  group('FileLocalStoreService (live 저장소, C1-3)', () {
    test('발표 저장 → 새 인스턴스에서 읽기 · JSON 키 snake_case', () async {
      final a = store();
      expect(value(await a.loadPresentations()), isEmpty);
      await a.savePresentation(DemoData.presentation);
      await a.savePresentation(DemoData.presentations[2]);

      final raw = await fileOf(
        FileLocalStoreService.presentationsFile,
      ).readAsString();
      final list = json.decode(raw) as List<dynamic>;
      expect(list, hasLength(2));
      expect(
        (list.first as Map<String, dynamic>).keys,
        contains('talk_minutes'),
      );

      final b = store();
      final loaded = value(await b.loadPresentations());
      expect(
        loaded,
        containsAll([DemoData.presentation, DemoData.presentations[2]]),
      );
    });

    test('원고 · 분석 · 리허설 · 리포트 왕복', () async {
      final a = store();
      await a.saveScriptVersion(DemoData.scriptV1);
      await a.saveAnalysis(DemoData.analysisV1);
      await a.saveRehearsal(DemoData.rehearsal3);
      await a.saveReport(DemoData.report3);

      final b = store();
      expect(value(await b.loadScriptVersions(DemoData.presentationId)), [
        DemoData.scriptV1,
      ]);
      expect(
        value(await b.loadAnalysis(DemoData.scriptV1Id))?.id,
        DemoData.analysisV1.id,
      );
      final rehearsals = value(await b.loadRehearsals(DemoData.presentationId));
      expect(rehearsals.single.id, DemoData.rehearsal3.id);
      expect(value(await b.loadReport(DemoData.report3.id))?.matchRate, 0.87);
    });

    test('발표 삭제 cascade가 파일에도 반영된다', () async {
      final a = store();
      await a.savePresentation(DemoData.presentation);
      await a.saveScriptVersion(DemoData.scriptV1);
      await a.saveAnalysis(DemoData.analysisV1);
      await a.saveRehearsal(DemoData.rehearsal3);
      await a.saveReport(DemoData.report3);
      await a.deletePresentation(DemoData.presentationId);

      final b = store();
      expect(value(await b.loadPresentations()), isEmpty);
      expect(
        value(await b.loadScriptVersions(DemoData.presentationId)),
        isEmpty,
      );
      expect(value(await b.loadAnalysis(DemoData.scriptV1Id)), isNull);
      expect(value(await b.loadRehearsals(DemoData.presentationId)), isEmpty);
      expect(value(await b.loadReport(DemoData.report3.id)), isNull);
    });

    test('손상된 파일 → Failure, 파일은 지우지 않는다', () async {
      final dir = Directory(
        p.join(temp.path, FileLocalStoreService.folderName),
      );
      await dir.create(recursive: true);
      await fileOf(
        FileLocalStoreService.presentationsFile,
      ).writeAsString('[{broken');
      final s = store();
      expect(await s.loadPresentations(), isA<Failure<List<Presentation>>>());
      expect(
        await s.savePresentation(DemoData.presentation),
        isA<Failure<void>>(),
        reason: '로드 실패 상태에서는 덮어쓰지 않는다',
      );
      expect(
        await fileOf(FileLocalStoreService.presentationsFile).readAsString(),
        '[{broken',
      );
    });

    test('deleteAll → 파일 5개 삭제 · 빈 목록', () async {
      final a = store();
      await a.savePresentation(DemoData.presentation);
      await a.saveScriptVersion(DemoData.scriptV1);
      await a.saveRehearsal(DemoData.rehearsal1);
      await a.saveReport(DemoData.report1);
      await a.deleteAll();
      for (final name in FileLocalStoreService.allFiles) {
        expect(await fileOf(name).exists(), isFalse, reason: name);
      }
      expect(value(await store().loadPresentations()), isEmpty);
    });

    test('리허설 삭제 시 리포트도 파일에서 사라진다', () async {
      final a = store();
      await a.saveRehearsal(DemoData.rehearsal1);
      await a.saveReport(DemoData.report1);
      await a.deleteRehearsal(DemoData.rehearsal1.id);
      final b = store();
      expect(value(await b.loadRehearsals(DemoData.presentationId)), isEmpty);
      expect(value(await b.loadReport(DemoData.report1.id)), isNull);
    });

    test('리허설 정렬(회차 내림차순) · 원고 정렬(버전 오름차순)은 메모리 구현과 동일', () async {
      final a = store();
      await a.saveRehearsal(DemoData.rehearsal1);
      await a.saveRehearsal(DemoData.rehearsal3);
      await a.saveRehearsal(DemoData.rehearsal2);
      await a.saveScriptVersion(DemoData.scriptV3);
      await a.saveScriptVersion(DemoData.scriptV1);
      final b = store();
      final rounds = value(
        await b.loadRehearsals(DemoData.presentationId),
      ).map((Rehearsal r) => r.round);
      expect(rounds, [3, 2, 1]);
      final versions = value(
        await b.loadScriptVersions(DemoData.presentationId),
      ).map((ScriptVersion v) => v.version);
      expect(versions, [1, 3]);
      expect(value(await b.loadReport('none')), isNull);
      expect(DemoData.report1, isA<Report>());
    });
  });
}
