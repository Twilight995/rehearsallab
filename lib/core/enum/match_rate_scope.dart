/// 일치율 분모 범위 (통합 문서 5장 Report.matchRateScope).
/// - full: 원고 전체
/// - reached: 부분 리허설에서 도달한 원고 구간까지. 완주 회차와의 증감은 표시하지 않는다.
enum MatchRateScope { full, reached }

extension MatchRateScopeExtension on MatchRateScope {
  String get label => switch (this) {
    MatchRateScope.full => '원고 전체 기준',
    MatchRateScope.reached => '도달 구간 기준',
  };

  static MatchRateScope fromName(String name) => MatchRateScope.values
      .firstWhere((e) => e.name == name, orElse: () => MatchRateScope.full);
}
