import 'package:rehearsallab/core/enum/script_version_origin.dart';
import 'package:rehearsallab/core/models/result.dart';
import 'package:rehearsallab/models/script_analysis.dart';
import 'package:rehearsallab/models/script_version.dart';

/// 리라이트 치환 · 되돌리기. 통합 문서 2장. 순수 동기 계산.
/// - 확정 1회 = 버전 +1 (배치 적용 없음)
/// - 원문이 현재 원고에 정확히 일치할 때만 치환. 없으면 Failure(재분석 안내)
/// - 되돌리기 = 선택한 과거 버전의 텍스트를 현재 version+1로 저장
class RewriteService {
  final String Function() _idGenerator;
  final DateTime Function() _now;

  RewriteService({String Function()? idGenerator, DateTime Function()? now})
    : _idGenerator =
          idGenerator ?? (() => 'sv-${DateTime.now().microsecondsSinceEpoch}'),
      _now = now ?? DateTime.now;

  Result<ScriptVersion> apply({
    required ScriptVersion current,
    required Rewrite rewrite,
  }) {
    final index = current.text.indexOf(rewrite.original);
    if (index < 0) {
      return Failure(Exception('원문을 찾을 수 없어요. 원고를 다시 분석하세요.'));
    }
    final newText = current.text.replaceRange(
      index,
      index + rewrite.original.length,
      rewrite.replacement,
    );
    return Success(
      ScriptVersion(
        id: _idGenerator(),
        presentationId: current.presentationId,
        version: current.version + 1,
        text: newText,
        parentVersionId: current.id,
        createdBy: ScriptVersionOrigin.rewrite,
        createdAt: _now(),
      ),
    );
  }

  Result<ScriptVersion> revert({
    required ScriptVersion current,
    required ScriptVersion target,
  }) {
    if (target.presentationId != current.presentationId) {
      return Failure(Exception('다른 발표의 원고로는 되돌릴 수 없습니다.'));
    }
    return Success(
      ScriptVersion(
        id: _idGenerator(),
        presentationId: current.presentationId,
        version: current.version + 1,
        text: target.text,
        parentVersionId: current.id,
        createdBy: ScriptVersionOrigin.revert,
        createdAt: _now(),
      ),
    );
  }
}
