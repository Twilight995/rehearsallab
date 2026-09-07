import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:rehearsallab/core/models/result.dart';
import 'package:rehearsallab/models/presentation.dart';
import 'package:rehearsallab/models/rehearsal.dart';
import 'package:rehearsallab/models/report.dart';
import 'package:rehearsallab/models/script_analysis.dart';
import 'package:rehearsallab/models/script_version.dart';

/// 발표 · 원고 · 분석 · 리허설 · 리포트 로컬 저장.
/// - Phase 0: MemoryLocalStoreService (테스트 · mock)
/// - Phase 1: FileLocalStoreService (path_provider, JSON 파일)
/// 상태 없음. 명령은 `Future<Result<T>>`. Notifier는 변이 후 invalidateSelf()로 재조회한다.
abstract class LocalStoreService {
  Future<Result<List<Presentation>>> loadPresentations();
  Future<Result<void>> savePresentation(Presentation presentation);
  Future<Result<void>> deletePresentation(String presentationId);

  Future<Result<List<ScriptVersion>>> loadScriptVersions(String presentationId);
  Future<Result<void>> saveScriptVersion(ScriptVersion version);

  Future<Result<ScriptAnalysis?>> loadAnalysis(String scriptVersionId);
  Future<Result<void>> saveAnalysis(ScriptAnalysis analysis);

  Future<Result<List<Rehearsal>>> loadRehearsals(String presentationId);
  Future<Result<void>> saveRehearsal(Rehearsal rehearsal);
  Future<Result<void>> deleteRehearsal(String rehearsalId);

  Future<Result<Report?>> loadReport(String reportId);
  Future<Result<void>> saveReport(Report report);

  /// 설정 09 → 31 → 32 "모든 데이터 삭제". 실패 항목은 지워진 척하지 않는다.
  Future<Result<void>> deleteAll();
}

/// 메모리 구현. 앱을 재시작하면 사라진다. mock 모드 기본값이며 seed로 데모 데이터를 넣을 수 있다.
class MemoryLocalStoreService implements LocalStoreService {
  final Map<String, Presentation> _presentations = {};
  final Map<String, ScriptVersion> _versions = {};
  final Map<String, ScriptAnalysis> _analyses = {};
  final Map<String, Rehearsal> _rehearsals = {};
  final Map<String, Report> _reports = {};

  MemoryLocalStoreService({
    Iterable<Presentation> presentations = const [],
    Iterable<ScriptVersion> versions = const [],
    Iterable<ScriptAnalysis> analyses = const [],
    Iterable<Rehearsal> rehearsals = const [],
    Iterable<Report> reports = const [],
  }) {
    for (final p in presentations) {
      _presentations[p.id] = p;
    }
    for (final v in versions) {
      _versions[v.id] = v;
    }
    for (final a in analyses) {
      _analyses[a.scriptVersionId] = a;
    }
    for (final r in rehearsals) {
      _rehearsals[r.id] = r;
    }
    for (final r in reports) {
      _reports[r.id] = r;
    }
  }

  @override
  Future<Result<List<Presentation>>> loadPresentations() async =>
      Success(_presentations.values.toList());

  @override
  Future<Result<void>> savePresentation(Presentation presentation) async {
    _presentations[presentation.id] = presentation;
    return const Success(null);
  }

  @override
  Future<Result<void>> deletePresentation(String presentationId) async {
    // 발표에 딸린 원고 버전 · 분석 · 리허설 · 리포트를 모두 지운다 (근거 인용 · 발화 인용 잔존 금지).
    _presentations.remove(presentationId);
    final versionIds = _versions.values
        .where((v) => v.presentationId == presentationId)
        .map((v) => v.id)
        .toSet();
    final reportIds = _rehearsals.values
        .where((r) => r.presentationId == presentationId)
        .map((r) => r.reportId)
        .whereType<String>()
        .toSet();
    _versions.removeWhere((id, _) => versionIds.contains(id));
    _analyses.removeWhere((versionId, _) => versionIds.contains(versionId));
    _rehearsals.removeWhere((_, r) => r.presentationId == presentationId);
    _reports.removeWhere((id, _) => reportIds.contains(id));
    return const Success(null);
  }

