/// 원고 버전이 만들어진 경로 (통합 문서 5장 ScriptVersion.createdBy).
enum ScriptVersionOrigin { user, rewrite, revert }

extension ScriptVersionOriginExtension on ScriptVersionOrigin {
  String get title => switch (this) {
    ScriptVersionOrigin.user => '직접 편집',
    ScriptVersionOrigin.rewrite => '리라이트 반영',
    ScriptVersionOrigin.revert => '되돌리기',
  };

  static ScriptVersionOrigin fromName(String name) =>
      ScriptVersionOrigin.values.firstWhere(
        (e) => e.name == name,
        orElse: () => ScriptVersionOrigin.user,
      );
}
