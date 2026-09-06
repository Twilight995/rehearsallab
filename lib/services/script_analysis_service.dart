import 'package:rehearsallab/core/models/result.dart';
import 'package:rehearsallab/models/presentation.dart';
import 'package:rehearsallab/models/script_analysis.dart';
import 'package:rehearsallab/models/script_version.dart';
import 'package:rehearsallab/services/mock/demo_data.dart';

/// 원고 분석. 11b → 12 또는 38.
/// live 모드에서는 HttpScriptAnalysisService가 원고 · 발표 유형 · 청중 범주만 LLM에 보낸다.
abstract class ScriptAnalysisService {
  Future<Result<ScriptAnalysis>> analyze({
    required ScriptVersion version,
    required Presentation presentation,
  });
}

/// 데모 데이터를 돌려주는 Mock. delay로 11b 화면을 확인할 수 있다.
class MockScriptAnalysisService implements ScriptAnalysisService {
  final Duration delay;

  /// true면 38번 화면 재현 (응답 시간 초과)
  final bool failWithTimeout;

  const MockScriptAnalysisService({
    this.delay = const Duration(seconds: 2),
    this.failWithTimeout = false,
  });

  @override
  Future<Result<ScriptAnalysis>> analyze({
    required ScriptVersion version,
    required Presentation presentation,
  }) async {
    await Future<void>.delayed(delay);
    if (failWithTimeout) {
      return Failure(
        Exception('제공사 응답 시간 초과 (timeout, 20초). 네트워크를 확인하고 다시 시도하세요.'),
      );
    }
    return Success(
      DemoData.analysisV1.copyWith(
        id: 'analysis-${version.id}',
        scriptVersionId: version.id,
        createdAt: DateTime.now(),
      ),
    );
  }
}