  @override
  Future<Result<List<ScriptVersion>>> loadScriptVersions(
    String presentationId,
  ) async {
    final list =
        _versions.values
            .where((v) => v.presentationId == presentationId)
            .toList()
          ..sort((a, b) => a.version.compareTo(b.version));
    return Success(list);
  }

  @override
  Future<Result<void>> saveScriptVersion(ScriptVersion version) async {
    _versions[version.id] = version;
    return const Success(null);
  }

  @override
  Future<Result<ScriptAnalysis?>> loadAnalysis(String scriptVersionId) async =>
      Success(_analyses[scriptVersionId]);

  @override
  Future<Result<void>> saveAnalysis(ScriptAnalysis analysis) async {
    _analyses[analysis.scriptVersionId] = analysis;
    return const Success(null);
  }

  @override
  Future<Result<List<Rehearsal>>> loadRehearsals(String presentationId) async {
    final list =
        _rehearsals.values
            .where((r) => r.presentationId == presentationId)
            .toList()
          ..sort((a, b) => b.round.compareTo(a.round));
    return Success(list);
  }

  @override
  Future<Result<void>> saveRehearsal(Rehearsal rehearsal) async {
    _rehearsals[rehearsal.id] = rehearsal;
    return const Success(null);
  }

  @override
  Future<Result<void>> deleteRehearsal(String rehearsalId) async {
    final removed = _rehearsals.remove(rehearsalId);
    if (removed?.reportId != null) _reports.remove(removed!.reportId);
    return const Success(null);
  }

  @override
  Future<Result<Report?>> loadReport(String reportId) async =>
      Success(_reports[reportId]);

  @override
  Future<Result<void>> saveReport(Report report) async {
    _reports[report.id] = report;
    return const Success(null);
  }

  @override
  Future<Result<void>> deleteAll() async {
    _presentations.clear();
    _versions.clear();
    _analyses.clear();
    _rehearsals.clear();
    _reports.clear();
    return const Success(null);
  }
}

/// 파일 구현 (live 모드, C1-3). 앱 문서 폴더 `rehearsallab/` 아래 컬렉션별 JSON 파일 5개.
/// 메모리 구현을 캐시로 쓰고 변이마다 해당 컬렉션 파일을 다시 쓴다. 파일 오류는 Failure로 돌려주고
/// 손상된 파일은 지우지 않는다 (설정 09 "모든 데이터 삭제"만 파일을 지운다).
class FileLocalStoreService extends MemoryLocalStoreService {
  static const String folderName = 'rehearsallab';
  static const String presentationsFile = 'presentations.json';
  static const String versionsFile = 'script_versions.json';
  static const String analysesFile = 'analyses.json';
  static const String rehearsalsFile = 'rehearsals.json';
  static const String reportsFile = 'reports.json';
  static const List<String> allFiles = [
    presentationsFile,
    versionsFile,
    analysesFile,
    rehearsalsFile,
    reportsFile,
  ];

  final Future<Directory> Function() _baseDirectory;
  Future<void>? _loading;

  FileLocalStoreService({Future<Directory> Function()? baseDirectory})
    : _baseDirectory = baseDirectory ?? getApplicationDocumentsDirectory;

