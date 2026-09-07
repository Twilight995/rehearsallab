import 'dart:convert';

import 'package:rehearsallab/core/enum/retention_option.dart';
import 'package:rehearsallab/core/models/result.dart';
import 'package:rehearsallab/models/rehearsal.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 09 설정 값 저장 (C1-4): 보관 기간 · 외부 제공사 삭제 상태 · 발표별 마지막 탭.
/// 명령은 `Future<Result<T>>`. 상태 없음.
abstract class SettingsService {
  Future<Result<RetentionOption>> loadRetention();
  Future<Result<void>> saveRetention(RetentionOption option);

  /// 32 영구 삭제 후 외부 제공사(STT · LLM) 삭제 요청 결과. 요청 접수만으로 완료라고 표시하지 않는다.
  Future<Result<ExternalDeletion>> loadExternalDeletion();
  Future<Result<void>> saveExternalDeletion(ExternalDeletion status);

  /// 07 카드 탭 → 발표 상세 "마지막에 보던 탭" (통합 문서 4장). 없으면 null.
  Future<Result<String?>> loadLastTab(String presentationId);
  Future<Result<void>> saveLastTab(String presentationId, String tab);
}

/// 메모리 구현 (mock · 테스트)
class MockSettingsService extends SettingsService {
  RetentionOption _retention;
  ExternalDeletion _external;
  final Map<String, String> _lastTabs = {};

  MockSettingsService({
    RetentionOption retention = RetentionOption.days7,
    ExternalDeletion external = const ExternalDeletion(),
  }) : _retention = retention,
       _external = external;

  @override
  Future<Result<RetentionOption>> loadRetention() async => Success(_retention);

  @override
  Future<Result<void>> saveRetention(RetentionOption option) async {
    _retention = option;
    return const Success(null);
  }

  @override
  Future<Result<ExternalDeletion>> loadExternalDeletion() async =>
      Success(_external);

  @override
  Future<Result<void>> saveExternalDeletion(ExternalDeletion status) async {
    _external = status;
    return const Success(null);
  }

  @override
  Future<Result<String?>> loadLastTab(String presentationId) async =>
      Success(_lastTabs[presentationId]);

  @override
  Future<Result<void>> saveLastTab(String presentationId, String tab) async {
    _lastTabs[presentationId] = tab;
    return const Success(null);
  }
}

/// SharedPreferences 구현 (live). 키 `settings.*`.
class PrefsSettingsService extends SettingsService {
  static const String retentionKey = 'settings.retention';
  static const String externalKey = 'settings.external_deletion';
  static const String lastTabPrefix = 'settings.last_tab.';

  Future<Result<T>> _guard<T>(
    Future<T> Function(SharedPreferences prefs) body,
  ) async {
    try {
      return Success(await body(await SharedPreferences.getInstance()));
    } on Exception catch (e) {
      return Failure(e);
    } on Error catch (e) {
      return Failure(Exception(e.toString()));
    }
  }

  @override
  Future<Result<RetentionOption>> loadRetention() => _guard((prefs) async {
    final raw = prefs.getString(retentionKey);
    return raw == null
        ? RetentionOption.days7
        : RetentionOptionExtension.fromName(raw);
  });

  @override
  Future<Result<void>> saveRetention(RetentionOption option) =>
      _guard((prefs) => prefs.setString(retentionKey, option.name));

  @override
  Future<Result<ExternalDeletion>> loadExternalDeletion() => _guard((
    prefs,
  ) async {
    final raw = prefs.getString(externalKey);
    if (raw == null || raw.isEmpty) return const ExternalDeletion();
    return ExternalDeletion.fromMap(json.decode(raw) as Map<String, dynamic>);
  });

  @override
  Future<Result<void>> saveExternalDeletion(ExternalDeletion status) => _guard(
    (prefs) => prefs.setString(externalKey, json.encode(status.toMap())),
  );

  @override
  Future<Result<String?>> loadLastTab(String presentationId) =>
      _guard((prefs) async => prefs.getString('$lastTabPrefix$presentationId'));

  @override
  Future<Result<void>> saveLastTab(String presentationId, String tab) =>
      _guard((prefs) => prefs.setString('$lastTabPrefix$presentationId', tab));
}
