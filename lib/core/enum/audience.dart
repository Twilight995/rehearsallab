/// 청중 (기획서 §4). 용어·배경 설명 수준 판정 기준. LLM에는 이 범주값만 전송한다.
enum Audience { sameField, adjacentField, general }

extension AudienceExtension on Audience {
  String get title => switch (this) {
    Audience.sameField => '같은 분과 전문가',
    Audience.adjacentField => '인접 분야 연구자',
    Audience.general => '비전공 일반',
  };

  static Audience fromName(String name) => Audience.values.firstWhere(
    (e) => e.name == name,
    orElse: () => Audience.adjacentField,
  );
}
