import 'package:rehearsallab/core/enum/match_rate_scope.dart';
import 'package:rehearsallab/core/models/result.dart';
import 'package:rehearsallab/models/report.dart';
import 'package:rehearsallab/services/mock/demo_data.dart';
import 'package:rehearsallab/services/transcription_service.dart';

/// 정렬 결과. 전체 전사문을 담지 않는다 (즉흥 추가 문장만 spokenText).
class AlignmentResult {
  final List<AlignedSentence> sentences;

  /// 0.0 ~ 1.0
  final double matchRate;
  final MatchRateScope scope;

  const AlignmentResult({
    required this.sentences,
    required this.matchRate,
    required this.scope,
  });
}

/// 원고 문장 ↔ 전사문 정렬 (X1-5). 순수 동기 계산.
/// - 상태: read · missed · added · reordered · notReached
/// - capReached(부분 리허설)면 도달하지 못한 후반 문장은 missed가 아니라 notReached,
///   일치율 분모는 도달 구간까지(scope = reached).
abstract class AlignmentService {
  Result<AlignmentResult> align({
    required List<String> scriptSentences,
    required Transcript transcript,
    required bool capReached,
  });
}

/// 데모 정렬 결과를 돌려주는 Mock.
class MockAlignmentService implements AlignmentService {
  const MockAlignmentService();

  @override
  Result<AlignmentResult> align({
    required List<String> scriptSentences,
    required Transcript transcript,
    required bool capReached,
  }) => Success(
    AlignmentResult(
      sentences: DemoData.alignment3,
      matchRate: 0.87,
      scope: capReached ? MatchRateScope.reached : MatchRateScope.full,
    ),
  );
}
