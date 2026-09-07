import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rehearsallab/app/app_config.dart';
import 'package:rehearsallab/app/app_strings.dart';
import 'package:rehearsallab/core/enum/app_mode.dart';
import 'package:rehearsallab/core/enum/badge_tone.dart';
import 'package:rehearsallab/core/enum/script_state.dart';
import 'package:rehearsallab/core/models/result.dart';
import 'package:rehearsallab/models/presentation.dart';
import 'package:rehearsallab/models/rehearsal.dart';
import 'package:rehearsallab/services/local_store_service.dart';
import 'package:rehearsallab/services/mock/demo_data.dart';
import 'package:rehearsallab/services/presentation_form_service.dart';

/// mock 모드는 데모 데이터(통합 문서 8장)를 넣은 메모리 저장소, live 모드는 파일 저장소 (C1-3).
final localStoreProvider = Provider<LocalStoreService>((ref) {
  return ref.watch(appModeProvider) == AppMode.mock
      ? MemoryLocalStoreService(
          presentations: DemoData.presentations,
          versions: [
            DemoData.scriptV1,
            DemoData.scriptV2,
            DemoData.scriptV3,
            DemoData.presentation2ScriptV1,
          ],
          analyses: [DemoData.analysisV1, DemoData.presentation2Analysis],
          rehearsals: [
            DemoData.rehearsal1,
            DemoData.rehearsal2,
            DemoData.rehearsal3,
          ],
          reports: [DemoData.report1, DemoData.report2, DemoData.report3],
        )
      : FileLocalStoreService();
});

/// D-day 기준 날짜. mock 모드는 데모 데이터와 맞춘 고정 날짜(D-3), live는 지금.
final todayProvider = Provider<DateTime>((ref) {
  return ref.watch(appModeProvider) == AppMode.mock
      ? DemoData.today
      : DateTime.now();
});

final presentationFormServiceProvider = Provider<PresentationFormService>(
  (ref) => const PresentationFormService(),
);

final presentationsProvider =
    AsyncNotifierProvider<PresentationsNotifier, List<Presentation>>(
      PresentationsNotifier.new,
      retry: (retryCount, error) => null,
    );

/// 발표 목록 (홈 정렬 적용). 변이 후 invalidateSelf()로 저장소를 다시 읽는다 (계약서 2장).
class PresentationsNotifier extends AsyncNotifier<List<Presentation>> {
  LocalStoreService get _store => ref.read(localStoreProvider);

  @override
  FutureOr<List<Presentation>> build() async {
    final result = await _store.loadPresentations();
    return switch (result) {
      Success(:final value) => PresentationFormService.sortForHome(value),
      Failure(:final exception) => throw exception,
    };
  }

  /// 08 "발표 만들기" · 편집 저장. 검증 실패는 Failure(PresentationFormException).
  Future<Result<Presentation>> save(
    PresentationDraft draft, {
    Presentation? existing,
  }) async {
    final built = ref
        .read(presentationFormServiceProvider)
        .build(draft, existing: existing, now: DateTime.now());
    if (built case Failure(:final exception)) return Failure(exception);
    final presentation = (built as Success<Presentation>).value;
    final saved = await _store.savePresentation(presentation);
    if (saved case Failure(:final exception)) return Failure(exception);
    ref.invalidateSelf();
    ref.invalidate(homeCardsProvider);
    return Success(presentation);
  }

  Future<Result<void>> delete(String presentationId) async {
    final result = await _store.deletePresentation(presentationId);
    if (result is Success) {
      ref.invalidateSelf();
      ref.invalidate(homeCardsProvider);
    }
    return result;
  }
}

/// 07 카드 한 장에 필요한 파생값. 단계 배지는 리허설 > 분석 > 원고 순으로 가장 진행된 상태.
class HomeCard {
  final Presentation presentation;
  final int rehearsalCount;
  final String stageLabel;
  final BadgeTone stageTone;

  /// 회차별 원고 일치율(0~1), 회차 오름차순. 종합 점수는 쓰지 않는다.
  final List<double> matchTrend;

  const HomeCard({
    required this.presentation,
    required this.rehearsalCount,
    required this.stageLabel,
    required this.stageTone,
    required this.matchTrend,
  });
}

/// 홈 카드 목록 (발표 + 원고 · 분석 · 리허설 · 리포트 조합). 발표 정렬을 그대로 따른다.
final homeCardsProvider = FutureProvider<List<HomeCard>>((ref) async {
  final presentations = await ref.watch(presentationsProvider.future);
  final store = ref.read(localStoreProvider);
  final cards = <HomeCard>[];
  for (final p in presentations) {
    cards.add(await _buildHomeCard(store, p));
  }
  return cards;
}, retry: (retryCount, error) => null);

Future<HomeCard> _buildHomeCard(LocalStoreService store, Presentation p) async {
  final rehearsals = switch (await store.loadRehearsals(p.id)) {
    Success(:final value) => value,
    Failure(:final exception) => throw exception,
  };
  if (rehearsals.isNotEmpty) {
    final byRound = [...rehearsals]..sort((a, b) => a.round.compareTo(b.round));
    final trend = <double>[];
    for (final r in byRound) {
      final reportId = r.reportId;
      if (reportId == null) continue;
      if (await store.loadReport(reportId) case Success(
        :final value,
      ) when value != null) {
        trend.add(value.matchRate);
      }
    }
    return HomeCard(
      presentation: p,
      rehearsalCount: rehearsals.length,
      stageLabel: AppStrings.homeRehearsalCount(rehearsals.length),
      stageTone: BadgeTone.info,
      matchTrend: trend,
    );
  }
  final versions = switch (await store.loadScriptVersions(p.id)) {
    Success(:final value) => value,
    Failure(:final exception) => throw exception,
  };
  var state = ScriptState.empty;
  if (versions.isNotEmpty) {
    final latest = versions.last;
    final analysis = switch (await store.loadAnalysis(latest.id)) {
      Success(:final value) => value,
      Failure(:final exception) => throw exception,
    };
    state = analysis != null ? ScriptState.analyzed : ScriptState.saved;
  }
  return HomeCard(
    presentation: p,
    rehearsalCount: 0,
    stageLabel: state.badgeLabel,
    stageTone: state.tone,
    matchTrend: const [],
  );
}

/// 07 헤더 "다음 발표까지"에 쓰는 발표 (없으면 null → 06 빈 홈)
final nextPresentationProvider = Provider<Presentation?>((ref) {
  final list = ref.watch(presentationsProvider).value ?? const [];
  return PresentationFormService.nextPresentation(
    list,
    ref.watch(todayProvider),
  );
});

/// 특정 발표 (상세 · 편집용)
final presentationByIdProvider = Provider.family<Presentation?, String>((
  ref,
  id,
) {
  for (final p in ref.watch(presentationsProvider).value ?? const []) {
    if (p.id == id) return p;
  }
  return null;
});

/// 리허설 회차 수 (헤더 문구용)
int rehearsalCountOf(List<HomeCard> cards, Presentation p) {
  for (final c in cards) {
    if (c.presentation.id == p.id) return c.rehearsalCount;
  }
  return 0;
}

/// 데모 리포트 등 Rehearsal 조회 도우미 (리포트 화면에서 재사용 예정)
List<Rehearsal> sortByRound(Iterable<Rehearsal> items) =>
    [...items]..sort((a, b) => a.round.compareTo(b.round));
