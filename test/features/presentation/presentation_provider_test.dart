import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rehearsallab/core/enum/badge_tone.dart';
import 'package:rehearsallab/core/models/result.dart';
import 'package:rehearsallab/features/presentation/presentation_provider.dart';
import 'package:rehearsallab/models/presentation.dart';
import 'package:rehearsallab/services/local_store_service.dart';
import 'package:rehearsallab/services/mock/demo_data.dart';
import 'package:rehearsallab/services/presentation_form_service.dart';

void main() {
  ProviderContainer container({LocalStoreService? store}) {
    final c = ProviderContainer(
      overrides: [
        if (store != null) localStoreProvider.overrideWithValue(store),
      ],
    );
    addTearDown(c.dispose);
    return c;
  }

  group('mock 모드 기본값 (데모 데이터 §8)', () {
    test('발표 3개 · D-day 기준일 2026-09-09 · 홈 정렬', () async {
      final c = container();
      final list = await c.read(presentationsProvider.future);
      expect(list.map((p) => p.id), [
        'demo-presentation',
        'demo-presentation-2',
        'demo-presentation-3',
      ]);
      expect(c.read(todayProvider), DemoData.today);
      expect(c.read(nextPresentationProvider)?.id, 'demo-presentation');
    });

    test('홈 카드: 리허설 2회(일치율 추이 3점) · 분석 완료 · 원고 없음', () async {
      final c = container();
      final cards = await c.read(homeCardsProvider.future);
      expect(cards, hasLength(3));
      expect(cards[0].stageLabel, '리허설 3회');
      expect(cards[0].stageTone, BadgeTone.info);
      expect(cards[0].rehearsalCount, 3);
      expect(cards[0].matchTrend, [0.74, 0.81, 0.87]);
      expect(cards[1].stageLabel, '원고 없음');
      expect(cards[2].stageLabel, '원고 없음');
      expect(cards[1].matchTrend, isEmpty);
    });
  });

  group('단계 배지 파생', () {
    test('원고만 있으면 "원고 저장됨", 분석이 있으면 "분석 완료"', () async {
      final other = DemoData.presentations[1];
      final version = DemoData.scriptV1.copyWith(
        id: 'o-v1',
        presentationId: other.id,
      );
      final c = container(
        store: MemoryLocalStoreService(
          presentations: [other, DemoData.presentations[2]],
          versions: [
            version,
            DemoData.scriptV1.copyWith(
              id: 'p3-v1',
              presentationId: DemoData.presentations[2].id,
            ),
          ],
          analyses: [
            DemoData.analysisV1.copyWith(id: 'o-a', scriptVersionId: 'o-v1'),
          ],
        ),
      );
      final cards = await c.read(homeCardsProvider.future);
      final byId = {for (final card in cards) card.presentation.id: card};
      expect(byId[other.id]!.stageLabel, '분석 완료');
      expect(byId[other.id]!.stageTone, BadgeTone.info);
      expect(byId[DemoData.presentations[2].id]!.stageLabel, '원고 저장됨');
      expect(byId[DemoData.presentations[2].id]!.stageTone, BadgeTone.neutral);
    });
  });

  group('PresentationsNotifier.save · delete', () {
    test('빈 저장소에 생성 → 목록 · 카드 갱신 · 다음 발표', () async {
      final store = MemoryLocalStoreService();
      final c = container(store: store);
      expect(await c.read(presentationsProvider.future), isEmpty);
      final result = await c
          .read(presentationsProvider.notifier)
          .save(
            PresentationDraft.initial().copyWith(
              title: '새 발표',
              date: DateTime(2026, 10, 1),
            ),
          );
      expect(result, isA<Success<Presentation>>());
      final list = await c.read(presentationsProvider.future);
      expect(list.single.title, '새 발표');
      expect(
        (await c.read(homeCardsProvider.future)).single.stageLabel,
        '원고 없음',
      );
      expect(c.read(nextPresentationProvider)?.title, '새 발표');
      expect(
        ((await store.loadPresentations()) as Success<List<Presentation>>)
            .value
            .single
            .title,
        '새 발표',
        reason: '저장소에 반영',
      );
    });

    test('검증 실패 → Failure(PresentationFormException), 저장소 변화 없음', () async {
      final store = MemoryLocalStoreService();
      final c = container(store: store);
      await c.read(presentationsProvider.future);
      final result = await c
          .read(presentationsProvider.notifier)
          .save(
            PresentationDraft.initial().copyWith(title: '', talkMinutes: 0),
          );
      expect(result, isA<Failure<Presentation>>());
      expect(
        ((result as Failure<Presentation>).exception
                as PresentationFormException)
            .errors,
        [PresentationFormError.titleRequired, PresentationFormError.talkRange],
      );
      expect(
        ((await store.loadPresentations()) as Success<List<Presentation>>)
            .value,
        isEmpty,
      );
    });

    test('편집 저장은 id 유지 · 삭제 후 목록에서 제거', () async {
      final c = container();
      await c.read(presentationsProvider.future);
      final notifier = c.read(presentationsProvider.notifier);
      final existing = c.read(
        presentationByIdProvider(DemoData.presentationId),
      )!;
      final saved = await notifier.save(
        PresentationDraft.fromPresentation(existing).copyWith(title: '수정됨'),
        existing: existing,
      );
      expect((saved as Success<Presentation>).value.id, existing.id);
      expect(
        (await c.read(
          presentationsProvider.future,
        )).firstWhere((p) => p.id == existing.id).title,
        '수정됨',
      );
      await notifier.delete(existing.id);
      expect(
        (await c.read(presentationsProvider.future)).map((p) => p.id),
        isNot(contains(existing.id)),
      );
      expect(c.read(presentationByIdProvider(existing.id)), isNull);
    });
  });
}