  Future<Directory> _dir() async {
    final dir = Directory(p.join((await _baseDirectory()).path, folderName));
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  Future<List<Map<String, dynamic>>> _readList(String name) async {
    final file = File(p.join((await _dir()).path, name));
    if (!await file.exists()) return const [];
    final raw = await file.readAsString();
    if (raw.trim().isEmpty) return const [];
    return (json.decode(raw) as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .toList();
  }

  Future<void> _writeList(
    String name,
    Iterable<Map<String, dynamic>> items,
  ) async {
    final file = File(p.join((await _dir()).path, name));
    await file.writeAsString(json.encode(items.toList()), flush: true);
  }

  /// 첫 호출 때 모든 컬렉션을 읽어 메모리 캐시에 채운다. 실패하면 다음 호출에서 다시 시도.
  Future<void> _ensureLoaded() {
    return _loading ??= () async {
      try {
        for (final m in await _readList(presentationsFile)) {
          final v = Presentation.fromMap(m);
          _presentations[v.id] = v;
        }
        for (final m in await _readList(versionsFile)) {
          final v = ScriptVersion.fromMap(m);
          _versions[v.id] = v;
        }
        for (final m in await _readList(analysesFile)) {
          final v = ScriptAnalysis.fromMap(m);
          _analyses[v.scriptVersionId] = v;
        }
        for (final m in await _readList(rehearsalsFile)) {
          final v = Rehearsal.fromMap(m);
          _rehearsals[v.id] = v;
        }
        for (final m in await _readList(reportsFile)) {
          final v = Report.fromMap(m);
          _reports[v.id] = v;
        }
      } on Object {
        _loading = null;
        rethrow;
      }
    }();
  }

  Future<Result<T>> _guard<T>(Future<Result<T>> Function() body) async {
    try {
      await _ensureLoaded();
      return await body();
    } on Exception catch (e) {
      return Failure(e);
    } on Error catch (e) {
      return Failure(Exception(e.toString()));
    }
  }

  Future<void> _flushPresentations() => _writeList(
    presentationsFile,
    _presentations.values.map((e) => e.toMap()),
  );
  Future<void> _flushVersions() =>
      _writeList(versionsFile, _versions.values.map((e) => e.toMap()));
  Future<void> _flushAnalyses() =>
      _writeList(analysesFile, _analyses.values.map((e) => e.toMap()));
  Future<void> _flushRehearsals() =>
      _writeList(rehearsalsFile, _rehearsals.values.map((e) => e.toMap()));
  Future<void> _flushReports() =>
      _writeList(reportsFile, _reports.values.map((e) => e.toMap()));

  @override
  Future<Result<List<Presentation>>> loadPresentations() =>
      _guard(super.loadPresentations);

  @override
  Future<Result<void>> savePresentation(Presentation presentation) =>
      _guard(() async {
        await super.savePresentation(presentation);
        await _flushPresentations();
        return const Success(null);
      });

  @override
  Future<Result<void>> deletePresentation(String presentationId) =>
      _guard(() async {
        await super.deletePresentation(presentationId);
        await _flushPresentations();
        await _flushVersions();
        await _flushAnalyses();
        await _flushRehearsals();
        await _flushReports();
        return const Success(null);
      });

  @override
  Future<Result<List<ScriptVersion>>> loadScriptVersions(
    String presentationId,
  ) => _guard(() => super.loadScriptVersions(presentationId));

  @override
  Future<Result<void>> saveScriptVersion(ScriptVersion version) =>
      _guard(() async {
        await super.saveScriptVersion(version);
        await _flushVersions();
        return const Success(null);
      });

  @override
  Future<Result<ScriptAnalysis?>> loadAnalysis(String scriptVersionId) =>
      _guard(() => super.loadAnalysis(scriptVersionId));

  @override
  Future<Result<void>> saveAnalysis(ScriptAnalysis analysis) =>
      _guard(() async {
        await super.saveAnalysis(analysis);
        await _flushAnalyses();
        return const Success(null);
      });

  @override
  Future<Result<List<Rehearsal>>> loadRehearsals(String presentationId) =>
      _guard(() => super.loadRehearsals(presentationId));

  @override
  Future<Result<void>> saveRehearsal(Rehearsal rehearsal) => _guard(() async {
    await super.saveRehearsal(rehearsal);
    await _flushRehearsals();
    return const Success(null);
  });

  @override
  Future<Result<void>> deleteRehearsal(String rehearsalId) => _guard(() async {
    await super.deleteRehearsal(rehearsalId);
    await _flushRehearsals();
    await _flushReports();
    return const Success(null);
  });

  @override
  Future<Result<Report?>> loadReport(String reportId) =>
      _guard(() => super.loadReport(reportId));

  @override
  Future<Result<void>> saveReport(Report report) => _guard(() async {
    await super.saveReport(report);
    await _flushReports();
    return const Success(null);
  });

  @override
  Future<Result<void>> deleteAll() => _guard(() async {
    await super.deleteAll();
    final dir = await _dir();
    for (final name in allFiles) {
      final file = File(p.join(dir.path, name));
      if (await file.exists()) await file.delete();
    }
    return const Success(null);
  });
}
