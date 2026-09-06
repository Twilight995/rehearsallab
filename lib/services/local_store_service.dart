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
    _presentations.remove(presentationId);
    _versions.removeWhere((_, v) => v.presentationId == presentationId);
    _rehearsals.removeWhere((_, r) => r.presentationId == presentationId);
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
