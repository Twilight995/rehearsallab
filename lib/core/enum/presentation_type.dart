/// 발표 유형 (기획서 §4). 루브릭 톤과 예상 질문 성격을 결정한다.
enum PresentationType { conference, defense, labSeminar, classOther }

extension PresentationTypeExtension on PresentationType {
  String get title => switch (this) {
    PresentationType.conference => '학회 구두발표',
    PresentationType.defense => '논문 심사(디펜스)',
    PresentationType.labSeminar => '랩 세미나',
    PresentationType.classOther => '수업·기타',
  };

  static PresentationType fromName(String name) =>
      PresentationType.values.firstWhere(
        (e) => e.name == name,
        orElse: () => PresentationType.conference,
      );
}
