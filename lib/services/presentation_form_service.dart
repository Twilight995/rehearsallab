import 'package:rehearsallab/app/app_config.dart';
import 'package:rehearsallab/core/enum/audience.dart';
import 'package:rehearsallab/core/enum/presentation_type.dart';
import 'package:rehearsallab/core/models/result.dart';
import 'package:rehearsallab/models/presentation.dart';

/// 08 발표 생성 · 편집 입력값. 숫자는 검증 전이므로 num (정수 · 범위 검증은 서비스가 한다).
class PresentationDraft {
  final String title;
  final PresentationType type;
  final num talkMinutes;
  final num qaMinutes;
  final Audience audience;
  final DateTime? date;

  const PresentationDraft({
    required this.title,
    required this.type,
    required this.talkMinutes,
    required this.qaMinutes,
    required this.audience,
    this.date,
  });

  factory PresentationDraft.initial() => const PresentationDraft(
    title: '',
    type: PresentationType.conference,
    talkMinutes: 15,
    qaMinutes: 5,
    audience: Audience.adjacentField,
  );

  factory PresentationDraft.fromPresentation(Presentation p) =>
      PresentationDraft(
        title: p.title,
        type: p.type,
        talkMinutes: p.talkMinutes,
        qaMinutes: p.qaMinutes,
        audience: p.audience,
        date: p.date,
      );

  PresentationDraft copyWith({
    String? title,
    PresentationType? type,
    num? talkMinutes,
    num? qaMinutes,
    Audience? audience,
    DateTime? date,
    bool clearDate = false,
  }) => PresentationDraft(
    title: title ?? this.title,
    type: type ?? this.type,
    talkMinutes: talkMinutes ?? this.talkMinutes,
    qaMinutes: qaMinutes ?? this.qaMinutes,
    audience: audience ?? this.audience,
    date: clearDate ? null : (date ?? this.date),
  );

  /// 20분 초과 → 프로토타입은 20분까지만 녹음 (부분 리허설 고지)
  bool get exceedsRecordingCap => talkMinutes > AppConfig.recordingCapMinutes;
}

/// 검증 실패 항목. 문구는 AppStrings.formError(code).
enum PresentationFormError { titleRequired, talkRange, qaRange }

class PresentationFormException implements Exception {
  final List<PresentationFormError> errors;
  const PresentationFormException(this.errors);

  @override
  String toString() =>
      'PresentationFormException(${errors.map((e) => e.name).join(', ')})';
}

/// 08 입력 검증 (순수 동기 계산 → Result). 통합 문서 4장 "제목·발표 시간 필수 검증 후 10",
/// 5장 "qaMinutes 0 이상 정수, talkMinutes 1~60". 계약서 8장: 0·61·소수 거절, 1·20·21·60 허용, Q&A 0 허용.
class PresentationFormService {
  const PresentationFormService();

  static bool _isInt(num value) => value == value.roundToDouble();

  List<PresentationFormError> validate(PresentationDraft draft) {
    final errors = <PresentationFormError>[];
    if (draft.title.trim().isEmpty) {
      errors.add(PresentationFormError.titleRequired);
    }
    if (!_isInt(draft.talkMinutes) ||
        draft.talkMinutes < AppConfig.talkMinutesMin ||
        draft.talkMinutes > AppConfig.talkMinutesMax) {
      errors.add(PresentationFormError.talkRange);
    }
    if (!_isInt(draft.qaMinutes) ||
        draft.qaMinutes < AppConfig.qaMinutesMin ||
        draft.qaMinutes > AppConfig.qaMinutesMax) {
      errors.add(PresentationFormError.qaRange);
    }
    return errors;
  }

  /// 검증을 통과하면 저장할 Presentation을 만든다. `existing`이 있으면 id · createdAt 유지(편집).
  Result<Presentation> build(
    PresentationDraft draft, {
    Presentation? existing,
    required DateTime now,
  }) {
    final errors = validate(draft);
    if (errors.isNotEmpty) return Failure(PresentationFormException(errors));
    return Success(
      Presentation(
        id: existing?.id ?? 'p-${now.microsecondsSinceEpoch}',
        title: draft.title.trim(),
        type: draft.type,
        talkMinutes: draft.talkMinutes.toInt(),
        qaMinutes: draft.qaMinutes.toInt(),
        audience: draft.audience,
        date: draft.date?.copyWith(
          hour: 0,
          minute: 0,
          second: 0,
          millisecond: 0,
          microsecond: 0,
        ),
        createdAt: existing?.createdAt ?? now,
      ),
    );
  }

  /// 홈 정렬 (통합 문서 5장): 날짜 있는 발표를 날짜 오름차순으로 먼저, 날짜 없는 발표는 그 뒤에 생성일 내림차순.
  static List<Presentation> sortForHome(Iterable<Presentation> items) {
    final dated = items.where((p) => p.date != null).toList()
      ..sort((a, b) {
        final byDate = a.date!.compareTo(b.date!);
        return byDate != 0 ? byDate : b.createdAt.compareTo(a.createdAt);
      });
    final undated = items.where((p) => p.date == null).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return [...dated, ...undated];
  }

  /// 07 헤더 "다음 발표까지": 오늘 이후(오늘 포함) 가장 가까운 날짜 있는 발표. 없으면 정렬 첫 항목.
  static Presentation? nextPresentation(
    Iterable<Presentation> items,
    DateTime today,
  ) {
    final sorted = sortForHome(items);
    final todayOnly = DateTime(today.year, today.month, today.day);
    for (final p in sorted) {
      if (p.date != null && !p.date!.isBefore(todayOnly)) return p;
    }
    return sorted.isEmpty ? null : sorted.first;
  }
}
