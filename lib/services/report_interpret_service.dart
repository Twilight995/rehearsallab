import 'package:rehearsallab/core/models/result.dart';
import 'package:rehearsallab/models/presentation.dart';
import 'package:rehearsallab/models/report.dart';
import 'package:rehearsallab/models/script_version.dart';
import 'package:rehearsallab/services/mock/demo_data.dart';

/// 6차원 AI 해석 (X1-4 Mock → X2-1 Http).
/// LLM에는 원고 · 전사문 · 발표 유형 · 청중 범주 · 파생 지표 · 대조 결과만 보낸다.
abstract class ReportInterpretService {
  Future<Result<AiFeedback>> interpret({
    required Presentation presentation,
    required ScriptVersion script,
    required Report partialReport,
  });
}

/// 데모 AI 피드백을 돌려주는 Mock. failWithTimeout으로 18 · 33번 화면 재현.
class MockReportInterpretService implements ReportInterpretService {
  final Duration delay;
  final bool failWithTimeout;

  const MockReportInterpretService({
    this.delay = const Duration(seconds: 2),
    this.failWithTimeout = false,
  });

  @override
  Future<Result<AiFeedback>> interpret({
    required Presentation presentation,
    required ScriptVersion script,
    required Report partialReport,
  }) async {
    await Future<void>.delayed(delay);
    if (failWithTimeout) {
      return Failure(Exception('제공사 응답 시간 초과 (timeout 20초)'));
    }
    return Success(DemoData.aiFeedback3);
  }
}
