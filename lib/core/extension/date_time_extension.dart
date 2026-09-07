/// 날짜 표기 (intl 로케일 초기화 없이 한국어 고정). 홈 07 · 발표 생성 08 · 상세 헤더.
extension DateTimeExtension on DateTime {
  static const List<String> _weekdays = ['월', '화', '수', '목', '금', '토', '일'];

  /// 시각을 뗀 날짜만
  DateTime get dateOnly => DateTime(year, month, day);

  /// "9월 12일 (금)"
  String get koreanMonthDay => '$month월 $day일 (${_weekdays[weekday - 1]})';

  /// "2026년 9월 12일 (금)"
  String get koreanFullDate => '$year년 $koreanMonthDay';

  /// 오늘 기준 남은 일수 (날짜 단위). 지났으면 음수.
  int daysFrom(DateTime today) => dateOnly.difference(today.dateOnly).inDays;
}
