import 'package:rehearsallab/core/models/result.dart';
import 'package:rehearsallab/models/report.dart';
import 'package:rehearsallab/services/mock/demo_data.dart';
import 'package:rehearsallab/services/script_estimate_service.dart';
import 'package:rehearsallab/services/transcription_service.dart';

/// 속도(WPM = 어절/분) · 필러 · 침묵 · 섹션 시간 계산 (X1-5).
/// 순수 동기 계산. AI와 무관하게 항상 결과가 있어야 한다 (부분 실패 원칙).
/// 권장 배분은 발표 규격(talkMinutes)을 원고 섹션 어절 비율로 나눈 값이다.
abstract class MetricsService {
  Result<ReportMetrics> compute({
    required Transcript transcript,
    required List<ScriptSection> sections,
    required int totalSec,
    required int talkMinutes,
  });
}

/// 데모 지표를 돌려주는 Mock.
class MockMetricsService implements MetricsService {
  const MockMetricsService();

  @override
  Result<ReportMetrics> compute({
    required Transcript transcript,
    required List<ScriptSection> sections,
    required int totalSec,
    required int talkMinutes,
  }) => Success(DemoData.metrics3);
}
