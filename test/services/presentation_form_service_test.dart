import 'package:flutter_test/flutter_test.dart';
import 'package:rehearsallab/core/enum/audience.dart';
import 'package:rehearsallab/core/enum/presentation_type.dart';
import 'package:rehearsallab/core/models/result.dart';
import 'package:rehearsallab/models/presentation.dart';
import 'package:rehearsallab/services/mock/demo_data.dart';
import 'package:rehearsallab/services/presentation_form_service.dart';

void main() {
  const service = PresentationFormService();
  PresentationDraft draft({
    String title = '○○학회 구두발표',
    num talk = 15,
    num qa = 5,
    DateTime? date,
  }) => PresentationDraft(
    title: title,
    type: PresentationType.conference,
    talkMinutes: talk,
    qaMinutes: qa,
    audience: Audience.adjacentField,
    date: date,
  );

  group('발표 시간 입력 검증 (계약서 8장 C1-3)', () {
    test('0 · 61 · 소수 거절', () {
      for (final bad in [0, 61, 15.5, -1]) {
        expect(
          service.validate(draft(talk: bad)),
          contains(PresentationFormError.talkRange),
          reason: '$bad',
        );
      }
    });

    test('1 · 20 · 21 · 60 허용', () {
      for (final ok in [1, 20, 21, 60]) {
        expect(service.validate(draft(talk: ok)), isEmpty, reason: '$ok');
      }
    });

    test('Q&A 0 허용 · 음수 · 소수 · 61 거절', () {
      expect(service.validate(draft(qa: 0)), isEmpty);
      for (final bad in [-1, 2.5, 61]) {
        expect(
          service.validate(draft(qa: bad)),
          contains(PresentationFormError.qaRange),
          reason: '$bad',
        );
      }
    });

    test('제목 공백 거절 · 여러 오류 동시 보고', () {
      final errors = service.validate(draft(title: '   ', talk: 0, qa: -1));
      expect(errors, [
        PresentationFormError.titleRequired,
        PresentationFormError.talkRange,
        PresentationFormError.qaRange,
      ]);
    });

    test('21~60 입력 시 부분 리허설 고지 대상, 20 이하는 아님', () {
      expect(draft(talk: 21).exceedsRecordingCap, isTrue);
      expect(draft(talk: 60).exceedsRecordingCap, isTrue);
      expect(draft(talk: 20).exceedsRecordingCap, isFalse);
    });
  });

  group('build', () {
    final now = DateTime(2026, 9, 7, 10, 30);

    test('검증 통과 → Presentation (제목 trim · 날짜는 자정 · Q&A 0 저장)', () {
      final result = service.build(
        draft(title: '  제목  ', qa: 0, date: DateTime(2026, 9, 12, 15, 40)),
        now: now,
      );
      final p = (result as Success<Presentation>).value;
      expect(p.title, '제목');
      expect(p.qaMinutes, 0);
      expect(p.timeSpecLabel, '15분');
      expect(p.date, DateTime(2026, 9, 12));
      expect(p.createdAt, now);
      expect(p.id, startsWith('p-'));
    });

    test('검증 실패 → Failure(PresentationFormException)', () {
      final result = service.build(draft(talk: 0), now: now);
      expect(result, isA<Failure<Presentation>>());
      final e = (result as Failure<Presentation>).exception;
      expect((e as PresentationFormException).errors, [
        PresentationFormError.talkRange,
      ]);
    });

    test('편집: id · createdAt 유지', () {
      final existing = DemoData.presentation;
      final result = service.build(
        PresentationDraft.fromPresentation(existing).copyWith(title: '수정'),
        existing: existing,
        now: now,
      );
      final p = (result as Success<Presentation>).value;
      expect(p.id, existing.id);
      expect(p.createdAt, existing.createdAt);
      expect(p.title, '수정');
    });
  });

  group('홈 정렬 · 다음 발표 (통합 문서 5장)', () {
    Presentation p(String id, {DateTime? date, required DateTime created}) =>
        Presentation(
          id: id,
          title: id,
          type: PresentationType.conference,
          talkMinutes: 10,
          qaMinutes: 0,
          audience: Audience.general,
          date: date,
          createdAt: created,
        );

    test('날짜 있는 발표 날짜순 → 날짜 없는 발표 생성일 내림차순', () {
      final items = [
        p('undated-old', created: DateTime(2026, 9, 1)),
        p('late', date: DateTime(2026, 9, 27), created: DateTime(2026, 9, 3)),
        p('undated-new', created: DateTime(2026, 9, 5)),
        p('soon', date: DateTime(2026, 9, 12), created: DateTime(2026, 9, 2)),
      ];
      expect(PresentationFormService.sortForHome(items).map((e) => e.id), [
        'soon',
        'late',
        'undated-new',
        'undated-old',
      ]);
    });

    test('데모 데이터 정렬: 학회(9/12) → 디펜스(9/27) → 랩 세미나(날짜 미정)', () {
      expect(
        PresentationFormService.sortForHome(
          DemoData.presentations,
        ).map((e) => e.id),
        ['demo-presentation', 'demo-presentation-2', 'demo-presentation-3'],
      );
    });

    test('다음 발표: 오늘 이후 가장 가까운 날짜, 없으면 정렬 첫 항목, 비어 있으면 null', () {
      final today = DateTime(2026, 9, 9);
      final past = p('past', date: DateTime(2026, 9, 1), created: today);
      final todayP = p('today', date: DateTime(2026, 9, 9), created: today);
      final future = p('future', date: DateTime(2026, 9, 20), created: today);
      final undated = p('undated', created: today);
      expect(
        PresentationFormService.nextPresentation([
          undated,
          future,
          past,
          todayP,
        ], today)?.id,
        'today',
      );
      expect(
        PresentationFormService.nextPresentation([undated, past], today)?.id,
        'past',
        reason: '지난 발표만 있으면 정렬 첫 항목(날짜 있음 우선)',
      );
      expect(PresentationFormService.nextPresentation([], today), isNull);
    });
  });
}
