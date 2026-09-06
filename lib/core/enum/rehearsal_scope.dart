/// 리허설 범위 (통합 문서 4·9장 부분 리허설 합의).
/// - full: 원고를 끝까지 읽음
/// - partial: 20:00 녹음 상한 도달로 자동 종료 (원고 후반 미도달)
enum RehearsalScope { full, partial }

extension RehearsalScopeExtension on RehearsalScope {
  String get badgeLabel => switch (this) {
    RehearsalScope.full => '전체 리허설',
    RehearsalScope.partial => '부분 리허설',
  };

  static RehearsalScope fromName(String name) => RehearsalScope.values
      .firstWhere((e) => e.name == name, orElse: () => RehearsalScope.full);
}
